##An ability a player can execute at will, with limitations of course.

extends RefCounted
class_name Ability

enum TARGET_TYPE {
	POSITION,
	ENTITY,
	ITEM
}

enum COMBAT_COST {
	NONE,
	ACTION,
	REACTION
}

var ability_id: StringName
var ability_name: String

var target_requirements: Array = []

## What this Ability costs when used during combat.
## Outside combat this has no effect.
var combat_cost: COMBAT_COST = COMBAT_COST.ACTION

##True if the [AbilityUse] can be used
func can_use(_use: AbilityUse) -> bool:
	return false

##Attempts to perform the [AbilityUse]
##True if the [Ability] was performed successfully
func perform(_use: AbilityUse) -> bool:
	return false

func can_pay_combat_cost(
	user: Entity
) -> bool:
	if not user:
		return false

	var combat := user.get_component(
		&"base:combat"
	) as CombatComponent

	# No active combat means combat costs don't matter.
	if (
		not combat
		or not combat.current_combat
		or not combat.current_combat.started
	):
		return true

	match combat_cost:
		COMBAT_COST.NONE:
			return true

		COMBAT_COST.ACTION:
			if not combat.current_combat.is_active(
				user
			):
				return false

			return combat.can_spend_action()

		COMBAT_COST.REACTION:
			return combat.can_spend_reaction()

	return false


func spend_combat_cost(
	user: Entity
) -> bool:
	if not user:
		return false

	var combat := user.get_component(
		&"base:combat"
	) as CombatComponent

	if (
		not combat
		or not combat.current_combat
		or not combat.current_combat.started
	):
		return true

	match combat_cost:
		COMBAT_COST.NONE:
			return true

		COMBAT_COST.ACTION:
			return combat.spend_action()

		COMBAT_COST.REACTION:
			return combat.spend_reaction()

	return false
