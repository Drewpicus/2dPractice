extends RefCounted
class_name ItemFactory

static func build(definition: ItemDefinition) -> Item:
	var item := Item.new()
	
	item.item_id = definition.item_id
	item.definition = definition
	item.item_name = definition.item_name
	item.sprite = definition.sprite

	for component in definition.components:
		item.add_component(component.component_id, component.parameters)

	return item
