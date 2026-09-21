extends RefCounted
class_name InteractionRegistry

const INTERACTIONS: Dictionary = {
	##Universal
	&"base:inspect": preload("res://Scripts/Interactions/inspect_interaction.gd"),
	&"base:attack": preload("res://Scripts/Interactions/attack_interaction.gd"),

	&"base:open_inventory": preload("res://Scripts/Interactions/open_inventory_interaction.gd"),
	&"base:pickpocket": preload("res://Scripts/Interactions/pickpocket_interaction.gd"),
}

static func create_interaction(interaction_id: StringName) -> Interaction:
	if not GameID.is_valid(interaction_id):
		push_error("Invalid Interaction ID: %s" % interaction_id)
		return null

	var interaction_script: Script = INTERACTIONS.get(interaction_id)

	if not interaction_script:
		push_error("Unregistered Interaction ID: %s" % interaction_id)
		return null

	var interaction := interaction_script.new() as Interaction

	if not interaction:
		push_error("Registered script does not create an Interaction: %s" % interaction_id)
		return null

	if interaction.interaction_id != interaction_id:
		push_error(
			"Interaction ID mismatch. Requested %s, interaction identifies as %s." % [interaction_id, interaction.interaction_id])
		return null

	return interaction
