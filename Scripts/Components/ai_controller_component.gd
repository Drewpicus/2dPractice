extends EntityComponent

class_name AIControllerComponent

var movement_component : MovementComponent
var direction_timer : float = 1.0
var dir : Vector2 = Vector2.ZERO

func _ready() -> void:
	var component_folder = get_parent()
	if not component_folder:
		push_warning(self," has no Components node, Player Controller will be disabled")
		return
	
	if not movement_component:
		movement_component = component_folder.get_node_or_null("MovementComponent")
	
	dir = new_direction()
	if not movement_component:
		return
	movement_component.speed = 50


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
