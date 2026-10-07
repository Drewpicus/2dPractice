extends GameEvent
class_name TeleportAppliedEvent


var source: Object
var source_item: Item
var target: Entity
var resolution: TeleportResolution


func _init(
	_source: Object,
	_target: Entity,
	_resolution: TeleportResolution,
	_source_item: Item = null
) -> void:
	event_id = &"base:teleport_applied"

	source = _source
	source_item = _source_item
	target = _target
	resolution = _resolution
