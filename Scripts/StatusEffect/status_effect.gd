extends RefCounted
class_name StatusEffect

var effect_id: StringName
var owner: Entity
var source: Object


func on_added() -> void:
	pass


func on_removing() -> void:
	pass


func on_event(_event: GameEvent) -> void:
	pass


func on_resolution(_resolution: GameResolution) -> void:
	pass
