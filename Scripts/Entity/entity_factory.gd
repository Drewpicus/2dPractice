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
	entity.get_node("Sprite2D").texture = definition.sprite
	if definition.collision_shape:
		entity.get_node("CollisionShape2D").shape = definition.collision_shape.duplicate()
	entity.solid = definition.solid
	
	for component in definition.components:
		entity.add_component(component.component_id,component.parameters)
	
	return entity

static func spawn(entity: EntityDefinition, global_position: Vector2, parent: Node) -> Entity:
	var new_entity = build(entity) as Entity
	
	parent.add_child(new_entity)
	
	new_entity.global_position = global_position
	
	return new_entity
