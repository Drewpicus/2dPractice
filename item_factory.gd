extends RefCounted
class_name ItemFactory

static func build(definition: ItemDefinition) -> Item:
	var item := Item.new()
	item.definition = definition
	
	item.item_name = definition.item_name
	item.sprite = definition.sprite

	for component in definition.components:
		item.components.append(component.duplicate(true))

	return item
