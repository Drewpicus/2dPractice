##Contains a reference to the type of remains left behind by this Entity when
##they die, be it a corpse or a puddle of goo. Remains inherit inventory.

extends EntityComponent
class_name RemainsComponent

@export var remains: EntityDefinition

func spawn_remains() -> Entity:
	var remains_entity: Entity
	if remains:
		remains_entity = EntityFactory.spawn(remains,root_entity.global_position,get_tree().root.get_node("Main/GameWorld/Entities"))
	return remains_entity
