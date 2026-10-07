extends Node
class_name WorldMovementSystem


const MOVEMENT_SNAPSHOT_RATE: float = 20.0
const FAR_MOVEMENT_SNAPSHOT_RATE: float = 2.0
const FULL_RATE_RADIUS: float = 1024.0
const REMOTE_VISUAL_INTERPOLATION_SPEED: float = 20.0
const REMOTE_VISUAL_TELEPORT_DISTANCE: float = 160.0

var _snapshot_timer: float = 0.0
var _far_snapshot_timer: float = 0.0

var _last_movement_sequence: Dictionary[int, int] = {}
var _last_simulated_movement_sequence: Dictionary[int, int] = {}

var _network_positions: Dictionary[String, Vector2] = {}
var _network_velocities: Dictionary[String, Vector2] = {}
var _remote_sprite_rest_positions: Dictionary[String, Vector2] = {}

var _teleport_revisions: Dictionary[String, int] = {}

@onready var world: GameWorld = get_parent() as GameWorld


func _ready() -> void:
	if not MultiplayerManager.peer_left.is_connected(_on_peer_left):
		MultiplayerManager.peer_left.connect(_on_peer_left)


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
			_remote_sprite_rest_positions.erase(instance_id)
			continue

		var controller := entity.get_component(&"base:player_controller") as PlayerControllerComponent

		if (controller and controller.is_locally_controlled()):
			continue

		_interpolate_remote_visual(entity, instance_id, delta)

		if _network_velocities.has(instance_id):
			entity.velocity = _network_velocities[instance_id]


func _physics_process(delta: float) -> void:
	if not MultiplayerManager.session_active:
		return

	if not MultiplayerManager.is_world_authority():
		return

	_snapshot_timer += delta
	_far_snapshot_timer += delta

	var snapshot_interval := (1.0 / MOVEMENT_SNAPSHOT_RATE)

	var far_snapshot_interval := (1.0 / FAR_MOVEMENT_SNAPSHOT_RATE)

	if _snapshot_timer >= snapshot_interval:
		_snapshot_timer -= snapshot_interval
		_send_movement_snapshots(true)

	if _far_snapshot_timer >= far_snapshot_interval:
		_far_snapshot_timer -= far_snapshot_interval
		_send_movement_snapshots(false)

func submit_movement_input(entity: Entity, sequence: int, direction: Vector2) -> void:
	if not entity:
		return

	# Preserve ordinary offline behavior.
	if not MultiplayerManager.session_active:
		_set_entity_movement_input(entity, direction)
		return

	var controller := entity.get_component(&"base:player_controller") as PlayerControllerComponent

	if not controller:
		return

	if not controller.is_locally_controlled():
		return

	# Host applies directly to the authoritative simulation.
	if MultiplayerManager.is_world_authority():
		_apply_movement_input(multiplayer.get_unique_id(), entity.instance_id, sequence, direction)
		return

	# Client prediction.
	_set_entity_movement_input(entity, direction, sequence)

	_receive_movement_input.rpc_id(1, entity.instance_id, sequence, direction)


@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func _receive_movement_input(entity_instance_id: String, sequence: int, direction: Vector2) -> void:
	if not MultiplayerManager.is_world_authority():
		return

	_apply_movement_input(multiplayer.get_remote_sender_id(), entity_instance_id, sequence, direction)


func _apply_movement_input(sender_peer_id: int, entity_instance_id: String, sequence: int, direction: Vector2) -> void:
	var entity := RuntimeObjectRegistry.get_entity(entity_instance_id)

	if not entity:
		return

	var controller := entity.get_component(&"base:player_controller") as PlayerControllerComponent

	if not controller:
		return

	if controller.controller_peer_id != sender_peer_id:
		return

	var last_sequence := int(_last_movement_sequence.get(sender_peer_id, -1))

	if sequence <= last_sequence:
		return

	_last_movement_sequence[sender_peer_id] = sequence

	_set_entity_movement_input(entity, direction, sequence)


func _set_entity_movement_input(entity: Entity, direction: Vector2, sequence: int = -1) -> void:
	var movement := entity.get_component(&"base:movement") as MovementComponent

	if not movement:
		return

	if direction.length_squared() > 1.0:
		direction = direction.normalized()

	movement.input_direction = direction

	if sequence >= 0:
		movement.input_sequence = sequence


func record_simulated_movement(entity: Entity, sequence: int) -> void:
	if not MultiplayerManager.session_active:
		return

	if not MultiplayerManager.is_world_authority():
		return

	if not entity or sequence < 0:
		return

	var controller := entity.get_component(&"base:player_controller") as PlayerControllerComponent

	if not controller:
		return

	_last_simulated_movement_sequence[controller.controller_peer_id] = sequence

func _send_movement_snapshots(full_rate: bool) -> void:
	var radius_squared := (FULL_RATE_RADIUS * FULL_RATE_RADIUS)

	for peer_value in multiplayer.get_peers():
		var peer_id := int(peer_value)

		var controlled_entity := (world.get_entity_controlled_by_peer(peer_id))

		if not controlled_entity:
			continue

		var states: Array = []

		for entity in world.get_entities():
			if not entity.has_component(&"base:movement"):
				continue

			var distance_squared := (controlled_entity.global_position.distance_squared_to(entity.global_position))

			var is_full_rate := ((entity == controlled_entity) or (distance_squared <= radius_squared))

			if is_full_rate != full_rate:
				continue

			states.append(_build_movement_state(entity))

		if states.is_empty():
			continue

		_receive_movement_snapshot.rpc_id(peer_id, states)

