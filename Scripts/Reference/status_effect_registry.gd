extends RefCounted
class_name StatusEffectRegistry

const EFFECTS: Dictionary = {
	&"base:burning": preload("res://Scripts/StatusEffect/burning_status_effect.gd"),
	&"base:wet": preload("res://Scripts/StatusEffect/wet_status_effect.gd"),
}


static func create_effect(effect_id: StringName) -> StatusEffect:
	if not GameID.is_valid(effect_id):
		push_error("Invalid StatusEffect ID: %s" % effect_id)
		return null

	var effect_script: Script = EFFECTS.get(effect_id)

	if not effect_script:
		push_error("Unregistered StatusEffect ID: %s" % effect_id)
		return null

	var effect := effect_script.new() as StatusEffect

	if not effect:
		push_error(
			"Registered script does not create a StatusEffect: %s"
			% effect_id
		)
		return null

	if effect.effect_id != effect_id:
		push_error(
			"StatusEffect ID mismatch. Requested %s, effect identifies as %s."
			% [effect_id, effect.effect_id]
		)
		return null

	return effect
