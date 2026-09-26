extends EntityComponent
class_name MovementComponent

@export var speed: float = 6.0

var input_direction: Vector2 = Vector2.ZERO

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

	var direction := input_direction.normalized()

	root_entity.velocity = Vector3(
		direction.x * speed,
		0.0,
		direction.y * speed
	)

	root_entity.move_and_slide()
	root_entity.velocity.y = 0.0
	root_entity.global_position.y = 0.0
