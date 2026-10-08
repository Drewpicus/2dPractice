extends EntityComponent
class_name MovementComponent

@export var base_speed : float = 100
@export var waypoint_tolerance: float = 4.0

var input_direction : Vector2 = Vector2.ZERO
var input_sequence: int = -1

var _path: PackedVector2Array = []
var _path_index: int = 0


func _physics_process(_delta: float) -> void:
	if not root_entity:
		return

	if not root_entity.is_simulated_locally():
		return

	_update_path_direction()

	root_entity.velocity = (
		input_direction.normalized()
		* base_speed
	)

	if root_entity.velocity != Vector2.ZERO:
		root_entity.move_and_slide()

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
