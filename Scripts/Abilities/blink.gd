extends Ability
class_name BlinkAbility

#var blink_range: float = 96.0


func _init() -> void:
	ability_id = &"base:blink"
	ability_name = "Blink"
	target_requirements = [
		TARGET_TYPE.POSITION
	]


func can_use(use: AbilityUse) -> bool:
	if not use:
		return false

	if not use.user:
		return false

	if not use.has_target_position:
		return false

	#if (use.user.global_position.distance_to(use.target_position) > blink_range):
	#	return false

	return true


func perform(use: AbilityUse) -> bool:
	if not can_use(use):
		return false

	use.user.global_position = use.target_position

	return true
