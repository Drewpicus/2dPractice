extends Node2D
class_name GameWorld

@onready var entities: Node2D = $Entities

static func find_world(node: Node) -> GameWorld:
	while node != null:
		if node is GameWorld:
			return node

		node = node.get_parent()

	return null

func spawn_entity(entity_id: StringName, entity_position: Vector2) -> Entity:
	var definition := DefinitionRegistry.get_entity(entity_id)

	if not definition:
		push_error("No EntityDefinition registered for: %s" % entity_id)
		return null

	return EntityFactory.spawn(definition, entity_position, entities)

func remove_entity(entity: Entity) -> void:
	if not entity:
		return

	entity.queue_free()
