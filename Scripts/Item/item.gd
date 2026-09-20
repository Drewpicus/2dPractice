extends Resource
class_name Item

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

func add_component(component: StringName, parameters: Dictionary = {}) -> ItemComponent:
	if component.is_empty():
		return null
	
	if has_component(component):
		return null
	
	var new_component := ItemComponentRegistry.get_component_resource(component)
	if not new_component:
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
