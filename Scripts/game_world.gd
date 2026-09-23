extends Node2D
class_name GameWorld

@onready var entities: Node2D = $Entities

func spawn_entity(entity_id: StringName, position: Vector2) -> Entity:
	var definition := DefinitionRegistry.get_entity(entity_id)

	if not definition:
		push_error("No EntityDefinition registered for: %s" % entity_id)
		return null

	return EntityFactory.spawn(definition, position, entities)

func remove_entity(entity: Entity) -> void:
	if not entity:
		return

	entity.queue_free()
