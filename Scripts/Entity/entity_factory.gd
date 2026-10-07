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
	
	if definition.sprite:
		sprite.position.y = float(-definition.sprite.get_height()) / 2
	
	if definition.collision_shape:
		entity.get_node("CollisionShape2D").shape = definition.collision_shape.duplicate()
	
	entity.solid = definition.solid
	
	entity.z_index = definition.draw_layer
	
	for component_definition in definition.components:
		var component := entity.add_component(
			component_definition.component_id,
			component_definition.parameters
		)

		if not component:
			push_error(
				"Failed to build Entity %s because component %s could not be added."
				% [
					definition.entity_id,
					component_definition.component_id
				]
			)

			_cleanup_failed_entity(entity)
			return null

	return entity

static func spawn(entity: EntityDefinition, global_position: Vector2, parent: Node) -> Entity:
	var new_entity = build(entity) as Entity
	
	parent.add_child(new_entity)
	
	new_entity.global_position = global_position
	
	return new_entity

static func _cleanup_failed_entity(
	entity: Entity
) -> void:
	if not entity:
		return

	for component in entity.get_components():
		entity.remove_component(
			component.component_id
		)

	RuntimeObjectRegistry.unregister(
		entity.instance_id,
		entity
	)

	entity.free()
