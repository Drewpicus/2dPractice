extends RefCounted
class_name Combat

var combat_id: int

## Entities currently participating in combat.
var combatants: Array[Entity] = []

## Entities that left this combat and should not
## automatically be added again.
var disengaged: Array[Entity] = []

## Current initiative order.
## Combatants sorted in descending initiative order.
var turn_order: Array[Entity] = []

## Array rather than a single Entity because later
## similar initiatives may act concurrently.
var active_combatants: Array[Entity] = []

var round_number: int = 0
var _turn_index: int = -1
var started: bool = false
var initiative_scores: Dictionary = {}

func add_combatant(
	entity: Entity,
	respect_disengagement: bool = false
) -> void:
	if not entity:
		return

	if entity in combatants:
		return

	var combat_component := entity.get_component(
		&"base:combat"
	) as CombatComponent

	if not combat_component:
		return

	if combat_component.current_combat:
		return

	if (
		respect_disengagement
		and entity in disengaged
	):
		return

	combat_component.current_combat = self

	disengaged.erase(entity)
	combatants.append(entity)


func remove_combatant(entity: Entity) -> void:
	if not entity:
		return

	if entity not in combatants:
		return

	var combat_component := entity.get_component(
		&"base:combat"
	) as CombatComponent

	if combat_component:
		combat_component.current_combat = null
		combat_component.end_turn()

	combatants.erase(entity)
	turn_order.erase(entity)
	active_combatants.erase(entity)

	if entity not in disengaged:
		disengaged.append(entity)


func start() -> bool:
	if started:
		return false

	if combatants.is_empty():
		return false

	_roll_initiative()

	turn_order = combatants.duplicate()
	turn_order.sort_custom(
		_sort_by_initiative
	)

	started = true
	round_number = 1
	_turn_index = 0

	_begin_current_turn()

	return true


func end_turn(entity: Entity) -> bool:
	if not started:
		return false

	if entity not in active_combatants:
		return false

	var movement := entity.get_component(
		&"base:movement"
	) as MovementComponent

	if movement:
		movement.cancel_path()

	var combat_component := entity.get_component(
		&"base:combat"
	) as CombatComponent

	if combat_component:
		combat_component.end_turn()

	active_combatants.erase(entity)

	# Later, when multiple combatants can share a turn,
	# we wait until all members of the active group finish.
	if not active_combatants.is_empty():
		return true

	_advance_turn()

	return true


func is_active(entity: Entity) -> bool:
	return entity in active_combatants


func _begin_current_turn() -> void:
	if turn_order.is_empty():
		return

	if (
		_turn_index < 0
		or _turn_index >= turn_order.size()
	):
		return

	var entity := turn_order[_turn_index]

	active_combatants.clear()
	active_combatants.append(entity)

	var combat_component := entity.get_component(
		&"base:combat"
	) as CombatComponent

	if combat_component:
		combat_component.begin_turn()


func _advance_turn() -> void:
	_turn_index += 1

	if _turn_index >= turn_order.size():
		_turn_index = 0
		round_number += 1

	_begin_current_turn()

func _roll_initiative() -> void:
	initiative_scores.clear()

	for entity in combatants:
		var combat_component := entity.get_component(
			&"base:combat"
		) as CombatComponent

		if not combat_component:
			continue

		var roll := randi_range(
			1,
			4
		)

		var score := (
			roll
			+ combat_component.initiative_bonus
		)

		initiative_scores[entity] = score

		print(
			entity.entity_name,
			" initiative: ",
			score,
			" (",
			roll,
			" + ",
			combat_component.initiative_bonus,
			")"
		)


func _sort_by_initiative(
	a: Entity,
	b: Entity
) -> bool:
	return int(
		initiative_scores.get(a, 0)
	) > int(
		initiative_scores.get(b, 0)
	)
