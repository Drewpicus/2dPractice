extends EntityComponent
class_name StatusComponent

var effects: Array[StatusEffect] = []

signal gained_effect(status: StatusEffect)
signal losing_effect(status: StatusEffect)

func add_effect(effect: StatusEffect) -> void:
	if not effect:
		return

	effects.append(effect)
	effect.owner = root_entity
	effect.on_added()
	gained_effect.emit(effect)


func remove_effect(effect: StatusEffect) -> void:
	if effect not in effects:
		return

	effect.on_removing()
	losing_effect.emit(effect)
	effects.erase(effect)
	effect.owner = null

func on_event(event: GameEvent) -> void:
	for effect in effects.duplicate():
		effect.on_event(event)


func on_resolution(resolution: GameResolution) -> void:
	for effect in effects.duplicate():
		effect.on_resolution(resolution)
		

func serialize_state() -> Dictionary:
	var serialized_effects: Array = []

	for effect in effects:
		if not effect:
			continue

		serialized_effects.append({
			"effect_id": String(effect.effect_id),
			"state": effect.serialize_state()
		})

	return {
		"effects": serialized_effects
	}

func deserialize_state(state: Dictionary) -> void:
	effects.clear()

	var saved_effects = state.get("effects", [])

	if not saved_effects is Array:
		push_error("Serialized status effects must be an Array.")
		return

	for effect_value in saved_effects:
		if not effect_value is Dictionary:
			continue

		var effect_data := effect_value as Dictionary
		var effect_id := StringName(
			effect_data.get("effect_id", "")
		)

		var effect := StatusEffectRegistry.create_effect(effect_id)

		if not effect:
			continue

		effect.owner = root_entity

		var effect_state = effect_data.get("state", {})

		if effect_state is Dictionary:
			effect.deserialize_state(effect_state)

		effects.append(effect)
