extends Resource
class_name Item

var instance_id: String = RuntimeID.generate()
var item_id: StringName
var item_name: String
var sprite: Texture2D
var definition: ItemDefinition
var _components: Dictionary[StringName, ItemComponent] = {}

signal component_added(component_id: StringName,component: ItemComponent)

signal component_removing(component_id: StringName,component: ItemComponent)

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

	for component in get_components():
		component.on_resolution(resolution)

	resolution.apply_modifiers()

	return resolution
