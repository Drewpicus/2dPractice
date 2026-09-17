extends EntityComponent
class_name InventoryComponent

@export var items: Array[Resource] = []

signal items_updated

func _ready() -> void:
	var health_component = get_component(&"health")
	if health_component:
		health_component.health_depleted.connect(drop_all_items)

func add_item(item: Resource) -> void:
	items.append(item)
	items_updated.emit()

func drop_all_items() -> void:
	var entity = get_parent().get_parent()
	if not entity: return
	
	for item in items:
		_spawn_loot_pickup(item, entity.global_position)
		
	items.clear()
	items_updated.emit()
	print("items dropped")

func _spawn_loot_pickup(_item_resource: Resource, _drop_position: Vector2) -> void:
	pass

func get_interaction_suggestions() -> Array[StringName]:
	var capabilities: CapabilityComponent = get_component(&"capability")
	if capabilities != null:
		if capabilities.has_capability(&"possessive"):
			return [&"pickpocket"]
	return [&"open_inventory"]
