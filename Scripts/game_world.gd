extends Node2D
class_name GameWorld

@onready var entities: Node2D = $Entities
@onready var terrain: TerrainRenderer = $Terrain
@onready var entity_spawner: MultiplayerSpawner = $EntitySpawner

const MOVEMENT_SNAPSHOT_RATE: float = 20.0
const LOCAL_CORRECTION_SPEED: float = 20.0
const REMOTE_INTERPOLATION_SPEED: float = 50.0
const HARD_CORRECTION_DISTANCE: float = 32.0

var _snapshot_timer: float = 0.0
var _last_movement_sequence: Dictionary[String, int] = {}
var _network_positions: Dictionary[String, Vector2] = {}
var _network_velocities: Dictionary[String, Vector2] = {}

var world_data: WorldData

func _ready() -> void:
	entity_spawner.spawn_function = _spawn_network_entity

func _process(delta: float) -> void:
	if not MultiplayerManager.session_active:
		return

	if MultiplayerManager.is_world_authority():
		return

	for instance_id in _network_positions.keys():
		var entity := RuntimeObjectRegistry.get_entity(instance_id)

		if not entity:
			_network_positions.erase(instance_id)
			_network_velocities.erase(instance_id)
			continue

		var target_position := (_network_positions[instance_id])

		var controller := entity.get_component(&"base:player_controller") as PlayerControllerComponent

		var locally_controlled := (controller and controller.is_locally_controlled())

		var distance := entity.global_position.distance_to(target_position)

		if distance > HARD_CORRECTION_DISTANCE:
			entity.global_position = target_position
			continue

		if locally_controlled:
			_correct_local_prediction(entity,target_position)
		else:
			_interpolate_remote_entity(entity,target_position,delta)

			if _network_velocities.has(instance_id):
				entity.velocity = (_network_velocities[instance_id])

func _physics_process(delta: float) -> void:
	if not MultiplayerManager.session_active:
		return

	if not multiplayer.is_server():
		return

	_snapshot_timer += delta

	var snapshot_interval := (1.0 / MOVEMENT_SNAPSHOT_RATE)

	if _snapshot_timer < snapshot_interval:
		return

	_snapshot_timer -= snapshot_interval

	_send_movement_snapshot()

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

func transfer_player_controller(
	from_entity: Entity,
	to_entity: Entity
) -> bool:
	if (
		MultiplayerManager.session_active
		and not MultiplayerManager.is_world_authority()
	):
		return false

	var controller := from_entity.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return false

	var peer_id := controller.controller_peer_id

	if not _apply_player_controller_transfer(
		from_entity,
		to_entity
	):
		return false

	if MultiplayerManager.session_active:
		_receive_player_controller_transfer.rpc(
			from_entity.instance_id,
			to_entity.instance_id,
			peer_id
		)

	return true

func _apply_player_controller_transfer(
	from_entity: Entity,
	to_entity: Entity
) -> bool:
	if not from_entity or not to_entity:
		return false

	if to_entity.has_component(
		&"base:player_controller"
	):
		return false

	var controller := from_entity.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return false

	# Don't leave either body moving from an old input source.
	var old_movement := from_entity.get_component(
		&"base:movement"
	) as MovementComponent

	if old_movement:
		old_movement.input_direction = Vector2.ZERO

	var target_movement := to_entity.get_component(
		&"base:movement"
	) as MovementComponent

	if target_movement:
		target_movement.input_direction = Vector2.ZERO

	controller = from_entity.detach_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return false

	if not to_entity.attach_component(controller):
		from_entity.attach_component(controller)
		return false

	return true

@rpc("authority", "call_remote", "reliable", 4)
func _receive_player_controller_transfer(
	from_instance_id: String,
	to_instance_id: String,
	controller_peer_id: int
) -> void:
	if multiplayer.is_server():
		return

	var from_entity := RuntimeObjectRegistry.get_entity(
		from_instance_id
	)

	var to_entity := RuntimeObjectRegistry.get_entity(
		to_instance_id
	)

	if not from_entity or not to_entity:
		return

	var controller := from_entity.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return

	# Sanity check: we're moving the same player's controller.
	if controller.controller_peer_id != controller_peer_id:
		return

	_apply_player_controller_transfer(
		from_entity,
		to_entity
	)

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

func submit_movement_input(entity: Entity, sequence: int, direction: Vector2) -> void:
	if not entity:
		return

	# Normal singleplayer behavior.
	if not MultiplayerManager.session_active:
		_set_entity_movement_input(entity,direction)
		return

	var controller := entity.get_component(&"base:player_controller") as PlayerControllerComponent

	if not controller:
		return

	if not controller.is_locally_controlled():
		return

	# Host player can submit directly to the authoritative simulation.
	if multiplayer.is_server():
		_apply_movement_input(multiplayer.get_unique_id(),entity.instance_id,sequence,direction)
		return

	# Client prediction:
	# move our local copy immediately.
	_set_entity_movement_input(entity,direction)

	# Tell the authoritative host what input we used.
	_receive_movement_input.rpc_id(1,entity.instance_id,sequence,direction)

@rpc("any_peer","call_remote","unreliable_ordered",1)
func _receive_movement_input(entity_instance_id: String,sequence: int,direction: Vector2) -> void:
	if not multiplayer.is_server():
		return

	var sender_peer_id := multiplayer.get_remote_sender_id()

	_apply_movement_input(sender_peer_id,entity_instance_id,sequence,direction)

