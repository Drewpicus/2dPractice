extends GameEvent
class_name DeathAppliedEvent


var source: Object
var source_item: Item
var target: Entity
var resolution: DeathResolution


func _init(
	_source: Object,
	_target: Entity,
	_resolution: DeathResolution,
	_source_item: Item = null
) -> void:
	event_id = &"base:death_applied"

	source = _source
	source_item = _source_item
	target = _target
	resolution = _resolution
