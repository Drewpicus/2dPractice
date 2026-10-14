extends EntityComponent
class_name MovementComponent

@export var base_speed : float = 100
@export var waypoint_tolerance: float = 1.0

var input_direction : Vector2 = Vector2.ZERO
var input_sequence: int = -1

var _path: PackedVector2Array = []
var _path_index: int = 0


func _physics_process(delta: float) -> void:
	if not root_entity:
		return

	if not root_entity.is_simulated_locally():
		return

	_update_path_direction()

	var combat := get_component(
		&"base:combat"
	) as CombatComponent

	var in_combat := (
		combat
		and combat.current_combat
		and combat.current_combat.started
	)

	if in_combat:
		if not combat.current_combat.is_active(
			root_entity
		):
			cancel_path()
			root_entity.velocity = Vector2.ZERO
			_record_simulated_input()
			return

		if combat.movement_remaining <= 0.0:
			cancel_path()
			root_entity.velocity = Vector2.ZERO
			_record_simulated_input()
			return

	var movement_speed := base_speed

	# Don't allow this physics step to attempt more
	# movement than remains in the combat budget.
	if (
		in_combat
		and delta > 0.0
	):
		movement_speed = min(
			movement_speed,
			combat.movement_remaining / delta
		)

	root_entity.velocity = (
		input_direction.normalized()
		* movement_speed
	)

	var position_before := (
		root_entity.global_position
	)

	if root_entity.velocity != Vector2.ZERO:
		root_entity.move_and_slide()

	var distance_moved := (
		position_before.distance_to(
			root_entity.global_position
		)
	)

	if (
		in_combat
		and distance_moved > 0.0
	):
		combat.spend_movement(
			distance_moved
		)

		if combat.movement_remaining <= 0.0:
			cancel_path()
			root_entity.velocity = Vector2.ZERO

	_record_simulated_input()

func _record_simulated_input() -> void:
	if input_sequence < 0:
		return

	if not MultiplayerManager.session_active:
		return

	var controller := get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return

	var world := GameWorld.find_world(root_entity)

	if not world:
		return

	if MultiplayerManager.is_world_authority():
		world.record_simulated_movement(
			root_entity,
			input_sequence
		)
		return

	if controller.is_locally_controlled():
		controller.record_predicted_position(
			input_sequence
		)

func follow_path(
	path: PackedVector2Array
) -> bool:
	if path.is_empty():
		return false

	_path = path
	_path_index = 0

	return true


func cancel_path() -> void:
	_path.clear()
	_path_index = 0
	input_direction = Vector2.ZERO


func has_path() -> bool:
	return not _path.is_empty()

func _update_path_direction() -> void:
	if _path.is_empty():
		return

	if _path_index >= _path.size():
		cancel_path()
		return

	var target := _path[_path_index]

	if (
		root_entity.global_position.distance_to(target)
		<= waypoint_tolerance
	):
		_path_index += 1

		if _path_index >= _path.size():
			cancel_path()
			return

		target = _path[_path_index]

	input_direction = (
		target - root_entity.global_position
	).normalized()