func _apply_movement_input(sender_peer_id: int,entity_instance_id: String,sequence: int,direction: Vector2) -> void:
	var entity := RuntimeObjectRegistry.get_entity(entity_instance_id)

	if not entity:
		return

	var controller := entity.get_component(&"base:player_controller") as PlayerControllerComponent

	if not controller:
		return

	# This is the important authority check.
	# A client cannot submit movement for somebody else's controller.
	if controller.controller_peer_id != sender_peer_id:
		return

	var last_sequence := int(_last_movement_sequence.get(entity_instance_id,-1))

	if sequence <= last_sequence:
		return

	_last_movement_sequence[entity_instance_id] = sequence

	_set_entity_movement_input(entity,direction)

func _set_entity_movement_input(entity: Entity,direction: Vector2) -> void:
	var movement := entity.get_component(&"base:movement") as MovementComponent

	if not movement:
		return

	if direction.length_squared() > 1.0:
		direction = direction.normalized()

	movement.input_direction = direction

func _send_movement_snapshot() -> void:
	var states: Array = []

	for entity in get_entities():
		if not entity.has_component(&"base:movement"):
			continue

		states.append({
			"instance_id": entity.instance_id,
			"position": entity.global_position,
			"velocity": entity.velocity,
			"last_input_sequence":
				int(_last_movement_sequence.get(entity.instance_id,-1))
		})

	if states.is_empty():
		return

	_receive_movement_snapshot.rpc(states)

@rpc("authority","call_remote","unreliable_ordered",2)
func _receive_movement_snapshot(
	states: Array) -> void:
	if multiplayer.is_server():
		return

	for state_value in states:
		if not state_value is Dictionary:
			continue

		var state := state_value as Dictionary

		var instance_id := String(state.get("instance_id", ""))

		var position = state.get("position",Vector2.ZERO)

		var velocity = state.get("velocity",Vector2.ZERO)

		if instance_id.is_empty():
			continue

		if not position is Vector2:
			continue

		if not velocity is Vector2:
			continue

		var entity := RuntimeObjectRegistry.get_entity(instance_id)

		if not entity:
			continue

		_network_positions[instance_id] = position

		_network_velocities[instance_id] = velocity

func _correct_local_prediction(entity: Entity, target_position: Vector2) -> void:
	var distance := entity.global_position.distance_to(target_position)

	if distance < HARD_CORRECTION_DISTANCE:
		return

	entity.global_position = target_position

func _interpolate_remote_entity(entity: Entity,target_position: Vector2,delta: float) -> void:
	var interpolation_amount := (1.0 - exp(-REMOTE_INTERPOLATION_SPEED * delta))

	entity.global_position = (entity.global_position.lerp(target_position,interpolation_amount))

func submit_interaction(
	interaction: Interaction,
	interactor: Entity,
	target: Entity
) -> void:
	if not interaction or not interactor or not target:
		return

	if not interaction.can_perform(interactor, target):
		return

	# Presentation-only/local interactions.
	if not interaction.requires_authority():
		interaction.perform(interactor, target)
		return

	# Singleplayer.
	if not MultiplayerManager.session_active:
		interaction.perform(interactor, target)
		return

	var controller := interactor.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return

	if not controller.is_locally_controlled():
		return

	# Host player can execute directly through the authoritative path.
	if multiplayer.is_server():
		_apply_interaction_request(
			multiplayer.get_unique_id(),
			interaction.interaction_id,
			interactor.instance_id,
			target.instance_id
		)
		return

	_receive_interaction_request.rpc_id(
		1,
		String(interaction.interaction_id),
		interactor.instance_id,
		target.instance_id
	)

@rpc("any_peer", "call_remote", "reliable", 3)
func _receive_interaction_request(
	interaction_id_string: String,
	interactor_instance_id: String,
	target_instance_id: String
) -> void:
	if not multiplayer.is_server():
		return

	_apply_interaction_request(
		multiplayer.get_remote_sender_id(),
		StringName(interaction_id_string),
		interactor_instance_id,
		target_instance_id
	)

func _apply_interaction_request(
	sender_peer_id: int,
	interaction_id: StringName,
	interactor_instance_id: String,
	target_instance_id: String
) -> void:
	var interactor := RuntimeObjectRegistry.get_entity(
		interactor_instance_id
	)

	var target := RuntimeObjectRegistry.get_entity(
		target_instance_id
	)

	if not interactor or not target:
		return

	var controller := interactor.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return

	# Client may only act through the Entity it currently controls.
	if controller.controller_peer_id != sender_peer_id:
		return

	var interactable := target.get_component(
		&"base:interactable"
	) as InteractableComponent

	if not interactable:
		return

	# Reconstruct the interaction from the HOST'S world state.
	var selected_interaction: Interaction

	for interaction in interactable.get_interactions(interactor):
		if interaction.interaction_id == interaction_id:
			selected_interaction = interaction
			break

	if not selected_interaction:
		return

	if not selected_interaction.requires_authority():
		return

	if not selected_interaction.can_perform(
		interactor,
		target
	):
		return

	selected_interaction.perform(
		interactor,
		target
	)
