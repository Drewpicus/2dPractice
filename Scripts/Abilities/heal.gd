extends Ability
class_name HealAbility

var heal_amount: int = 3


func _init() -> void:
	ability_id = &"base:heal"
	ability_name = "Heal"
	target_requirements = [
		TARGET_TYPE.ENTITY
	]


func can_use(use: AbilityUse) -> bool:
	if not use:
		return false

	if not use.user:
		return false

	if not use.target_entity:
		return false

	var health := use.target_entity.get_component(
		&"base:health"
	) as HealthComponent

	if not health:
		return false

	if not health.is_alive():
		return false

	if health.is_full_health():
		return false

	return true


func perform(use: AbilityUse) -> bool:
	if not can_use(use):
		return false

	var resolution := HealSystem.apply_healing(
		use.user,
		use.target_entity,
		heal_amount
	)

	return (
		resolution != null
		and not resolution.cancelled
	)
