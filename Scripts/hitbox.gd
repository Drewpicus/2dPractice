extends Area2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@export var damage : float = -1.0

func _ready() -> void:
	monitorable = false
	monitoring = false

func activate_for_one_frame() -> void:
	monitoring = true
	await get_tree().physics_frame
	await get_tree().physics_frame

	var hurtboxes := get_overlapping_areas()
	for hurtbox in hurtboxes:
		if hurtbox.has_method("register_hit"):
			hurtbox.register_hit(self)
		print(hurtbox)
	monitoring = false
