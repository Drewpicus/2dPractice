extends EntityComponent
class_name InventoryComponent

@export var items: Array[Item] = []

const DROPPED_ITEM_SCENE: PackedScene = preload("res://dropped_item.tscn")

signal items_updated
signal item_added(item:Item)
signal item_removed(item:Item)

func add_item(item: Item) -> void:
	items.append(item)
	item_added.emit(item)
	items_updated.emit()

func add_items(new_items: Array[Item]) -> void:
	items.append_array(new_items)
	for item in new_items:
		item_added.emit(item)
	items_updated.emit()

func remove_item(item: Item) -> Item:
	if item not in items:
		return null
	items.erase(item)
	item_removed.emit(item)
	items_updated.emit()
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
		item_removed.emit(item)
	items_updated.emit()
	return removed_items

func take_all_items() -> Array[Item]:
	var new_inventory := items.duplicate()
	items.clear()
	for item in new_inventory:
		item_removed.emit(item)
	items_updated.emit()
	return new_inventory

func drop_all_items() -> void:
	var all_items := items
	items.clear()
	for item in all_items:
		_spawn_loot_pickup(item, root_entity.global_position)
		item_removed.emit(item)
	items_updated.emit()

## @deprecated dropped items may be old
func _spawn_loot_pickup(_item_resource: Item, _drop_position: Vector2) -> void:
	var new_item: DroppedItem = DROPPED_ITEM_SCENE.instantiate()
	
	new_item.item = _item_resource
	new_item.global_position = _drop_position
	new_item.position += Vector2(randf_range(-16,16),randf_range(-16,16))
	root_entity.get_parent().add_child(new_item)
	print("Dropped %s" % [new_item])

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
	items.clear()

	var saved_items = state.get("items", [])

	if not saved_items is Array:
		push_error("Serialized inventory items must be an Array.")
		return

	for item_id_value in saved_items:
		var item_id := String(item_id_value)
		var item := RuntimeObjectRegistry.get_item(item_id)

		if not item:
			push_error(
				"Could not restore Inventory item instance: %s"
				% item_id
			)
			continue

		items.append(item)
