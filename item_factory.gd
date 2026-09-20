extends RefCounted
class_name ItemFactory

static func build(item: ItemDefinition) -> Item:
	var new_item := item.new() as Item
	
	new_item.name = item.item_name
	new_item.sprite = item.sprite

	for component in item.components:
		new_item.add_component(component.component_id,component.parameters)
	
	return new_item
