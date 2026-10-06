extends RefCounted
class_name AbilityRegistry

const ABILITIES: Dictionary = {
	&"base:blink":preload("res://Scripts/Abilities/blink.gd"),
	&"base:place_campfire":preload("res://Scripts/Abilities/place_campfire.gd"),
	&"base:heal": preload("res://Scripts/Abilities/heal.gd"),
	&"base:throw": preload("res://Scripts/Abilities/throw.gd"),
	}


static func create_ability(
	ability_id: StringName
) -> Ability:
	if not GameID.is_valid(ability_id):
		push_error(
			"Invalid Ability ID: %s"
			% ability_id
		)
		return null

	var ability_script: Script = ABILITIES.get(
		ability_id
	)

	if not ability_script:
		push_error(
			"Unregistered Ability ID: %s"
			% ability_id
		)
		return null

	var ability := ability_script.new() as Ability

	if not ability:
		push_error(
			"Registered script does not create an Ability: %s"
			% ability_id
		)
		return null

	if ability.ability_id != ability_id:
		push_error(
			"Ability ID mismatch. Requested %s, ability identifies as %s."
			% [ability_id, ability.ability_id]
		)
		return null

	return ability
