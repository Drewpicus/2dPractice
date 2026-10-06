extends EntityComponent
class_name AbilityComponent

@export var ability_ids: Array = []


func has_ability(ability_id: StringName) -> bool:
	for id in ability_ids:
		if StringName(id) == ability_id:
			return true

	return false


func get_ability(ability_id: StringName) -> Ability:
	if not has_ability(ability_id):
		return null

	return AbilityRegistry.create_ability(ability_id)


func get_abilities() -> Array[Ability]:
	var result: Array[Ability] = []

	for id in ability_ids:
		var ability := AbilityRegistry.create_ability(
			StringName(id)
		)

		if ability:
			result.append(ability)

	return result
