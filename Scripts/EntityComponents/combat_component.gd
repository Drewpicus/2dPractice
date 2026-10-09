extends EntityComponent
class_name CombatComponent

@export var movement_per_turn: float = 160.0
@export var initiative_bonus: int = 0

var current_combat: Combat

var movement_remaining: float = 0.0
var action_available: bool = false
var reaction_available: bool = false


func add_to_combat(
	combat: Combat,
	side_id: int,
	respect_disengagement: bool = false
) -> void:
	if not combat:
		return

	if current_combat:
		return

	combat.add_combatant(
		root_entity,
		side_id,
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

	notify_state_changed()


func end_turn() -> void:
	movement_remaining = 0.0
	action_available = false

	notify_state_changed()


func can_spend_movement(
	amount: float
) -> bool:
	if amount < 0.0:
		return false

	return (
		amount <= movement_remaining
		or is_equal_approx(
			amount,
			movement_remaining
		)
	)


func spend_movement(
	amount: float
) -> bool:
	if not can_spend_movement(
		amount
	):
		return false

	# If this is effectively the rest of the
	# movement budget, consume it completely rather
	# than preserving floating-point residue.
	if is_equal_approx(
		amount,
		movement_remaining
	):
		movement_remaining = 0.0
	else:
		movement_remaining -= amount

	notify_state_changed()

	return true


func can_spend_action() -> bool:
	return action_available


func spend_action() -> bool:
	if not can_spend_action():
		return false

	action_available = false

	notify_state_changed()

	return true

func on_event(event: GameEvent) -> void:
	if not event is DeathAppliedEvent:
		return

	var death_event := event as DeathAppliedEvent

	# Death events also get sent to the source,
	# so only react when this Entity is the one
	# that actually died.
	if death_event.target != root_entity:
		return

	if current_combat:
		current_combat.remove_combatant(
			root_entity
		)

func clear_combat_resources() -> void:
	movement_remaining = 0.0
	action_available = false
	reaction_available = false

	notify_state_changed()

func can_spend_reaction() -> bool:
	return reaction_available


func spend_reaction() -> bool:
	if not can_spend_reaction():
		return false

	reaction_available = false

	notify_state_changed()

	return true

func serialize_state() -> Dictionary:
	return {
		"movement_remaining":
			movement_remaining,
		"action_available":
			action_available,
		"reaction_available":
			reaction_available
	}


func deserialize_state(
	state: Dictionary
) -> void:
	movement_remaining = float(
		state.get(
			"movement_remaining",
			movement_remaining
		)
	)

	action_available = bool(
		state.get(
			"action_available",
			action_available
		)
	)

	reaction_available = bool(
		state.get(
			"reaction_available",
			reaction_available
		)
	)
