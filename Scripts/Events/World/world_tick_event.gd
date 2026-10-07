extends GameEvent
class_name WorldTickEvent


var delta_seconds: float
var tick_index: int


func _init(
	_delta_seconds: float,
	_tick_index: int
) -> void:
	event_id = &"base:world_tick"

	delta_seconds = _delta_seconds
	tick_index = _tick_index
