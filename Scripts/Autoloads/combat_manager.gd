extends Node


var combats: Array[Combat] = []


func new_combat() -> Combat:
	if (
		MultiplayerManager.session_active
		and not MultiplayerManager.is_world_authority()
	):
		return null

	var combat := Combat.new()

	combat.combat_id = _unique_combat_id()

	_register_combat(
		combat
	)

	return combat


func end_combat(
	id: int
) -> void:
	if (
		MultiplayerManager.session_active
		and not MultiplayerManager.is_world_authority()
	):
		return

	var combat := get_combat_by_id(
		id
	)

	if not combat:
		return

	combat.end()

	_unregister_combat(
		combat
	)

	if MultiplayerManager.session_active:
		_receive_combat_ended.rpc(
			id
		)


func get_combats() -> Array[Combat]:
	return combats


func get_combat_by_id(
	id: int
) -> Combat:
	for combat in combats:
		if combat.combat_id == id:
			return combat

	return null


func _register_combat(
	combat: Combat
) -> void:
	if not combat:
		return

	if combat in combats:
		return

	combats.append(
		combat
	)

	var callback := (
		_on_combat_state_changed.bind(
			combat
		)
	)

	if not combat.state_changed.is_connected(
		callback
	):
		combat.state_changed.connect(
			callback
		)


func _unregister_combat(
	combat: Combat
) -> void:
	if not combat:
		return

	var callback := (
		_on_combat_state_changed.bind(
			combat
		)
	)

	if combat.state_changed.is_connected(
		callback
	):
		combat.state_changed.disconnect(
			callback
		)

	combats.erase(
		combat
	)


func _on_combat_state_changed(
	combat: Combat
) -> void:
	if not combat:
		return

	if not MultiplayerManager.session_active:
		return

	if not MultiplayerManager.is_world_authority():
		return

	_receive_combat_state.rpc(
		combat.serialize_state()
	)


@rpc(
	"authority",
	"call_remote",
	"reliable"
)
func _receive_combat_state(
	state: Dictionary
) -> void:
	if MultiplayerManager.is_world_authority():
		return

	var combat_id := int(
		state.get(
			"combat_id",
			-1
		)
	)

	if combat_id < 0:
		return

	var combat := get_combat_by_id(
		combat_id
	)

	if not combat:
		combat = Combat.new()
		combat.combat_id = combat_id

		_register_combat(
			combat
		)

	combat.deserialize_state(
		state
	)

@rpc(
	"authority",
	"call_remote",
	"reliable"
)
func _receive_combat_ended(
	combat_id: int
) -> void:
	if MultiplayerManager.is_world_authority():
		return

	var combat := get_combat_by_id(
		combat_id
	)

	if not combat:
		return

	combat.end()

	_unregister_combat(
		combat
	)


func _unique_combat_id() -> int:
	var ids_in_use: Array[int] = []

	for combat in combats:
		ids_in_use.append(
			combat.combat_id
		)

	var new_id := 1

	while new_id in ids_in_use:
		new_id += 1

	return new_id

func clear_all_combats() -> void:
	var current_combats := combats.duplicate()

	for combat in current_combats:
		if combat:
			combat.end()

		_unregister_combat(
			combat
		)

	combats.clear()

func engage_hostile(
	actor: Entity,
	target: Entity
) -> bool:
	if not actor or not target:
		return false

	if actor == target:
		return false

	if (
		MultiplayerManager.session_active
		and not MultiplayerManager.is_world_authority()
	):
		return false

	var actor_component := actor.get_component(
		&"base:combat"
	) as CombatComponent

	var target_component := target.get_component(
		&"base:combat"
	) as CombatComponent

	# Some destructible things can be attacked without
	# actually participating in turn-based combat.
	if not actor_component or not target_component:
		return true

	var actor_combat := actor_component.current_combat
	var target_combat := target_component.current_combat

	# Already participating in the same fight.
	if actor_combat and target_combat:
		return actor_combat == target_combat

	# Actor is already fighting. The new hostile Entity
	# joins as another opposing side.
	if actor_combat:
		var new_side := _next_side_id(
			actor_combat
		)

		actor_combat.add_combatant(
			target,
			new_side
		)

		return (
			target_component.current_combat
			== actor_combat
		)

	# Same situation in reverse.
	if target_combat:
		var new_side := _next_side_id(
			target_combat
		)

		target_combat.add_combatant(
			actor,
			new_side
		)

		return (
			actor_component.current_combat
			== target_combat
		)

	# Neither is fighting yet: create a new two-sided
	# combat.
	var combat := new_combat()

	if not combat:
		return false

	combat.add_combatant(
		actor,
		0
	)

	combat.add_combatant(
		target,
		1
	)

	if (
		actor_component.current_combat != combat
		or target_component.current_combat != combat
	):
		combat.end()
		_unregister_combat(combat)
		return false

	if not combat.start():
		combat.end()
		_unregister_combat(combat)
		return false

	return true


func _next_side_id(
	combat: Combat
) -> int:
	var side_id := 0
	var used_sides := combat.combat_sides.values()

	while side_id in used_sides:
		side_id += 1

	return side_id
