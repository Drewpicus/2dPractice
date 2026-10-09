extends Node2D
class_name GameWorld

@onready var entities: Node2D = $Entities
var _items: Dictionary[String, Item] = {}
var _terrain_overrides: Dictionary[Vector2i, StringName] = {}
var _terrain_originals: Dictionary[Vector2i, StringName] = {}

@onready var terrain: TerrainRenderer = $Terrain
@onready var entity_spawner: MultiplayerSpawner = $EntitySpawner
@onready var command_system: WorldCommandSystem = $CommandSystem
@onready var movement_system: WorldMovementSystem = $MovementSystem
@onready var replication_system: WorldReplicationSystem = $ReplicationSystem
@onready var tick_system: WorldTickSystem = $TickSystem
@onready var pathfinding_system: WorldPathfindingSystem = $PathfindingSystem

var world_data: WorldData

signal inspection_requested(viewer: Entity, target: Entity)
signal inventory_requested(viewer: Entity, owner: Entity)

func _ready() -> void:
	entity_spawner.spawn_function = _spawn_network_entity

	if not MultiplayerManager.peer_left.is_connected(_on_peer_left):
		MultiplayerManager.peer_left.connect(_on_peer_left)

##Returns the GameWorld node in the Scene Tree that [param node] lives in.
##If [param node] is not in a GameWorld, returns null.
static func find_world(node: Node) -> GameWorld:
	while node != null:
		if node is GameWorld:
			return node

		node = node.get_parent()

	return null

#region World Terrain

func generate_world(
	world_size: Vector2i,
	seed: int
) -> void:
	_terrain_overrides.clear()
	_terrain_originals.clear()

	var generator := WorldGenerator.new()

	world_data = generator.generate(
		world_size,
		seed
	)

	terrain.render(world_data)

	pathfinding_system.rebuild()

func start_new_world(
	world_size: Vector2i,
	world_seed: int
) -> void:
	if not MultiplayerManager.is_world_authority():
		return

	if world_size.x <= 0 or world_size.y <= 0:
		push_error(
			"World size must be positive."
		)
		return

	generate_world(
		world_size,
		world_seed
	)

	if MultiplayerManager.session_active:
		_receive_world_generation.rpc(
			world_size,
			world_seed
		)

@rpc("authority", "call_remote", "reliable")
func _receive_world_generation(
	world_size: Vector2i,
	world_seed: int
) -> void:
	if MultiplayerManager.is_world_authority():
		return

	if world_size.x <= 0 or world_size.y <= 0:
		return

	generate_world(
		world_size,
		world_seed
	)

func set_terrain(
	cell: Vector2i,
	terrain_id: StringName
) -> bool:
	if (
		MultiplayerManager.session_active
		and not MultiplayerManager.is_world_authority()
	):
		return false

	if not _apply_terrain_change(
		cell,
		terrain_id
	):
		return false

	if MultiplayerManager.session_active:
		_receive_terrain_change.rpc(
			cell,
			String(terrain_id)
		)

	return true


func _apply_terrain_change(
	cell: Vector2i,
	terrain_id: StringName
) -> bool:
	if not world_data:
		return false

	if not world_data.in_bounds(cell):
		return false

	if not GameID.is_valid(terrain_id):
		return false

	if not terrain.has_terrain(terrain_id):
		push_error(
			"Unknown terrain ID: %s"
			% terrain_id
		)
		return false

	if not _terrain_originals.has(cell):
		_terrain_originals[cell] = world_data.get_terrain(
			cell
		)

	world_data.set_terrain(
		cell,
		terrain_id
	)

	terrain.render_cell(
		cell,
		terrain_id
	)

	var original_terrain := _terrain_originals[cell]

	if terrain_id == original_terrain:
		_terrain_overrides.erase(cell)
		_terrain_originals.erase(cell)
	else:
		_terrain_overrides[cell] = terrain_id

	return true


@rpc("authority", "call_remote", "reliable")
func _receive_terrain_change(
	cell: Vector2i,
	terrain_id_string: String
) -> void:
	if MultiplayerManager.is_world_authority():
		return

	_apply_terrain_change(
		cell,
		StringName(terrain_id_string)
	)

func cell_to_world(cell: Vector2i) -> Vector2:
	return terrain.to_global(terrain.map_to_local(cell))

func world_to_cell(world_position: Vector2) -> Vector2i:
	return terrain.local_to_map(terrain.to_local(world_position))

