extends EntityComponent
class_name AbilityComponent

@export var ability_ids: Array = []

var _granted_abilities: Dictionary[StringName, Array] = {}


func has_ability(
	ability_id: StringName
) -> bool:
	for id in ability_ids:
		if StringName(id) == ability_id:
			return true

	if not _granted_abilities.has(ability_id):
		return false

	return not _granted_abilities[
		ability_id
	].is_empty()


func grant_ability(
	ability_id: StringName,
	source: Variant
) -> void:
	if source == null:
		return

	if not _granted_abilities.has(ability_id):
		_granted_abilities[ability_id] = []

	var sources: Array = _granted_abilities[
		ability_id
	]

	if source not in sources:
		sources.append(source)


func revoke_ability(
	ability_id: StringName,
	source: Variant
) -> void:
	if not _granted_abilities.has(ability_id):
		return

	var sources: Array = _granted_abilities[
		ability_id
	]

	sources.erase(source)

	if sources.is_empty():
		_granted_abilities.erase(
			ability_id
		)


func get_ability(
	ability_id: StringName
) -> Ability:
	if not has_ability(ability_id):
		return null

	return AbilityRegistry.create_ability(
		ability_id
	)


func get_abilities() -> Array[Ability]:
	var result: Array[Ability] = []
	var ids: Array[StringName] = []

	for id in ability_ids:
		var ability_id := StringName(id)

		if ability_id not in ids:
			ids.append(ability_id)

	for ability_id in _granted_abilities:
		if (
			not _granted_abilities[
				ability_id
			].is_empty()
			and ability_id not in ids
		):
			ids.append(ability_id)

	for ability_id in ids:
		var ability := (
			AbilityRegistry.create_ability(
				ability_id
			)
		)

		if ability:
			result.append(ability)

	return result
