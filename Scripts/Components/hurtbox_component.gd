extends EntityComponent
class_name HurtboxComponent

@export var health_component : HealthComponent
@onready var collision : CollisionShape2D = $HurtboxCollision

func _ready() -> void:
	if not health_component:
		health_component = get_component(&"health")
	if root_entity:
		root_entity.apply_entity_collision_to(collision)

func register_hit(other_area:Area2D) -> void:
	if other_area.damage and health_component:
		health_component.change_health(other_area.damage)
		print("hit registered")
