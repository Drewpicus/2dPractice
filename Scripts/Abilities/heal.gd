extends Ability
class_name HealAbility


func _init() -> void:
	ability_id = &"base:heal"
	ability_name = "Heal"
	target_requirements = [TARGET_TYPE.ENTITY]

func can_use(_use: AbilityUse) -> bool:
	return false


func perform(_use: AbilityUse) -> bool:
	return false
