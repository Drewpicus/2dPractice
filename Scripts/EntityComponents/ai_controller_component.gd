extends EntityComponent
class_name AIControllerComponent

var movement_component : MovementComponent
var direction_timer : float = 1.0
var dir : Vector2 = Vector2.ZERO

func _ready() -> void:
	movement_component = get_component(&"movement")
	
	dir = new_direction()
	if not movement_component:
		return
	movement_component.speed = 20

func _process(delta: float) -> void:
	if not movement_component:
		return
	direction_timer -= delta
	if direction_timer <= 0:
		dir = new_direction()
		direction_timer += 1
	
	movement_component.input_direction = dir

func new_direction() -> Vector2:
	var new_dir : Vector2
	new_dir.x = (randf()*2)-1
	new_dir.y = (randf()*2)-1
	return new_dir
