extends Node3D
class_name GameWorld

@onready var entities: Node3D = $Entities

static func find_world(node: Node) -> GameWorld:
	while node != null:
		if node is GameWorld:
			return node

		node = node.get_parent()

	return null

func spawn_entity(entity_id: StringName, entity_position: Vector3) -> Entity:
	var definition := DefinitionRegistry.get_entity(entity_id)

	if not definition:
		push_error("No EntityDefinition registered for: %s" % entity_id)
		return null

	return EntityFactory.spawn(definition, entity_position, entities)

func remove_entity(entity: Entity) -> void:
	if not entity:
		return

	RuntimeObjectRegistry.unregister(entity.instance_id,entity)

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

## Save game
func serialize_state() -> Dictionary:
	return {
		"items": serialize_items(),
		"entities": serialize_entities()
	}

## Load game from save
func deserialize_state(state: Dictionary) -> bool:
	var item_states = state.get("items", [])
	var entity_states = state.get("entities", [])

	if not item_states is Array:
		push_error("GameWorld item states must be an Array.")
		return false

	if not entity_states is Array:
		push_error("GameWorld entity states must be an Array.")
		return false

	clear_runtime_state()

	var result := RuntimeStateLoader.reconstruct(
		item_states,
		entity_states,
		entities
	)

	return result.has("items") and result.has("entities")

func clear_runtime_state() -> void:
	var current_items := get_items()
	var current_entities := get_entities()

	# Unregister Items first while inventories still exist.
	for item in current_items:
		if item:
			RuntimeObjectRegistry.unregister(
				item.instance_id,
				item
			)

	for entity in current_entities:
		if not entity:
			continue

		RuntimeObjectRegistry.unregister(
			entity.instance_id,
			entity
		)

		# Remove immediately from the container so reconstructed
		# Entities can reuse readable names like "Player".
		if entity.get_parent() == entities:
			entities.remove_child(entity)

		entity.queue_free()
