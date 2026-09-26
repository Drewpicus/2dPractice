extends Camera3D

@export var max_size: float = 24.0
@export var min_size: float = 4.0
@export var step_amount: float = 1.0

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("zoom_in"):
		size = clampf(size - step_amount, min_size, max_size)
	if Input.is_action_just_pressed("zoom_out"):
		size = clampf(size + step_amount, min_size, max_size)
