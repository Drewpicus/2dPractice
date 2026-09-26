extends Sprite3D

@export_range(0.05, 1.0) var minimum_vertical_factor: float = 0.25

var _base_scale_y: float


func _ready() -> void:
	_base_scale_y = scale.y


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()

	if not camera:
		scale.y = _base_scale_y
		return

	var camera_forward := -camera.global_basis.z.normalized()

	var vertical_projection_factor := Vector2(
		camera_forward.x,
		camera_forward.z
	).length()

	vertical_projection_factor = max(
		vertical_projection_factor,
		minimum_vertical_factor
	)

	scale.y = _base_scale_y / vertical_projection_factor
