extends EntityComponent
class_name MovementComponent

@export var base_speed : float = 200

var input_direction : Vector2 = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	root_entity.velocity = input_direction.normalized() * base_speed
	root_entity.move_and_slide()
