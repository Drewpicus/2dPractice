extends Resource
class_name Item

var item_name: String
var sprite: Texture2D
var definition: ItemDefinition
var components: Array[ItemComponent]

func get_component(id: StringName) -> ItemComponent:
	if not definition:
		return null
	return definition.get_component(id)

func has_component(id: StringName) -> bool:
	if not definition:
		return false
	return definition.has_component(id)

func add_component(component:StringName,parameters:Dictionary={}) -> ItemComponent:
	if not definition.components:
		return

	if component.is_empty():
		return
	
	if has_component(component):
		return
	
	var new_component: ItemComponent = ItemComponent.new()
	new_component.component_id = component
	
	
	if not parameters.is_empty():
		for key in parameters.keys():
			if key in new_component:
				new_component.set(key,parameters[key])
	
	return new_component
