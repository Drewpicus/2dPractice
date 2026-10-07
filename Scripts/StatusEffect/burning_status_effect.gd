extends StatusEffect
class_name BurningStatusEffect


var damage_per_tick: float = 1.0


func _init() -> void:
	effect_id = &"base:burning"
	stack_mode = STACK_MODE.REFRESH


func on_event(event: GameEvent) -> void:
	if not event is WorldTickEvent:
		return

	if not owner:
		return

	DamageSystem.apply_damage(
		source,
		owner,
		damage_per_tick
	)
