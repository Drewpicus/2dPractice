extends Node

var combats : Array[Combat]

func new_combat() -> Combat:
	var combat := Combat.new()
	combat.combat_id = _unique_combat_id()
	combats.append(combat)
	print(_get_combats())
	return combat

func end_combat(id:int) -> void:
	var combat_to_end: Combat = _get_combat_by_id(id)
	if combat_to_end == null:
		return
	combats.erase(combat_to_end)

func _get_combats() -> Array[Combat]:
	return combats

func _unique_combat_id() -> int:
	if combats.is_empty():
		print("Unique combat ID is: 1")
		return 1
	var ids_in_use: Array = []
	for combat in combats:
		ids_in_use.append(combat.combat_id)

	var new_id: int = 1
	while new_id in ids_in_use:
		new_id += 1

	print("Unique combat ID is: ",new_id)
	return new_id

func _get_combat_by_id(id:int) -> Combat:
	for combat in combats:
		if combat.combat_id == id:
			return combat
	return null
