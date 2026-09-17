extends RefCounted
class_name InteractionRegistry

const INTERACTIONS: Dictionary = {
	##Universal
	&"inspect": preload("res://Scripts/Interactions/inspect_interaction.gd"),
	&"attack": preload("res://Scripts/Interactions/attack_interaction.gd"),

	&"open_inventory": preload("res://Scripts/Interactions/open_inventory_interaction.gd"),
	&"pickpocket": preload("res://Scripts/Interactions/pickpocket_interaction.gd"),
}

static func create_interaction(interaction_id: StringName) -> Interaction:
	var interaction_script: Script = INTERACTIONS.get(interaction_id)
	
	if interaction_script == null:
		return null
	
	return interaction_script.new()
