extends GameResolution
class_name StatusApplicationResolution

var source: Object
var target: Entity
var effect: StatusEffect

var duration: float

func _init(
	_source: Object,
	_target: Entity,
	_effect: StatusEffect,
	_duration: float
) -> void:
	resolution_id = &"base:status_application"

	source = _source
	target = _target
	effect = _effect
	duration = _duration
