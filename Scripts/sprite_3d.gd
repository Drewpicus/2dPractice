extends Sprite3D

## Prevents extreme stretching as the camera approaches straight-down.
@export_range(0.05, 1.0) var minimum_vertical_factor: float = 0.25

var _base_scale: Vector3


func _ready() -> void:
	_base_scale = scale


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()

	if not camera:
		scale = _base_scale
		return

	var camera_forward := -camera.global_basis.z.normalized()

	# Horizontal length of the camera's forward vector.
	# 1.0 = camera is horizontal.
	# 0.0 = camera is looking straight down/up.
	var vertical_projection_factor := Vector2(
		camera_forward.x,
		camera_forward.z
	).length()

	vertical_projection_factor = max(
		vertical_projection_factor,
		minimum_vertical_factor
	)

	scale = Vector3(
		_base_scale.x,
		_base_scale.y / vertical_projection_factor,
		_base_scale.z
	)
