extends EntityComponent
class_name CombatComponent

@export var movement_per_turn: float = 160.0

var current_combat: Combat

var movement_remaining: float = 0.0
var action_available: bool = false
var reaction_available: bool = false


func add_to_combat(
	combat: Combat,
	respect_disengagement: bool = false
) -> void:
	if not combat:
		return

	if current_combat:
		return

	combat.add_combatant(
		root_entity,
		respect_disengagement
	)


func remove_from_combat() -> void:
	if not current_combat:
		return

	current_combat.remove_combatant(
		root_entity
	)


func begin_turn() -> void:
	movement_remaining = movement_per_turn
	action_available = true
	reaction_available = true


func end_turn() -> void:
	movement_remaining = 0.0
	action_available = false


func can_spend_movement(
	amount: float
) -> bool:
	if amount < 0.0:
		return false

	return amount <= movement_remaining


func spend_movement(
	amount: float
) -> bool:
	if not can_spend_movement(amount):
		return false

	movement_remaining -= amount
	return true
