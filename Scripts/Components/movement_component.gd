extends EntityComponent
class_name MovementComponent

@export var speed : float = 200

var input_direction : Vector2 = Vector2.ZERO

func _ready() -> void:
	var component_folder = get_parent()
	if not component_folder:
		push_warning(self," has no Components node, ",self.name," will be disabled")
		return
	
	if not root_entity:
		push_warning(self," has no Root Entity, ",self.name," will be disabled")

func _physics_process(_delta: float) -> void:
	if not root_entity:
		return
	
	root_entity.velocity = input_direction.normalized() * speed
	root_entity.move_and_slide()
