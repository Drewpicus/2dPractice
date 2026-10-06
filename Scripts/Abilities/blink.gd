extends Ability
class_name BlinkAbility


func _init() -> void:
	ability_id = &"base:blink"
	ability_name = "Blink"
	target_requirements = [TARGET_TYPE.POSITION]

func can_use(_use: AbilityUse) -> bool:
	return false


func perform(_use: AbilityUse) -> bool:
	return false
