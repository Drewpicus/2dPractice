extends CharacterBody2D
class_name Entity

var entity_id: StringName
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var components_folder = $Components

var solid: bool = true
var components: Array

func _ready() -> void:
	var health_component := get_component(&"base:health") as HealthComponent
	if health_component:
		health_component.health_depleted.connect(die)
	if not solid:
		collision.disabled = true

func die() -> void:
	var remains_component = get_component(&"base:remains")
	if remains_component:
		remains_component.spawn_remains()
	queue_free()

##Add a component to the component folder, based on name, e.g. &"health"
##Parameters are a dict with the keys being variable names and the values being values
func add_component(component_id:StringName,parameters:Dictionary={}) -> EntityComponent:
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
			new_component.set(key, parameters[key])
	
	folder.add_child(new_component)
	return new_component

##Remove a component from the component folder, based on name, e.g. &"base:health"
func remove_component(component_id: StringName) -> void:
	var component := get_component(component_id)

	if not component:
		return

	component.queue_free()

##Returns true if the Entity has the given component
func has_component(component_id: StringName) -> bool:
	return get_component(component_id) != null

##Returns Component Node of a given name if an Entity has it, otherwise returns null
func get_component(component_id: StringName) -> EntityComponent:
	var folder := _get_components_folder()

	if not folder:
		return null

	for child in folder.get_children():
		if child is EntityComponent and child.component_id == component_id:
			return child

	return null

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

func _get_components_folder() -> Node:
	if not components_folder:
		components_folder = get_node_or_null("Components")

	return components_folder
