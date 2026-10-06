extends RefCounted
class_name AbilityRegistry

const ABILITIES: Dictionary = {
	&"base:blink":preload("res://Scripts/Abilities/blink.gd"),
	&"base:place_campfire":preload("res://Scripts/Abilities/place_campfire.gd"),
	&"base:heal": preload("res://Scripts/Abilities/heal.gd"),
	&"base:throw": preload("res://Scripts/Abilities/throw.gd"),
	}


static func create_ability(ability_id: StringName) -> Ability:
	var ability_script: Script = ABILITIES.get(ability_id)

	if not ability_script:
		return null

	return ability_script.new() as Ability
