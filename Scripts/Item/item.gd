extends Resource
class_name Item

var item_id: StringName
var item_name: String
var sprite: Texture2D
var definition: ItemDefinition
var components: Array[ItemComponent]

func get_component(id: StringName) -> ItemComponent:
	for component in components:
		if component and component.get_id() == id:
			return component
	return null

func has_component(id: StringName) -> bool:
	return get_component(id) != null

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
			new_component.set(key, parameters[key])

	components.append(new_component)

	return new_component

func remove_component(id: StringName) -> ItemComponent:
	var component := get_component(id)
	if not component:
		return null
	
	components.erase(component)
	return component
