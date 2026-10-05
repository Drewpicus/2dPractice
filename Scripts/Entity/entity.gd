##An Entity, something that can exist in the GameWorld, normally with a Sprite.
##Entites can have [EntityComponent]s, which define the properties of the Entity.
##This is the most common type of game object besides maybe Items.

extends CharacterBody2D
class_name Entity

@onready var collision: CollisionShape2D = $CollisionShape2D

##The ID of the specific instance of this Entity for tracking purposes, handled
##by [RuntimeObjectRegistry]
var instance_id: String
##The ID of the Entity's Definition, e.g. [param &"base:rock"]. This is the
##ID the [EntityFactory] used to construct this Entity.
var entity_id: StringName
##The name of the Entity for gameplay purposes, e.g. "Goblin"
var entity_name: String
##Reference to the parent folder of this Entity's [EntityComponent]s.
##Assigned by [method _get_components_folder].
var components_folder: Node
##If [code]true[/code], this Entity will interact with physics.
var solid: bool = true
##Dictionary of all [EntityComponent]s attached to this Entity.
##[code]_components.[&"base:health"][/code] will refer to an attached [HealthComponent].
var _components: Dictionary[StringName, EntityComponent] = {}

signal component_added(component_id: StringName, component: EntityComponent)
signal component_removing(component_id: StringName, component: EntityComponent)

func _init() -> void:
	instance_id = RuntimeObjectRegistry.generate_unique_id()
	RuntimeObjectRegistry.register(self, instance_id)

#TODO: Remove health/die stuff from here
func _ready() -> void:
	var health_component := get_component(&"base:health") as HealthComponent

	if health_component:
		health_component.health_depleted.connect(die)

	if not solid:
		collision.disabled = true

##This function is used locally when adding a new component or attaching an already-built component.
##Adds [param component] to [member Entity._components] and emits the added signals at both the Entity and component levels.
##Once a component is registered, the rest of the Entity can start talking to it. Returns [code]true[/code] if the registry was successful.
func _register_component(component: EntityComponent) -> bool:
	if not component:
		return false
	
	var component_id := component.component_id
	
	if not GameID.is_valid(component_id):
		push_error("Invalid EntityComponent ID: %s" % component_id)
		return false
	
	if _components.has(component_id):
		if _components[component_id] == component:
			return true
			
		push_error("Entity already has an EntityComponent with ID: %s" % component_id)
		return false
	
	_components[component_id] = component
	#It's important that _set_owner(self) is called first, since that connects the
	#component_added signal. So the order is:
	#1. Root entity set to Entity and signals are connected
	#2. The particular component's on_added is run (which might call watch_sibling, etc.)
	#3. The entity announces its component has been added, which runs that component's
	#		_handle_component_added function, notifying its siblings and anyone watching it.
	component._set_owner(self)
	component.on_added()
	component_added.emit(component_id, component)
	return true

## Deprecated, temporary function that spawns remains upon death and deletes the entity from the world
func die() -> void:
	var remains_component := get_component(&"base:remains") as RemainsComponent

	if remains_component:
		remains_component.spawn_remains()

	var world := GameWorld.find_world(self)

	if world:
		world.remove_entity(self)
	else:
		queue_free()

##Add a component to the component folder, based on ID, e.g. &"health".
##Parameters are a dict with the keys being variable names and the values being values
func add_component(component_id: StringName, parameters: Dictionary={}) -> EntityComponent:
	if not GameID.is_valid(component_id):
		push_error("Invalid component ID: %s" % component_id)
		return null
	
	var folder := _get_components_folder()
	if not folder:
		return null
	
	if has_component(component_id):
		return null
	
	var component_scene: PackedScene = EntityComponentRegistry.get_component_scene(component_id)
	if not component_scene:
		push_error("Unregistered EntityComponent ID: %s" % component_id)
		return null
	
	var new_component := component_scene.instantiate() as EntityComponent
	
	if not new_component:
		push_error("Component scene %s does not instantiate an EntityComponent." % component_id)
		return null
	
	if new_component.component_id != component_id:
		push_error(
			"Component ID mismatch. Requested %s, scene identifies as %s." % [component_id, new_component.component_id])
		new_component.free()
		return null
	
	for key in parameters:
		if key in new_component:
			var value = ParameterCoercion.coerce_for_property(new_component, key, parameters[key])
			new_component.set(key, value)
	
	if not _register_component(new_component):
		new_component.free()
		return null

	folder.add_child(new_component)
	return new_component

##Remove a component from the component folder, based on ID, e.g. &"base:health".
##The component is also deleted. To detatch without deleting, use [method detatch_component].
func remove_component(component_id: StringName) -> void:
	var component := get_component(component_id)

	if not component:
		return
		
	component.on_removing()
	component_removing.emit(component_id, component)
	_components.erase(component_id)
	component._clear_owner()
	component.queue_free()

##Attach an already-built component to the entity
func attach_component(component: EntityComponent) -> bool:
	if not component:
		return false

	if has_component(component.component_id):
		return false

	var folder := _get_components_folder()

	if not folder:
		return false

	if not _register_component(component):
		return false

	folder.add_child(component)

	return true

