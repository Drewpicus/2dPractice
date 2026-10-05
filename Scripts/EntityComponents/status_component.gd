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
	notify_state_changed()



func remove_effect(effect: StatusEffect) -> void:
	if effect not in effects:
		return

	effect.on_removing()
	losing_effect.emit(effect)
	effects.erase(effect)
	effect.owner = null
	notify_state_changed()


func on_event(event: GameEvent) -> void:
	for effect in effects.duplicate():
		effect.on_event(event)


func on_resolution(resolution: GameResolution) -> void:
	for effect in effects.duplicate():
		effect.on_resolution(resolution)
		

func apply_effect(
	effect: StatusEffect,
	source: Object = null,
	duration: float = -1.0
) -> bool:
	if not effect:
		return false

	if not root_entity:
		return false

	var resolution := StatusApplicationResolution.new(
		source,
		root_entity,
		effect,
		duration
	)

	# Let the target contribute rules about receiving the status.
	root_entity.contribute_to_resolution(
		resolution
	)

	# Let the source contribute too, unless the source IS the target.
	if source is Entity and source != root_entity:
		(source as Entity).contribute_to_resolution(
			resolution
		)

	if source is Item:
		(source as Item).contribute_to_resolution(
			resolution
		)

	resolution.apply_modifiers()

	if not resolution.allowed:
		return false

	effect.source = source
	effect.duration = resolution.duration

	add_effect(effect)

	var event := StatusAppliedEvent.new(
		source,
		root_entity,
		effect
	)

	root_entity.dispatch_event(event)

	if source is Entity and source != root_entity:
		(source as Entity).dispatch_event(event)

	if source is Item:
		(source as Item).dispatch_event(event)

	return true



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
