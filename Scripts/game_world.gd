extends Node2D
class_name GameWorld

@onready var entities: Node2D = $Entities
var _items: Dictionary[String, Item] = {}

@onready var terrain: TerrainRenderer = $Terrain
@onready var entity_spawner: MultiplayerSpawner = $EntitySpawner
@onready var command_system: WorldCommandSystem = $CommandSystem
@onready var movement_system: WorldMovementSystem = $MovementSystem
@onready var replication_system: WorldReplicationSystem = $ReplicationSystem

var world_data: WorldData

func _ready() -> void:
	entity_spawner.spawn_function = _spawn_network_entity

	if not MultiplayerManager.peer_left.is_connected(_on_peer_left):
		MultiplayerManager.peer_left.connect(_on_peer_left)

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

func spawn_entity(entity_id: StringName, entity_position: Vector2, runtime_components: Dictionary = {}, initial_component_states: Dictionary = {}) -> Entity:
	if not MultiplayerManager.is_world_authority():
		push_error("Non-authority tried to spawn Entity like a naughty client: %s" % entity_id)
		return null

	var definition := DefinitionRegistry.get_entity(entity_id)

	if not definition:
		push_error("No EntityDefinition registered for: %s" % entity_id)
		return null

	var instance_id := RuntimeObjectRegistry.generate_unique_id()

	var spawn_data := {
		"entity_id": String(entity_id),
		"instance_id": instance_id,
		"position": entity_position,
		"runtime_components": runtime_components,
		"initial_component_states": initial_component_states
	}

	var entity := entity_spawner.spawn(spawn_data) as Entity

	if entity:
		replication_system.track_entity(entity)

	return entity

func transfer_player_controller(from_entity: Entity, to_entity: Entity) -> bool:
	if (MultiplayerManager.session_active and not MultiplayerManager.is_world_authority()):
		return false

	var controller := from_entity.get_component(&"base:player_controller") as PlayerControllerComponent

	if not controller:
		return false

	var peer_id := controller.controller_peer_id

	if not _apply_player_controller_transfer(from_entity, to_entity):
		return false

	if MultiplayerManager.session_active:
		_receive_player_controller_transfer.rpc(from_entity.instance_id, to_entity.instance_id, peer_id)

	return true

func _apply_player_controller_transfer(from_entity: Entity, to_entity: Entity) -> bool:
	if not from_entity or not to_entity:
		return false

	if to_entity.has_component(&"base:player_controller"):
		return false

	var controller := from_entity.get_component(&"base:player_controller") as PlayerControllerComponent

	if not controller:
		return false

	# Don't leave either body moving from an old input source.
	var old_movement := from_entity.get_component(&"base:movement") as MovementComponent

	if old_movement:
		old_movement.input_direction = Vector2.ZERO

	var target_movement := to_entity.get_component(&"base:movement") as MovementComponent

	if target_movement:
		target_movement.input_direction = Vector2.ZERO

	controller = from_entity.detach_component(&"base:player_controller") as PlayerControllerComponent

	if not controller:
		return false

	if not to_entity.attach_component(controller):
		from_entity.attach_component(controller)
		return false

	return true

@rpc("authority", "call_remote", "reliable", 4)
func _receive_player_controller_transfer(from_instance_id: String, to_instance_id: String, controller_peer_id: int) -> void:
	if multiplayer.is_server():
		return

	var from_entity := RuntimeObjectRegistry.get_entity(from_instance_id)

	var to_entity := RuntimeObjectRegistry.get_entity(to_instance_id)

	if not from_entity or not to_entity:
		return

	var controller := from_entity.get_component(&"base:player_controller") as PlayerControllerComponent

	if not controller:
		return

	# Sanity check: we're moving the same player's controller.
	if controller.controller_peer_id != controller_peer_id:
		return

	_apply_player_controller_transfer(from_entity, to_entity)

func remove_entity(entity: Entity) -> void:
	if not entity:
		return

	if (MultiplayerManager.session_active and not MultiplayerManager.is_world_authority()):
		return

	replication_system.untrack_entity(entity)

	RuntimeObjectRegistry.unregister(entity.instance_id, entity)

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

func get_items() -> Array[Item]:
	var result: Array[Item] = []

	for item in _items.values():
		result.append(item)

	return result

func create_item(item_id: StringName) -> Item:
	if (MultiplayerManager.session_active and not MultiplayerManager.is_world_authority()):
		return null

	var definition := DefinitionRegistry.get_item(item_id)

	if not definition:
		return null

	var item := ItemFactory.build(definition)

	if not item:
		return null

	_items[item.instance_id] = item
	replication_system.track_item(item)

	if MultiplayerManager.session_active:
		_receive_item_created.rpc(String(item.item_id), item.instance_id)

	return item

@rpc("authority", "call_remote", "reliable", 5)
func _receive_item_created(item_id_string: String, instance_id: String) -> void:
	if multiplayer.is_server():
		return

	if _items.has(instance_id):
		return

	var item_id := StringName(item_id_string)

	if not GameID.is_valid(item_id):
		return

	var definition := DefinitionRegistry.get_item(item_id)

	if not definition:
		return

	var item := ItemFactory.build(definition)

	if not item:
		return

	if not item.restore_instance_id(instance_id):
		return

	_items[instance_id] = item

func remove_item(item: Item) -> void:
	if not item:
		return

	if (MultiplayerManager.session_active and not MultiplayerManager.is_world_authority()):
		return

	var instance_id := item.instance_id

	replication_system.untrack_item(item)

	_items.erase(instance_id)
	RuntimeObjectRegistry.unregister(instance_id, item)

	if MultiplayerManager.session_active:
		_receive_item_removed.rpc(instance_id)

