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

## Which side each combatant belongs to within this Combat.
var combat_sides: Dictionary = {}

## Number of entries in turn_order occupied by the
## currently active turn group.
var _active_group_size: int = 0

var round_number: int = 0
var _turn_index: int = -1
var started: bool = false
var initiative_scores: Dictionary = {}

signal state_changed

func add_combatant(
	entity: Entity,
	side_id: int,
	respect_disengagement: bool = false
) -> void:
	if not entity:
		return

	if side_id < 0:
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

	combat_sides[entity] = side_id

	disengaged.erase(entity)
	combatants.append(entity)

	if started:
		_roll_initiative_for(
			entity
		)

		# Late joiners act at the end of the current
		# round. Starting next round, normal initiative
		# order applies again.
		turn_order.append(
			entity
		)

		state_changed.emit()

func remove_combatant(entity: Entity) -> void:
	if not entity:
		return

	if entity not in combatants:
		return

	var removed_turn_index := turn_order.find(
		entity
	)

	var removed_from_active_group := false

	if (
		started
		and removed_turn_index >= 0
	):
		removed_from_active_group = (
			removed_turn_index >= _turn_index
			and removed_turn_index
				< _turn_index + _active_group_size
		)

	var combat_component := entity.get_component(
		&"base:combat"
	) as CombatComponent

	if combat_component:
		combat_component.current_combat = null
		combat_component.clear_combat_resources()

	combatants.erase(entity)
	combat_sides.erase(entity)
	initiative_scores.erase(entity)
	active_combatants.erase(entity)

	if removed_turn_index >= 0:
		turn_order.remove_at(
			removed_turn_index
		)

		if removed_turn_index < _turn_index:
			_turn_index -= 1
		elif removed_from_active_group:
			_active_group_size -= 1

	if entity not in disengaged:
		disengaged.append(entity)

	# Once only one side remains, the fight is over.
	if (
		started
		and _remaining_side_count() <= 1
	):
		CombatManager.end_combat(
			combat_id
		)
		return

	# If the removed Entity was the final unfinished
	# member of the current group, continue combat.
	if (
		started
		and removed_from_active_group
		and active_combatants.is_empty()
	):
		_advance_turn()
	
	if started:
		state_changed.emit()

func start() -> bool:
	if started:
		return false

	if combatants.is_empty():
		return false

	if _remaining_side_count() < 2:
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
	state_changed.emit()

	return true

func end() -> void:
	started = false

	for entity in combatants:
		if not is_instance_valid(entity):
			continue

		var combat_component := entity.get_component(
			&"base:combat"
		) as CombatComponent

		if (
			combat_component
			and combat_component.current_combat == self
		):
			combat_component.current_combat = null
			combat_component.clear_combat_resources()

	combatants.clear()
	turn_order.clear()
	active_combatants.clear()
	combat_sides.clear()
	initiative_scores.clear()

	_turn_index = -1
	_active_group_size = 0

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

	if active_combatants.is_empty():
		_advance_turn()

	state_changed.emit()

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

	active_combatants.clear()
	_active_group_size = 0

	var first_entity := turn_order[_turn_index]
	var active_side := get_combat_side(
		first_entity
	)

	var index := _turn_index

	while index < turn_order.size():
		var entity := turn_order[index]

		if get_combat_side(entity) != active_side:
			break

		active_combatants.append(entity)
		_active_group_size += 1

		var combat_component := entity.get_component(
			&"base:combat"
		) as CombatComponent

		if combat_component:
			combat_component.begin_turn()

		index += 1

func _advance_turn() -> void:
	_turn_index += _active_group_size

	if _turn_index >= turn_order.size():
		_turn_index = 0
		round_number += 1

		turn_order.sort_custom(
			_sort_by_initiative
		)

	_begin_current_turn()

func _roll_initiative() -> void:
	initiative_scores.clear()

	for entity in combatants:
		_roll_initiative_for(
			entity
		)


func _roll_initiative_for(
	entity: Entity
) -> void:
	if not entity:
		return

	var combat_component := entity.get_component(
		&"base:combat"
	) as CombatComponent

	if not combat_component:
		return

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

func get_combat_side(
	entity: Entity
) -> int:
	if not combat_sides.has(entity):
		return -1

	return int(
		combat_sides[entity]
	)

