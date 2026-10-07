extends RefCounted
class_name ItemFactory

static func build(definition: ItemDefinition) -> Item:
	if not definition:
		return null
	
	if not GameID.is_valid(definition.item_id):
		push_error("Invalid ItemDefinition ID: %s" % definition.item_id)
		return null


	var item := Item.new()
	
	item.item_id = definition.item_id
	item.definition = definition
	item.item_name = definition.item_name
	item.sprite = definition.sprite
	item.description = definition.description

	for component_definition in definition.components:
		var component := item.add_component(
			component_definition.component_id,
			component_definition.parameters
		)

		if not component:
			push_error(
				"Failed to build Item %s because component %s could not be added."
				% [
					definition.item_id,
					component_definition.component_id
				]
			)

			_cleanup_failed_item(item)
			return null

	return item

static func _cleanup_failed_item(
	item: Item
) -> void:
	if not item:
		return

	for component in item.get_components():
		item.remove_component(
			component.component_id
		)

	RuntimeObjectRegistry.unregister(
		item.instance_id,
		item
	)
