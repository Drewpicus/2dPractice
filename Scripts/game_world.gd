extends Node2D
class_name GameWorld

@onready var entities: Node2D = $Entities
@onready var terrain: TerrainRenderer = $Terrain
@onready var entity_spawner: MultiplayerSpawner = $EntitySpawner

var world_data: WorldData

func _ready() -> void:
	entity_spawner.spawn_function = _spawn_network_entity

func generate_world(world_size: Vector2i, _seed: int) -> void:
	var generator := WorldGenerator.new()

	world_data = generator.generate(world_size,_seed)

	terrain.render(world_data)

func cell_to_world(cell: Vector2i) -> Vector2:
	return terrain.to_global(terrain.map_to_local(cell))


func world_to_cell(world_position: Vector2) -> Vector2i:
	return terrain.local_to_map(terrain.to_local(world_position))

static func find_world(node: Node) -> GameWorld:
	while node != null:
		if node is GameWorld:
			return node

		node = node.get_parent()

	return null

func spawn_entity(entity_id: StringName, entity_position: Vector2, runtime_components: Dictionary = {}) -> Entity:
	var definition := DefinitionRegistry.get_entity(entity_id)

	if not definition:
		push_error("No EntityDefinition registered for: %s" % entity_id)
		return null

	if not MultiplayerManager.session_active:
		var entity := EntityFactory.spawn(definition, entity_position, entities)

		if not entity:
			return null

		if not _apply_runtime_components(entity, runtime_components):
			entity.queue_free()
			return null

		return entity
	
	#vvv MULTIPLAYER BEHAVIOR vvv
	
	if not multiplayer.is_server():
		push_error("Client is trying to spawn something smh: %s" % entity_id)
		return null
	
	var canon_instance_id := RuntimeObjectRegistry.generate_unique_id()
	
	var spawn_data := {
		"entity_id": String(entity_id),
		"instance_id": canon_instance_id,
		"position": entity_position,
		"runtime_components": runtime_components
	}
	
	return entity_spawner.spawn(spawn_data) as Entity

func transfer_player_controller(from_entity: Entity, to_entity: Entity) -> bool:
	if not from_entity or not to_entity:
		return false

	if to_entity.has_component(&"base:player_controller"):
		return false

	var controller := from_entity.detach_component(&"base:player_controller") as PlayerControllerComponent

	if not controller:
		return false

	if not to_entity.attach_component(controller):
		from_entity.attach_component(controller)
		return false

	return true

func remove_entity(entity: Entity) -> void:
	if not entity:
		return
	
	if MultiplayerManager.session_active:
		if not multiplayer.is_server():
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

func _spawn_network_entity(data: Variant) -> Node:
	if not data is Dictionary:
		push_error("Network Entity spawn data must be a Dictionary.")
		return null

	var spawn_data := data as Dictionary

	var entity_id := StringName(spawn_data.get("entity_id", ""))
	var instance_id := String(spawn_data.get("instance_id", ""))
	var entity_position = spawn_data.get("position",Vector2.ZERO)

	if not GameID.is_valid(entity_id):
		push_error("Invalid network Entity ID: %s. Likely base: is missing" % entity_id)
		return null

	if instance_id.is_empty():
		push_error("Network Entity spawn is missing an instance ID.")
		return null

	if not entity_position is Vector2:
		push_error("Network Entity position must be a Vector2.")
		return null

	var definition := DefinitionRegistry.get_entity(entity_id)

	if not definition:
		push_error("No EntityDefinition registered for network entity spawn: %s" % entity_id)
		return null

	var entity := EntityFactory.build(definition)

	if not entity:
		return null
	
	if not entity.restore_instance_id(instance_id):
		entity.free()
		return null
	
	var runtime_components = spawn_data.get("runtime_components",{})

	if not runtime_components is Dictionary:
		entity.free()
		return null

	if not _apply_runtime_components(entity, runtime_components):
		entity.free()
		return null
	
	# Give the node the same canon name on every peer.
	entity.name = instance_id

	entity.position = entities.to_local(entity_position)

	print("Spawned ", entity_id, " | ", instance_id, " | peer ", multiplayer.get_unique_id())

	return entity

func _apply_runtime_components(
	entity: Entity,
	runtime_components: Dictionary
) -> bool:
	for component_key in runtime_components:
		var component_id := StringName(component_key)

		if not GameID.is_valid(component_id):
			push_error(
				"Invalid runtime component ID: %s"
				% component_id
			)
			return false

		var parameters = runtime_components[component_key]

		if not parameters is Dictionary:
			push_error(
				"Runtime component parameters must be a Dictionary: %s"
				% component_id
			)
			return false

		var component := entity.add_component(
			component_id,
			parameters
		)

		if not component:
			push_error(
				"Could not add runtime component: %s"
				% component_id
			)
			return false

	return true