func _build_movement_state(entity: Entity) -> Dictionary:
	var last_input_sequence := -1

	var controller := entity.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if controller:
		last_input_sequence = int(
			_last_simulated_movement_sequence.get(
				controller.controller_peer_id,
				-1
			)
		)

	return {
		"instance_id": entity.instance_id,
		"position": entity.global_position,
		"velocity": entity.velocity,
		"last_input_sequence": last_input_sequence,
		"teleport_revision": int(
			_teleport_revisions.get(
				entity.instance_id,
				0
			)
		)
	}

@rpc("authority", "call_remote", "unreliable_ordered", 2)
func _receive_movement_snapshot(states: Array) -> void:
	if MultiplayerManager.is_world_authority():
		return

	for state_value in states:
		if not state_value is Dictionary:
			continue

		var state := state_value as Dictionary

		var instance_id := String(state.get("instance_id", ""))

		var server_position = state.get("position", Vector2.ZERO)

		var velocity = state.get("velocity", Vector2.ZERO)

		var last_input_sequence := int(state.get("last_input_sequence", -1))

		if instance_id.is_empty():
			continue

		if not server_position is Vector2:
			continue

		if not velocity is Vector2:
			continue

		var entity := RuntimeObjectRegistry.get_entity(instance_id)

		if not entity:
			continue

		var teleport_revision := int(
			state.get(
				"teleport_revision",
				0
			)
		)

		var known_revision := int(
			_teleport_revisions.get(
				instance_id,
				0
			)
		)

		# This snapshot predates a teleport we've
		# already received.
		if teleport_revision < known_revision:
			continue

		# The snapshot itself may arrive before the
		# reliable teleport RPC.
		if teleport_revision > known_revision:
			_apply_received_teleport(
				entity,
				instance_id,
				server_position,
				teleport_revision
			)

			_network_velocities[
				instance_id
			] = velocity

			continue

		var controller := entity.get_component(&"base:player_controller") as PlayerControllerComponent

		if (controller and controller.is_locally_controlled()):
			controller.reconcile_prediction(last_input_sequence, server_position)
			continue

		_network_positions[instance_id] = server_position

		_network_velocities[instance_id] = velocity

		_apply_remote_snapshot(entity, instance_id, server_position)


func _apply_remote_snapshot(entity: Entity, instance_id: String, target_position: Vector2) -> void:
	var sprite := entity.get_node_or_null("Sprite2D") as Sprite2D

	var old_entity_position := (entity.global_position)

	var movement_distance := (old_entity_position.distance_to(target_position))

	if (sprite and not _remote_sprite_rest_positions.has(instance_id)):
		_remote_sprite_rest_positions[instance_id] = sprite.position

	var old_visual_position := Vector2.ZERO

	if sprite:
		old_visual_position = (sprite.global_position)

	# Physics uses the newest authoritative
	# transform immediately.
	entity.global_position = target_position

	if not sprite:
		return

	var rest_position := (_remote_sprite_rest_positions.get(instance_id, sprite.position) as Vector2)

	if (movement_distance > REMOTE_VISUAL_TELEPORT_DISTANCE):
		sprite.position = rest_position
		return

	# Keep the previous rendered position,
	# then let the sprite catch up visually.
	sprite.global_position = old_visual_position


func _interpolate_remote_visual(entity: Entity, instance_id: String, delta: float) -> void:
	var sprite := entity.get_node_or_null("Sprite2D") as Sprite2D

	if not sprite:
		return

	if not _remote_sprite_rest_positions.has(instance_id):
		_remote_sprite_rest_positions[instance_id] = sprite.position

	var rest_position := (_remote_sprite_rest_positions[instance_id])

	var interpolation_amount := (1.0 - exp(-REMOTE_VISUAL_INTERPOLATION_SPEED * delta))

	sprite.position = sprite.position.lerp(rest_position, interpolation_amount)


func _on_peer_left(peer_id: int) -> void:
	_last_movement_sequence.erase(peer_id)
	_last_simulated_movement_sequence.erase(peer_id)

func teleport_entity(
	entity: Entity,
	destination: Vector2
) -> bool:
	if not MultiplayerManager.is_world_authority():
		return false

	if not entity:
		return false

	var revision := int(
		_teleport_revisions.get(
			entity.instance_id,
			0
		)
	) + 1

	_teleport_revisions[
		entity.instance_id
	] = revision

	entity.global_position = destination

	if MultiplayerManager.session_active:
		_receive_teleport.rpc(
			entity.instance_id,
			destination,
			revision
		)

	return true

@rpc("authority", "call_remote", "reliable", 6)
func _receive_teleport(
	instance_id: String,
	destination: Vector2,
	revision: int
) -> void:
	if MultiplayerManager.is_world_authority():
		return

	var entity := RuntimeObjectRegistry.get_entity(
		instance_id
	)

	if not entity:
		return

	_apply_received_teleport(
		entity,
		instance_id,
		destination,
		revision
	)

func _apply_received_teleport(
	entity: Entity,
	instance_id: String,
	destination: Vector2,
	revision: int
) -> void:
	var known_revision := int(
		_teleport_revisions.get(
			instance_id,
			0
		)
	)

	if revision < known_revision:
		return

	_teleport_revisions[
		instance_id
	] = revision

	entity.global_position = destination

	var controller := entity.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if controller and controller.is_locally_controlled():
		controller.clear_prediction_after_teleport()
		return

	var sprite := entity.get_node_or_null(
		"Sprite2D"
	) as Sprite2D

	if sprite:
		var rest_position := (
			_remote_sprite_rest_positions.get(
				instance_id,
				sprite.position
			) as Vector2
		)

		_remote_sprite_rest_positions[
			instance_id
		] = rest_position

		sprite.position = rest_position

	_network_positions[
		instance_id
	] = destination
