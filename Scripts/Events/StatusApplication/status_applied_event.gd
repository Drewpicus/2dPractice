extends GameEvent
class_name StatusAppliedEvent

var source: Object
var target: Entity
var effect: StatusEffect


func _init(
	_source: Object,
	_target: Entity,
	_effect: StatusEffect
) -> void:
	event_id = &"base:status_applied"

	source = _source
	target = _target
	effect = _effect
