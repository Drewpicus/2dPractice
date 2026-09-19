extends Camera2D

@export var max_zoom: float = 3.0
@export var min_zoom: float = 0.6

@export var step_amount: float = 0.2

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("zoom_in"):
		zoom += Vector2(step_amount,step_amount)
		zoom = Vector2(clampf(zoom.x,min_zoom,max_zoom),clampf(zoom.y,min_zoom,max_zoom))
	if Input.is_action_just_pressed("zoom_out"):
		zoom -= Vector2(step_amount,step_amount)
		zoom = Vector2(clampf(zoom.x,min_zoom,max_zoom),clampf(zoom.y,min_zoom,max_zoom))
