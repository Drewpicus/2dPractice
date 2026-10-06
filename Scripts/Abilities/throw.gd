extends Ability
class_name ThrowAbility


func _init() -> void:
	ability_id = &"base:throw"
	ability_name = "Throw"
	target_requirements = [TARGET_TYPE.ITEM, TARGET_TYPE.POSITION]


func can_use(_use: AbilityUse) -> bool:
	return false


func perform(_use: AbilityUse) -> bool:
	return false