#endregion

#region Entities
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

func remove_entity(entity: Entity) -> void:
	if not entity:
		return

	if (MultiplayerManager.session_active and not MultiplayerManager.is_world_authority()):
		return

	replication_system.untrack_entity(entity)

	RuntimeObjectRegistry.unregister(entity.instance_id, entity)

	entity.queue_free()

##Returns an Array of every [Entity] in the [GameWorld]
func get_entities() -> Array[Entity]:
	var result: Array[Entity] = []

	for child in entities.get_children():
		if child is Entity:
			result.append(child)

	return result

#endregion

#region Items

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

#endregion

#region Transfer Player Controller

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

#endregion

#region Serialization (Save/Load)

func serialize_entities() -> Array:
	var states: Array = []

	for entity in get_entities():
		states.append(entity.serialize_state())

	return states

func serialize_items() -> Array:
	var states: Array = []

	for item in get_items():
		states.append(item.serialize_state())

	return states

## Save game
func serialize_state() -> Dictionary:
	if not world_data:
		push_error(
			"Cannot serialize GameWorld without WorldData."
		)
		return {}

	return {
		"world_data": {
			"size": [
				world_data.size.x,
				world_data.size.y
			],
			"seed": world_data.get_seed(),
			"terrain_overrides":
					serialize_terrain_overrides()
		},
		"items": serialize_items(),
		"entities": serialize_entities()
	}

## Load game from save
func deserialize_state(state: Dictionary) -> bool:
	var world_data_state = state.get(
		"world_data",
		{}
	)

	if not world_data_state is Dictionary:
		push_error(
			"Serialized world data must be a Dictionary."
		)
		return false

	var size_data = world_data_state.get(
		"size",
		[]
	)

	if (
		not size_data is Array
		or size_data.size() != 2
	):
		push_error(
			"Serialized world size must contain two values."
		)
		return false

	var world_size := Vector2i(
		int(size_data[0]),
		int(size_data[1])
	)

	if world_size.x <= 0 or world_size.y <= 0:
		push_error(
			"Serialized world size must be positive."
		)
		return false

	if not world_data_state.has("seed"):
		push_error(
			"Serialized world data is missing its seed."
		)
		return false

	var world_seed := int(
		world_data_state["seed"]
	)

	var terrain_override_states = world_data_state.get(
		"terrain_overrides",
		[]
	)

	if not terrain_override_states is Array:
		push_error(
			"Serialized terrain overrides must be an Array."
		)
		return false

	var item_states = state.get(
		"items",
		[]
	)

	var entity_states = state.get(
		"entities",
		[]
	)

	if not item_states is Array:
		push_error("GameWorld item states must be an Array.")
		return false

	if not entity_states is Array:
		push_error("GameWorld entity states must be an Array.")
		return false

	clear_runtime_state()

	generate_world(
		world_size,
		world_seed
	)
	
	if not _apply_saved_terrain_overrides(terrain_override_states):
		return false

	var result := RuntimeStateLoader.reconstruct(
		item_states,
		entity_states,
		entities
	)

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

func serialize_terrain_overrides() -> Array:
	var states: Array = []

	for cell_value in _terrain_overrides:
		var cell: Vector2i = cell_value
		var terrain_id := _terrain_overrides[cell]

		states.append({
			"cell": [
				cell.x,
				cell.y
			],
			"terrain_id": String(terrain_id)
		})

	return states

func _apply_saved_terrain_overrides(
	states: Array
) -> bool:
	for state_value in states:
		if not state_value is Dictionary:
			push_error(
				"Serialized terrain override must be a Dictionary."
			)
			return false

		var state := state_value as Dictionary

		var cell_data = state.get(
			"cell",
			[]
		)

		if (
			not cell_data is Array
			or cell_data.size() != 2
		):
			push_error(
				"Serialized terrain override cell must contain two values."
			)
			return false

		var cell := Vector2i(
			int(cell_data[0]),
			int(cell_data[1])
		)

		var terrain_id := StringName(
			state.get(
				"terrain_id",
				""
			)
		)

		if not _apply_terrain_change(
			cell,
			terrain_id
		):
			push_error(
				"Could not restore terrain override at %s."
				% cell
			)
			return false

	return true

#endregion

##EntitySpawner's function for building entities
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

