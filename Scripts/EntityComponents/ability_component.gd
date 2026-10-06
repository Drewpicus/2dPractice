extends EntityComponent
class_name AbilityComponent

@export var abilities: Array = []

func has_ability(ability_id: StringName) -> bool:
	return ability_id in abilities
