extends RefCounted
class_name StatusEffect

enum STACK_MODE {
	STACK,
	EXTEND,
	REFRESH,
	REPLACE,
	IGNORE
}

var effect_id: StringName
var owner: Entity
var source: Object

var duration: float = -1.0
var stack_mode: STACK_MODE = STACK_MODE.REFRESH

func on_added() -> void:
	pass

func on_removing() -> void:
	pass

func on_event(_event: GameEvent) -> void:
	pass

func on_resolution(_resolution: GameResolution) -> void:
	pass

func serialize_state() -> Dictionary:
	return {}

func deserialize_state(_state: Dictionary) -> void:
	pass
