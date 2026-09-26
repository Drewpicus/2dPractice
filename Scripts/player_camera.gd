extends Camera3D

@export var max_size: float = 30.0
@export var min_size: float = 4.0
@export var step_amount: float = 4.0
@export var pivot_step_amount: float = 0.05
var acceleration := 0.5

var pivot: Node3D

func _ready() -> void:
	pivot = get_parent()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("zoom_in"):
		position.z = lerpf(position.z,clampf(position.z - step_amount, min_size, max_size),acceleration) 
	if Input.is_action_just_pressed("zoom_out"):
		position.z = lerpf(position.z,clampf(position.z + step_amount, min_size, max_size),acceleration) 
	
	if pivot:
		print(pivot.rotation.x)
		if Input.is_action_pressed("tilt_up"):
			pivot.rotation.x = lerpf(pivot.rotation.x,clampf(pivot.rotation.x - pivot_step_amount, deg_to_rad(-80), deg_to_rad(-10)),acceleration)
		if Input.is_action_pressed("tilt_down"):
			pivot.rotation.x = lerpf(pivot.rotation.x,clampf(pivot.rotation.x + pivot_step_amount, deg_to_rad(-80), deg_to_rad(-10)),acceleration)
