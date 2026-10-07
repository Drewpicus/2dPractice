extends EntityComponent
class_name InventoryComponent

@export var items: Array[Item] = []

signal items_updated

func add_item(item: Item) -> void:
	items.append(item)
	_notify_item_added(item)
	items_updated.emit()
	notify_state_changed()

func add_items(new_items: Array[Item]) -> void:
	items.append_array(new_items)
	for item in new_items:
		_notify_item_added(item)
	items_updated.emit()
	notify_state_changed()

func remove_item(item: Item) -> Item:
	if item not in items:
		return null
	items.erase(item)
	_notify_item_removed(item)
	items_updated.emit()
	notify_state_changed()
	return item

func remove_items(items_to_remove: Array[Item],ignore_missing: bool = true) -> Array[Item]:
	var removed_items: Array[Item]
	for item in items_to_remove:
		if item not in items:
			if ignore_missing:
				continue
			return []
		removed_items.append(item)
	
	items = items.filter(func(item): return not removed_items.has(item))
	for item in removed_items:
		_notify_item_removed(item)
	items_updated.emit()
	notify_state_changed()
	return removed_items

func take_all_items() -> Array[Item]:
	var new_inventory := items.duplicate()
	items.clear()
	for item in new_inventory:
		_notify_item_removed(item)
	items_updated.emit()
	notify_state_changed()
	return new_inventory

func _notify_item_added(
	item: Item
) -> void:
	if not item:
		return

	item.on_added_to_inventory(
		root_entity
	)

	_notify_item_added(item)


func _notify_item_removed(
	item: Item
) -> void:
	if not item:
		return

	item.on_removed_from_inventory(
		root_entity
	)

	_notify_item_removed(item)

func get_interaction_suggestions() -> Array[StringName]:
	var capabilities: CapabilityComponent = get_component(&"base:capability")
	if capabilities:
		if capabilities.has_capability(&"base:possessive"):
			return [&"base:pickpocket"]
	return [&"base:open_inventory"]

func serialize_state() -> Dictionary:
	var item_ids: Array[String] = []

	for item in items:
		if item:
			item_ids.append(item.instance_id)

	return {
		"items": item_ids
	}

func deserialize_state(state: Dictionary) -> void:
	var saved_items = state.get("items", [])

	if not saved_items is Array:
		push_error(
			"Serialized inventory items must be an Array."
		)
		return

	var new_items: Array[Item] = []

	for item_id_value in saved_items:
		var item_id := String(item_id_value)
		var item := RuntimeObjectRegistry.get_item(item_id)

		if not item:
			push_error(
				"Could not restore Inventory item instance: %s"
				% item_id
			)
			continue

		new_items.append(item)

	var old_items := items.duplicate()

	for item in old_items:
		if item not in new_items:
			_notify_item_removed(item)

	items = new_items

	for item in new_items:
		if item not in old_items:
			_notify_item_added(item)

	items_updated.emit()
