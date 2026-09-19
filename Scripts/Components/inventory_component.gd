extends EntityComponent
class_name InventoryComponent

@export var items: Array[Item] = []

const DROPPED_ITEM_SCENE: PackedScene = preload("res://dropped_item.tscn")

signal items_updated

func add_item(item: Resource) -> void:
	items.append(item)
	items_updated.emit()

func take_all_items() -> Array[Item]:
	var new_inventory := items.duplicate()
	items.clear()
	items_updated.emit()
	return new_inventory

func drop_all_items() -> void:
	for item in items:
		_spawn_loot_pickup(item, root_entity.global_position)
		
	items.clear()
	items_updated.emit()

func _spawn_loot_pickup(_item_resource: Item, _drop_position: Vector2) -> void:
	var new_item: DroppedItem = DROPPED_ITEM_SCENE.instantiate()
	
	new_item.item = _item_resource
	new_item.global_position = _drop_position
	new_item.position.x += 16-(randf()*32)
	new_item.position.y += 16-(randf()*32)
	root_entity.get_parent().add_child(new_item)
	print("Dropped %s" % [new_item])

func get_interaction_suggestions() -> Array[StringName]:
	var capabilities: CapabilityComponent = get_component(&"capability")
	if capabilities:
		if capabilities.has_capability(&"possessive"):
			return [&"pickpocket"]
	return [&"open_inventory"]
