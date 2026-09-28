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
	entity.entity_name = definition.entity_name
	var sprite := entity.get_node("Sprite2D") as Sprite2D
	sprite.texture = definition.sprite
	
	var y_offset := 0.0
	
	if definition.sprite:
		y_offset = -definition.sprite.get_height() / 2
		sprite.position.y = y_offset
	
	var collision := entity.get_node("CollisionShape2D") as CollisionShape2D
	
	if definition.collision_shape:
		collision.shape = definition.collision_shape.duplicate()
		collision.position.y = y_offset
		
	entity.solid = definition.solid
	
	for component in definition.components:
		entity.add_component(component.component_id,component.parameters)
	
	return entity

static func spawn(entity: EntityDefinition, global_position: Vector2, parent: Node) -> Entity:
	var new_entity = build(entity) as Entity
	
	parent.add_child(new_entity)
	
	new_entity.global_position = global_position
	
	return new_entity
