extends StatusEffect
class_name BurningStatusEffect


func _init() -> void:
	effect_id = &"base:burning"


func serialize_state() -> Dictionary:
	return {
		"duration": duration
	}


func deserialize_state(state: Dictionary) -> void:
	duration = float(
		state.get("duration", -1.0)
	)