##Pluck a component out of an entity's components, properties intact and able to be re-parented
func detach_component(component_id: StringName) -> EntityComponent:
	var component := get_component(component_id)

	if not component:
		return null

	component.on_removing()
	component_removing.emit(component_id, component)

	_components.erase(component_id)

	component._clear_owner()

	if component.get_parent():
		component.get_parent().remove_child(component)

	return component

##Returns true if the Entity has the given component
func has_component(component_id: StringName) -> bool:
	return _components.has(component_id)

##Returns Component Node of a given name if an Entity has it, otherwise returns null
func get_component(component_id: StringName) -> EntityComponent:
	return _components.get(component_id)

##Returns Array of EntityComponents of the entity
func get_components() -> Array[EntityComponent]:
	var result : Array[EntityComponent] = []
	
	for component in _components.values():
		result.append(component)
	
	return result

##Sets a collision shape to match with the Entity's
func apply_entity_collision_to(target: CollisionShape2D) -> void:
	if target.shape != null:
		return

	if collision == null:
		collision = $CollisionShape2D

	if collision.shape == null:
		return

	target.shape = collision.shape.duplicate()
	target.position = collision.position
	target.rotation = collision.rotation
	target.scale = collision.scale

##When run on a component, returns its root Entity.
##Also works on sprites, hitboxes, or anything under an Entity.
static func find_entity(node:Node) -> Entity:
	while node != null:
		if node is Entity:
			return node
		node = node.get_parent()
	return null

##Sets [param components_folder] to the Entity's component's folder Node even if it hasn't been loaded yet.
func _get_components_folder() -> Node:
	if not components_folder:
		components_folder = get_node_or_null("Components")

	return components_folder

##Tells all [EntityComponent]s about [param event] so they can respond accordingly
func dispatch_event(event: GameEvent) -> void:
	if not event:
		return

	for component in get_components():
		component.on_event(event)

##Receives [param resolution], collects contributions from its components, applies any modifiers,
##and returns [param resolution] after the Entity is done modifying it.
func resolve(resolution: GameResolution) -> GameResolution:
	if not resolution:
		return null

	if resolution.resolved:
		push_error("Cannot resolve an already-resolved GameResolution.")
		return resolution

	contribute_to_resolution(resolution)
	resolution.apply_modifiers()

	return resolution

##Asks all its [EntityComponent]s to contribute to [param resolution]
func contribute_to_resolution(resolution: GameResolution) -> void:
	if not resolution:
		return

	if resolution.resolved:
		push_error("Cannot contribute to an already-resolved GameResolution.")
		return

	for component in get_components():
		component.on_resolution(resolution)

func serialize_state() -> Dictionary:
	var component_states := {}

	for component in get_components():
		component_states[String(component.component_id)] = component.serialize_state()

	return {"instance_id": instance_id, "entity_id": String(entity_id), "position": [global_position.x, global_position.y], "components": component_states}

func deserialize_state(state: Dictionary) -> bool:
	if state.has("entity_id"):
		var saved_entity_id := StringName(state["entity_id"])

		if saved_entity_id != entity_id:
			push_error("Entity state ID mismatch. Expected %s, received %s." % [entity_id, saved_entity_id])
			return false

	var component_states = state.get("components", {})

	if not component_states is Dictionary:
		push_error("Serialized Entity components must be a Dictionary.")
		return false

	for component_key in component_states:
		var component_id := StringName(component_key)

		if not GameID.is_valid(component_id):
			push_error("Invalid saved EntityComponent ID: %s" % component_id)
			return false

		if not component_states[component_key] is Dictionary:
			push_error("Saved state for EntityComponent %s must be a Dictionary." % component_id)
			return false

	for component in get_components():
		if not component_states.has(String(component.component_id)):
			remove_component(component.component_id)

	for component_key in component_states:
		var component_id := StringName(component_key)

		if not has_component(component_id):
			var added_component := add_component(component_id)

			if not added_component:
				push_error("Could not restore EntityComponent: %s" % component_id)
				return false

		var component := get_component(component_id)
		component.deserialize_state(component_states[component_key])

	if state.has("instance_id"):
		if not restore_instance_id(String(state["instance_id"])):
			return false

	if state.has("position"):
		var position_data = state["position"]

		if position_data is Array and position_data.size() == 2:
			global_position = Vector2(float(position_data[0]),float(position_data[1]))

	return true

func restore_instance_id(saved_instance_id: String) -> bool:
	if saved_instance_id.is_empty():
		push_error("Cannot restore an empty runtime instance ID.")
		return false

	if saved_instance_id == instance_id:
		return true

	if not RuntimeObjectRegistry.reassign(self, instance_id, saved_instance_id):
		return false

	instance_id = saved_instance_id
	return true

##True if this entity should be allowed to run its own movement and physics on this machine.
##For the host, this is true for every entity. For a client, it's just their controlled player.
func is_simulated_locally() -> bool:
	if MultiplayerManager.is_world_authority():
		return true

	var controller := get_component(&"base:player_controller") as PlayerControllerComponent

	if not controller:
		return false

	return controller.is_locally_controlled()
