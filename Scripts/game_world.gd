extends Node2D
class_name GameWorld

@onready var entities: Node2D = $Entities

static func find_world(node: Node) -> GameWorld:
	while node != null:
		if node is GameWorld:
			return node

		node = node.get_parent()

	return null

func spawn_entity(entity_id: StringName, entity_position: Vector2) -> Entity:
	var definition := DefinitionRegistry.get_entity(entity_id)

	if not definition:
		push_error("No EntityDefinition registered for: %s" % entity_id)
		return null

	return EntityFactory.spawn(definition, entity_position, entities)

func remove_entity(entity: Entity) -> void:
	if not entity:
		return

	entity.queue_free()

func get_entities() -> Array[Entity]:
	var result: Array[Entity] = []

	for child in entities.get_children():
		if child is Entity:
			result.append(child)

	return result

func serialize_entities() -> Array:
	var states: Array = []

	for entity in get_entities():
		states.append(entity.serialize_state())

	return states

## NOTE: Only gets items inside an inventory
func get_items() -> Array[Item]:
	var result: Array[Item] = []
	var seen_ids: Dictionary[String, bool] = {}

	for entity in get_entities():
		var inventory := entity.get_component(&"base:inventory") as InventoryComponent

		if not inventory:
			continue

		for item in inventory.items:
			if not item:
				continue

			if seen_ids.has(item.instance_id):
				continue

			seen_ids[item.instance_id] = true
			result.append(item)

	return result

func serialize_items() -> Array:
	var states: Array = []

	for item in get_items():
		states.append(item.serialize_state())

	return states
