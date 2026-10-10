extends EntityComponent
class_name PerceptionComponent


@export var perception_range: float = 150.0


func can_perceive(
	entity: Entity
) -> bool:
	if not root_entity or not entity:
		return false

	if entity == root_entity:
		return false

	if not is_instance_valid(entity):
		return false

	return (
		root_entity.global_position.distance_squared_to(
			entity.global_position
		)
		<= perception_range * perception_range
	)


func get_perceived_entities() -> Array[Entity]:
	var result: Array[Entity] = []

	if not root_entity:
		return result

	var world := GameWorld.find_world(
		root_entity
	)

	if not world:
		return result

	for entity in world.get_entities():
		if can_perceive(
			entity
		):
			result.append(
				entity
			)

	return result
