extends Resource
class_name Item

var instance_id: String
var item_id: StringName
var item_name: String
var sprite: Texture2D
var definition: ItemDefinition
var _components: Dictionary[StringName, ItemComponent] = {}

signal component_added(component_id: StringName,component: ItemComponent)

signal component_removing(component_id: StringName,component: ItemComponent)

func _init() -> void:
	instance_id = RuntimeObjectRegistry.generate_unique_id()
	RuntimeObjectRegistry.register(self, instance_id)

func get_component(component_id: StringName) -> ItemComponent:
	return _components.get(component_id)

func get_components() -> Array[ItemComponent]:
	var result: Array[ItemComponent] = []

	for component in _components.values():
		result.append(component)

	return result

func has_component(component_id: StringName) -> bool:
	return _components.has(component_id)

func add_component(component_id: StringName, parameters: Dictionary = {}) -> ItemComponent:
	if not GameID.is_valid(component_id):
		push_error("Invalid ItemComponent ID: %s" % component_id)
		return null

	if has_component(component_id):
		return null

	var new_component := ItemComponentRegistry.get_component_resource(component_id)

	if not new_component:
		push_error("Unregistered ItemComponent ID: %s" % component_id)
		return null

	if new_component.component_id != component_id:
		push_error(
			"ItemComponent ID mismatch. Requested %s, component identifies as %s." % [component_id, new_component.component_id])
		return null

	for key in parameters:
		if key in new_component:
			var value = ParameterCoercion.coerce_for_property(new_component, key, parameters[key])
			new_component.set(key, value)

	if not _register_component(new_component):
		return null

	return new_component

func remove_component(component_id: StringName) -> ItemComponent:
	var component := get_component(component_id)

	if not component:
		return null

	component.on_removing()
	component_removing.emit(component_id, component)
	_components.erase(component_id)
	component._clear_owner()

	return component

func _register_component(component: ItemComponent) -> bool:
	if not component:
		return false

	var component_id := component.component_id

	if not GameID.is_valid(component_id):
		push_error("Invalid ItemComponent ID: %s" % component_id)
		return false

	if _components.has(component_id):
		if _components[component_id] == component:
			return true

		push_error("Item already has an ItemComponent with ID: %s"% component_id)
		return false

	_components[component_id] = component
	component._set_owner(self)
	component.on_added()
	component_added.emit(component_id, component)

	return true

func dispatch_event(event: GameEvent) -> void:
	if not event:
		return

	for component in get_components():
		component.on_event(event)

func resolve(resolution: GameResolution) -> GameResolution:
	if not resolution:
		return null

	if resolution.resolved:
		push_error("Cannot resolve an already-resolved GameResolution.")
		return resolution

	contribute_to_resolution(resolution)
	resolution.apply_modifiers()

	return resolution

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

	return {"instance_id": instance_id, "item_id": String(item_id), "components": component_states}

func deserialize_state(state: Dictionary) -> bool:
	if state.has("item_id"):
		var saved_item_id := StringName(state["item_id"])

		if saved_item_id != item_id:
			push_error("Item state ID mismatch. Expected %s, received %s." % [item_id, saved_item_id])
			return false

	var component_states = state.get("components", {})

	if not component_states is Dictionary:
		push_error("Serialized Item components must be a Dictionary.")
		return false

	# Validate the saved component data before changing anything.
	for component_key in component_states:
		var component_id := StringName(component_key)

		if not GameID.is_valid(component_id):
			push_error("Invalid saved ItemComponent ID: %s" % component_id)
			return false

		if not component_states[component_key] is Dictionary:
			push_error("Saved state for ItemComponent %s must be a Dictionary." % component_id)
			return false

	# Remove components that no longer existed when the game was saved.
	for component in get_components():
		if not component_states.has(String(component.component_id)):
			remove_component(component.component_id)

	# Add missing components and restore every component's state.
	for component_key in component_states:
		var component_id := StringName(component_key)

		if not has_component(component_id):
			var added_component := add_component(component_id)

			if not added_component:
				push_error("Could not restore ItemComponent: %s" % component_id)
				return false

		var component := get_component(component_id)
		component.deserialize_state(component_states[component_key])

	if state.has("instance_id"):
		if not restore_instance_id(String(state["instance_id"])):
			return false

	return true

func restore_instance_id(saved_instance_id: String) -> bool:
	if saved_instance_id.is_empty():
		push_error("Cannot restore an empty runtime instance ID.")
		return false

	if saved_instance_id == instance_id:
		return true

	if not RuntimeObjectRegistry.reassign(
		self,
		instance_id,
		saved_instance_id
	):
		return false

	instance_id = saved_instance_id
	return true