@rpc("authority", "call_remote", "reliable", 5)
func _receive_item_removed(instance_id: String) -> void:
	if multiplayer.is_server():
		return

	var item = _items.get(instance_id)

	if not item:
		return

	_items.erase(instance_id)

	RuntimeObjectRegistry.unregister(instance_id, item)

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

	var result := RuntimeStateLoader.reconstruct(item_states, entity_states, entities)

	if not result.has("items") or not result.has("entities"):
		return false

	for item in result["items"]:
		if not item is Item:
			continue

		_items[item.instance_id] = item

		if MultiplayerManager.is_world_authority():
			replication_system.track_item(item)


	if MultiplayerManager.is_world_authority():
		for entity in result["entities"]:
			if entity is Entity:
				replication_system.track_entity(entity)

	return true

func clear_runtime_state() -> void:
	var current_items := get_items()
	var current_entities := get_entities()

	for item in current_items:
		if not item:
			continue

		replication_system.untrack_item(item)

		RuntimeObjectRegistry.unregister(item.instance_id, item)

	_items.clear()
	
	for entity in current_entities:
		if not entity:
			continue

		replication_system.untrack_entity(entity)

		RuntimeObjectRegistry.unregister(entity.instance_id, entity)

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
	
	var initial_component_states = spawn_data.get("initial_component_states",{})

	if not initial_component_states is Dictionary:
		entity.free()
		return null

	for component_key in initial_component_states:
		var component_id := StringName(component_key)

		if not GameID.is_valid(component_id):
			entity.free()
			return null

		var state = initial_component_states[component_key]

		if not state is Dictionary:
			entity.free()
			return null

		var component := entity.get_component(component_id)

		if not component:
			entity.free()
			return null

		component.deserialize_state(state)
	
	# Give the node the same canon name on every peer.
	entity.name = instance_id

	entity.position = entities.to_local(entity_position)

	print("Spawned ", entity_id, " | ", instance_id, " | peer ", multiplayer.get_unique_id())

	return entity

func _apply_runtime_components(entity: Entity, runtime_components: Dictionary) -> bool:
	for component_key in runtime_components:
		var component_id := StringName(component_key)

		if not GameID.is_valid(component_id):
			push_error("Invalid runtime component ID: %s" % component_id)
			return false

		var parameters = runtime_components[component_key]

		if not parameters is Dictionary:
			push_error("Runtime component parameters must be a Dictionary: %s" % component_id)
			return false

		var component := entity.add_component(component_id, parameters)

		if not component:
			push_error("Could not add runtime component: %s" % component_id)
			return false

	return true

func submit_movement_input(entity: Entity, sequence: int, direction: Vector2) -> void:
	movement_system.submit_movement_input(entity, sequence, direction)

func record_simulated_movement(entity: Entity, sequence: int) -> void:
	movement_system.record_simulated_movement(entity, sequence)

func submit_interaction(interaction: Interaction, interactor: Entity, target: Entity) -> void:
	command_system.submit_interaction(interaction, interactor, target)

func submit_take_item(viewer: Entity, source: Entity, item: Item) -> void:
	command_system.submit_take_item(viewer, source, item)

func submit_equip_item(entity: Entity, item: Item, slot: StringName) -> void:
	command_system.submit_equip_item(entity, item, slot)

func submit_unequip_item(entity: Entity, slot: StringName) -> void:
	command_system.submit_unequip_item(entity, slot)

func _on_peer_left(peer_id: int) -> void:
	if not MultiplayerManager.session_active:
		return

	if not MultiplayerManager.is_world_authority():
		return

	for entity in get_entities():
		var controller := entity.get_component(&"base:player_controller") as PlayerControllerComponent

		if not controller:
			continue

		if controller.controller_peer_id != peer_id:
			continue

		_remove_disconnected_player_controller(entity, peer_id)

func _remove_disconnected_player_controller(entity: Entity, peer_id: int) -> void:
	if not entity:
		return

	var controller := entity.get_component(&"base:player_controller") as PlayerControllerComponent

	if not controller:
		return

	if controller.controller_peer_id != peer_id:
		return

	var movement := entity.get_component(&"base:movement") as MovementComponent

	if movement:
		movement.input_direction = Vector2.ZERO

	entity.velocity = Vector2.ZERO

	entity.remove_component(&"base:player_controller")

	if MultiplayerManager.session_active:
		_receive_player_controller_removed.rpc(entity.instance_id, peer_id)

@rpc("authority", "call_remote", "reliable", 4)
func _receive_player_controller_removed(entity_instance_id: String, peer_id: int) -> void:
	if multiplayer.is_server():
		return

	var entity := RuntimeObjectRegistry.get_entity(entity_instance_id)

	if not entity:
		return

	var controller := entity.get_component(&"base:player_controller") as PlayerControllerComponent

	if not controller:
		return

	if controller.controller_peer_id != peer_id:
		return

	var movement := entity.get_component(&"base:movement") as MovementComponent

	if movement:
		movement.input_direction = Vector2.ZERO

	entity.velocity = Vector2.ZERO

	entity.remove_component(&"base:player_controller")

func get_entity_controlled_by_peer(peer_id: int) -> Entity:
	for entity in get_entities():
		var controller := entity.get_component(&"base:player_controller") as PlayerControllerComponent

		if not controller:
			continue

		if controller.controller_peer_id == peer_id:
			return entity

	return null

func get_locally_controlled_entity() -> Entity:
	return get_entity_controlled_by_peer(multiplayer.get_unique_id())
