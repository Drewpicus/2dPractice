extends RefCounted
class_name EntityFactory

const ENTITY_SCENE: PackedScene = preload("res://Scenes/entity.tscn")

static func build(entity: EntityDefinition) -> Entity:
	var new_entity := ENTITY_SCENE.instantiate() as Entity
	
	new_entity.name = entity.entity_name
	new_entity.get_node("Sprite2D").texture = entity.sprite
	if entity.collision_shape:
		new_entity.get_node("CollisionShape2D").shape = entity.collision_shape.duplicate()
	
	for component in entity.components:
		new_entity.add_component(component.component_id,component.parameters)
	
	return new_entity

static func spawn(entity: EntityDefinition, global_position: Vector2, parent: Node) -> Entity:
	var new_entity = build(entity) as Entity
	
	parent.add_child(new_entity)
	
	new_entity.global_position = global_position
	
	return new_entity
