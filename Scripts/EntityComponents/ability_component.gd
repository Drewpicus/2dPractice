extends EntityComponent
class_name AbilityComponent

@export var ability_ids: Array = []

func has_ability(ability_id: StringName) -> bool:
	for id in ability_ids:
		if StringName(id) == ability_id:
			return true

	return false
