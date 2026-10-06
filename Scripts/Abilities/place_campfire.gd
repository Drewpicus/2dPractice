extends Ability
class_name PlaceCampfireAbility


func _init() -> void:
	ability_id = &"base:place_campfire"
	ability_name = "Place Campfire"
	target_requirements = [TARGET_TYPE.POSITION]

func can_use(_use: AbilityUse) -> bool:
	return false


func perform(_use: AbilityUse) -> bool:
	return false
