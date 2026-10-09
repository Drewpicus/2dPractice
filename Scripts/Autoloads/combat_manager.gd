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
