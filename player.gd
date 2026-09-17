extends CharacterBody2D

@export var speed: float = 200.0
@export var network_position: Vector2
@export var smoothing_speed: float = 15.0

func _ready() -> void:
	network_position = position

@rpc
func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		var direction := Input.get_vector(
			"ui_left",
			"ui_right",
			"ui_up",
			"ui_down"
		)

		velocity = direction * speed
		move_and_slide()

		network_position = position

	else:
		position = position.lerp(
			network_position,
			1.0 - exp(-smoothing_speed * delta)
		)
