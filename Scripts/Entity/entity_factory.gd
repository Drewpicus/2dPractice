extends RefCounted
class_name EntityFactory

const ENTITY_SCENE: PackedScene = preload("res://Scenes/entity.tscn")

static func build(definition: EntityDefinition) -> Entity:
	if not definition:
		return null
	
	if not GameID.is_valid(definition.entity_id):
		push_error("Invalid EntityDefinition ID: %s" % definition.entity_id)
		return null
	
	var entity := ENTITY_SCENE.instantiate() as Entity
	
	entity.entity_id = definition.entity_id
	entity.name = definition.entity_name

	var sprite := entity.get_node("Sprite3D") as Sprite3D
	sprite.texture = definition.sprite
	if definition.sprite:
		sprite.position = Vector3.ZERO
		sprite.offset.y = definition.sprite.get_height() * 0.5

	if definition.collision_shape:
		var collision := entity.get_node("CollisionShape3D") as CollisionShape3D
		collision.shape = definition.collision_shape.duplicate()
		collision.position.y = _grounded_shape_offset(collision.shape)

	entity.solid = definition.solid
	
	for component in definition.components:
		entity.add_component(component.component_id,component.parameters)
	
	return entity

static func spawn(entity: EntityDefinition, global_position: Vector3, parent: Node) -> Entity:
	var new_entity := build(entity) as Entity
	
	parent.add_child(new_entity)
	
	new_entity.global_position = global_position
	
	return new_entity

static func _grounded_shape_offset(shape: Shape3D) -> float:
	if shape is CapsuleShape3D:
		return (shape as CapsuleShape3D).height * 0.5
	if shape is CylinderShape3D:
		return (shape as CylinderShape3D).height * 0.5
	if shape is SphereShape3D:
		return (shape as SphereShape3D).radius
	if shape is BoxShape3D:
		return (shape as BoxShape3D).size.y * 0.5
	return 0.0
