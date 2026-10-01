extends EntityComponent
class_name MovementComponent

@export var base_speed : float = 200

var input_direction : Vector2 = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	if not root_entity:
		return

	if MultiplayerManager.session_active:
		if not MultiplayerManager.is_world_authority():
			var controller := get_component(
				&"base:player_controller"
			) as PlayerControllerComponent

			if not controller:
				return

			if not controller.is_locally_controlled():
				return

	root_entity.velocity = (input_direction.normalized() * base_speed)
	if root_entity.velocity != Vector2.ZERO:
		root_entity.move_and_slide()
