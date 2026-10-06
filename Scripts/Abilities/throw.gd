extends Ability
class_name ThrowAbility


func _init() -> void:
	ability_id = &"base:throw"
	ability_name = "Throw"
	target_requirements = [
		TARGET_TYPE.ITEM,
		TARGET_TYPE.POSITION
	]


func can_use(use: AbilityUse) -> bool:
	if not use:
		return false

	if not use.user:
		return false

	if not use.item:
		return false

	if not use.has_target_position:
		return false

	var inventory := use.user.get_component(
		&"base:inventory"
	) as InventoryComponent

	if not inventory:
		return false

	if use.item not in inventory.items:
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

	var inventory := use.user.get_component(
		&"base:inventory"
	) as InventoryComponent

	if not inventory:
		return false

	var removed_item := inventory.remove_item(
		use.item
	)

	if not removed_item:
		return false

	var world := GameWorld.find_world(
		use.user
	)

	if not world:
		inventory.add_item(removed_item)
		return false

	var dropped_item := world.spawn_dropped_item(
		removed_item,
		use.target_position
	)

	if not dropped_item:
		inventory.add_item(removed_item)
		return false

	return true
