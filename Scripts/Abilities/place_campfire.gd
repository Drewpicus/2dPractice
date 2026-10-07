extends Ability
class_name PlaceCampfireAbility


func _init() -> void:
	ability_id = &"base:place_campfire"
	ability_name = "Place Campfire"
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

	var equipment := use.user.get_component(
		&"base:equipment"
	) as EquipmentComponent

	if not equipment:
		return false

	if not equipment.has_equipped_item(
		&"base:stick"
	):
		return false

	var world := GameWorld.find_world(
		use.user
	)

	if not world:
		return false

	return true


func perform(use: AbilityUse) -> bool:
	if not can_use(use):
		return false

	var world := GameWorld.find_world(
		use.user
	)

	if not world:
		return false

	var campfire := world.spawn_entity(
		&"base:campfire",
		use.target_position
	)

	return campfire != null