func _remaining_side_count() -> int:
	var sides: Dictionary = {}

	for entity in combatants:
		var side := get_combat_side(
			entity
		)

		if side >= 0:
			sides[side] = true

	return sides.size()

func get_opponents(
	entity: Entity
) -> Array[Entity]:
	var result: Array[Entity] = []

	var side := get_combat_side(
		entity
	)

	if side < 0:
		return result

	for combatant in combatants:
		if combatant == entity:
			continue

		if get_combat_side(combatant) == side:
			continue

		result.append(combatant)

	return result

func serialize_state() -> Dictionary:
	var combatant_ids: Array[String] = []
	var disengaged_ids: Array[String] = []
	var turn_order_ids: Array[String] = []
	var active_ids: Array[String] = []

	var serialized_sides: Dictionary = {}
	var serialized_initiative: Dictionary = {}

	for entity in combatants:
		if is_instance_valid(entity):
			combatant_ids.append(
				entity.instance_id
			)

	for entity in disengaged:
		if is_instance_valid(entity):
			disengaged_ids.append(
				entity.instance_id
			)

	for entity in turn_order:
		if is_instance_valid(entity):
			turn_order_ids.append(
				entity.instance_id
			)

	for entity in active_combatants:
		if is_instance_valid(entity):
			active_ids.append(
				entity.instance_id
			)

	for entity in combat_sides:
		if not is_instance_valid(entity):
			continue

		serialized_sides[
			entity.instance_id
		] = int(
			combat_sides[entity]
		)

	for entity in initiative_scores:
		if not is_instance_valid(entity):
			continue

		serialized_initiative[
			entity.instance_id
		] = int(
			initiative_scores[entity]
		)

	return {
		"combat_id": combat_id,
		"started": started,
		"round_number": round_number,
		"combatants": combatant_ids,
		"disengaged": disengaged_ids,
		"turn_order": turn_order_ids,
		"active_combatants": active_ids,
		"combat_sides": serialized_sides,
		"initiative_scores": serialized_initiative
	}

func deserialize_state(
	state: Dictionary
) -> void:
	# Clear old CombatComponent links before rebuilding
	# this snapshot.
	for entity in combatants:
		if not is_instance_valid(entity):
			continue

		var combat_component := entity.get_component(
			&"base:combat"
		) as CombatComponent

		if (
			combat_component
			and combat_component.current_combat == self
		):
			combat_component.current_combat = null

	combat_id = int(
		state.get(
			"combat_id",
			combat_id
		)
	)

	started = bool(
		state.get(
			"started",
			false
		)
	)

	round_number = int(
		state.get(
			"round_number",
			0
		)
	)

	combatants = _resolve_entity_ids(
		state.get(
			"combatants",
			[]
		)
	)

	disengaged = _resolve_entity_ids(
		state.get(
			"disengaged",
			[]
		)
	)

	turn_order = _resolve_entity_ids(
		state.get(
			"turn_order",
			[]
		)
	)

	active_combatants = _resolve_entity_ids(
		state.get(
			"active_combatants",
			[]
		)
	)

	combat_sides.clear()

	var side_state = state.get(
		"combat_sides",
		{}
	)

	if side_state is Dictionary:
		for instance_id in side_state:
			var entity := RuntimeObjectRegistry.get_entity(
				String(instance_id)
			)

			if not entity:
				continue

			combat_sides[entity] = int(
				side_state[instance_id]
			)

	initiative_scores.clear()

	var initiative_state = state.get(
		"initiative_scores",
		{}
	)

	if initiative_state is Dictionary:
		for instance_id in initiative_state:
			var entity := RuntimeObjectRegistry.get_entity(
				String(instance_id)
			)

			if not entity:
				continue

			initiative_scores[entity] = int(
				initiative_state[instance_id]
			)

	# Re-establish the Entity → Combat relationship
	# on this peer.
	for entity in combatants:
		var combat_component := entity.get_component(
			&"base:combat"
		) as CombatComponent

		if combat_component:
			combat_component.current_combat = self

func _resolve_entity_ids(
	values: Variant
) -> Array[Entity]:
	var result: Array[Entity] = []

	if not values is Array:
		return result

	for value in values:
		var entity := RuntimeObjectRegistry.get_entity(
			String(value)
		)

		if entity:
			result.append(
				entity
			)

	return result