func submit_move_to(entity: Entity, destination: Vector2) -> void:
	movement_system.submit_move_to(entity, destination)

func record_simulated_movement(entity: Entity, sequence: int) -> void:
	movement_system.record_simulated_movement(entity, sequence)

#region Command System handles

func submit_interaction(interaction: Interaction, interactor: Entity, target: Entity) -> void:
	command_system.submit_interaction(interaction, interactor, target)

func submit_take_item(viewer: Entity, source: Entity, item: Item) -> void:
	command_system.submit_take_item(viewer, source, item)

func submit_equip_item(entity: Entity, item: Item, slot: StringName) -> void:
	command_system.submit_equip_item(entity, item, slot)

func submit_unequip_item(entity: Entity, slot: StringName) -> void:
	command_system.submit_unequip_item(entity, slot)

func submit_drop_item(entity: Entity, item: Item) -> void:
	command_system.submit_drop_item(entity, item)

func submit_consume_item(consumer: Entity, item: Item) -> void:
	command_system.submit_consume_item(consumer, item)

func submit_ability(ability: Ability, use: AbilityUse) -> void:
	command_system.submit_ability(ability, use)

#endregion

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

func spawn_dropped_item(item: Item, world_position: Vector2) -> Entity:
	if not MultiplayerManager.is_world_authority():
		return null

	if not item:
		return null

	if not _items.has(item.instance_id):
		return null

	if _items[item.instance_id] != item:
		return null

	return spawn_entity(
		&"base:dropped_item",
		world_position,
		{},
		{
			"base:dropped_item": {
				"item_instance_id":
					item.instance_id
			}
		}
	)

#region UI Requests

func request_inspection(viewer: Entity, target: Entity) -> void:
	if not viewer or not target:
		return

	inspection_requested.emit(viewer, target)


func request_inventory(viewer: Entity, _owner: Entity) -> void:
	if not viewer or not _owner:
		return

	inventory_requested.emit(viewer, _owner)

#endregion

func move_entity_to(
	entity: Entity,
	destination: Vector2
) -> bool:
	if not entity:
		return false

	if (
		MultiplayerManager.session_active
		and not MultiplayerManager.is_world_authority()
	):
		return false

	var path := pathfinding_system.find_path(
		entity,
		destination
	)

	return _move_entity_along_path(
		entity,
		path
	)

func move_entity_to_entity(
	entity: Entity,
	target: Entity,
	stopping_distance: float = 0.0
) -> bool:
	if not entity or not target:
		return false

	if stopping_distance < 0.0:
		return false

	if (
		MultiplayerManager.session_active
		and not MultiplayerManager.is_world_authority()
	):
		return false

	var path := pathfinding_system.find_path_to_entity(
		entity,
		target,
		stopping_distance
	)

	return _move_entity_along_path(
		entity,
		path
	)

func _move_entity_along_path(
	entity: Entity,
	path: PackedVector2Array
) -> bool:
	if not entity:
		return false

	if path.is_empty():
		return false

	var movement := entity.get_component(
		&"base:movement"
	) as MovementComponent

	if not movement:
		return false

	var combat := entity.get_component(
		&"base:combat"
	) as CombatComponent

	var in_combat := (
		combat
		and combat.current_combat
		and combat.current_combat.started
	)

	if in_combat:
		if not combat.current_combat.is_active(
			entity
		):
			return false

		# For now, a combat move must finish before
		# another destination can be chosen.
		if movement.has_path():
			return false

	var movement_cost := 0.0

	if in_combat:
		movement_cost = pathfinding_system.measure_path(
			entity.global_position,
			path
		)

		if movement_cost > combat.movement_remaining:
			path = pathfinding_system.trim_path(
				entity.global_position,
				path,
				combat.movement_remaining
			)

			if path.is_empty():
				return false

			movement_cost = (
				pathfinding_system.measure_path(
					entity.global_position,
					path
				)
			)

		if not combat.can_spend_movement(
			movement_cost
		):
			return false

	if not movement.follow_path(
		path
	):
		return false

	if in_combat:
		combat.spend_movement(
			movement_cost
		)

		print(
			entity.entity_name,
			" spent ",
			movement_cost,
			" movement. Remaining: ",
			combat.movement_remaining
		)

	return true

func get_path_distance(
	entity: Entity,
	destination: Vector2
) -> float:
	return pathfinding_system.get_path_distance(
		entity,
		destination
	)
