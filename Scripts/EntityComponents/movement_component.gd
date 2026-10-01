extends EntityComponent
class_name MovementComponent

@export var base_speed : float = 100

var input_direction : Vector2 = Vector2.ZERO
var input_sequence: int = -1

func _physics_process(_delta: float) -> void:
	if not root_entity:
		return

	if not root_entity.is_simulated_locally():
		return

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
