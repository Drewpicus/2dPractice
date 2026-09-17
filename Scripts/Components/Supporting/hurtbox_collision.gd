extends CollisionShape2D

func _ready() -> void:
	if not shape:
		var entity : Entity = get_parent().get_parent().get_parent()
		if not entity:
			return
		var root_physics_collider : CollisionShape2D
		root_physics_collider = entity.get_node("CollisionShape2D")
		if root_physics_collider and root_physics_collider.shape:
			shape = root_physics_collider.shape
		else:
			print("Hurtbox collider shape auto-assignment failed for ",self)
