extends EntityComponent
class_name StatusComponent

var effects: Array[StatusEffect] = []
var _restoring_state: bool = false

signal gained_effect(status: StatusEffect)
signal losing_effect(status: StatusEffect)

func add_effect(effect: StatusEffect) -> void:
	if not effect:
		return

	effects.append(effect)
	effect.owner = root_entity
	effect.on_added()
	gained_effect.emit(effect)

	if not _restoring_state:
		notify_state_changed()


func remove_effect(effect: StatusEffect) -> void:
	if effect not in effects:
		return

	effect.on_removing()
	losing_effect.emit(effect)
	effects.erase(effect)
	effect.owner = null

	if not _restoring_state:
		notify_state_changed()

func get_effects_by_id(
	effect_id: StringName
) -> Array[StatusEffect]:
	var result: Array[StatusEffect] = []

	for effect in effects:
		if effect.effect_id == effect_id:
			result.append(effect)

	return result

func on_removing() -> void:
	for effect in effects.duplicate():
		remove_effect(effect)


func on_event(event: GameEvent) -> void:
	if event is WorldTickEvent:
		_handle_world_tick(
			event as WorldTickEvent
		)
		return

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

	if resolution.cancelled:
		return false

	effect.source = source
	effect.duration = resolution.duration

	var existing := get_effects_by_id(
		effect.effect_id
	)

	match effect.stack_mode:
		StatusEffect.STACK_MODE.STACK:
			add_effect(effect)

		StatusEffect.STACK_MODE.REFRESH:
			if existing.is_empty():
				add_effect(effect)
			else:
				var current := existing[0]

				current.source = effect.source

				# Negative duration means indefinite.
				# An indefinite effect stays indefinite, and applying
				# an indefinite version makes the existing one indefinite.
				if current.duration < 0.0 or effect.duration < 0.0:
					current.duration = -1.0
				else:
					current.duration = max(
						current.duration,
						effect.duration
					)

				notify_state_changed()

				effect = current

		StatusEffect.STACK_MODE.EXTEND:
			if existing.is_empty():
				add_effect(effect)
			else:
				var current := existing[0]

				current.source = effect.source

				# Indefinite + anything remains indefinite.
				if current.duration < 0.0 or effect.duration < 0.0:
					current.duration = -1.0
				else:
					current.duration += effect.duration

				notify_state_changed()

				effect = current

		StatusEffect.STACK_MODE.REPLACE:
			for current in existing:
				remove_effect(current)

			add_effect(effect)

		StatusEffect.STACK_MODE.IGNORE:
			if not existing.is_empty():
				return false

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
			"duration": effect.duration,
			"source_instance_id": _source_instance_id(effect.source),
			"state": effect.serialize_state()
		})

	return {
		"effects": serialized_effects
	}

func deserialize_state(state: Dictionary) -> void:
	var saved_effects = state.get("effects", [])

	if not saved_effects is Array:
		push_error("Serialized status effects must be an Array.")
		return

	_restoring_state = true

	for effect in effects.duplicate():
		remove_effect(effect)

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

		effect.duration = float(effect_data.get("duration", -1.0))

		var effect_state = effect_data.get("state", {})

		if effect_state is Dictionary:
			effect.deserialize_state(effect_state)

		effect.source = _source_from_instance_id(
			String(effect_data.get("source_instance_id", ""))
		)

		add_effect(effect)

	_restoring_state = false
	notify_state_changed()


func _source_instance_id(source: Object) -> String:
	if source is Entity:
		return (source as Entity).instance_id

	if source is Item:
		return (source as Item).instance_id

	return ""


func _source_from_instance_id(instance_id: String) -> Object:
	if instance_id.is_empty():
		return null

	return RuntimeObjectRegistry.get_object(instance_id)

func _handle_world_tick(
	event: WorldTickEvent
) -> void:
	var duration_changed := false

	for effect in effects.duplicate():
		if not effect:
			continue

		# The effect gets to act while it is still active.
		effect.on_event(event)

		# The effect may have removed itself while handling the tick.
		if effect not in effects:
			continue

		# Negative duration means indefinite.
		if effect.duration < 0.0:
			continue

		effect.duration -= 1.0
		duration_changed = true

		if effect.duration <= 0.0:
			remove_effect(effect)

	if duration_changed:
		notify_state_changed()
