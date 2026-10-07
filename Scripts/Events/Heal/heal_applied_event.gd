extends GameEvent
class_name HealAppliedEvent


var source: Object
var source_item: Item
var target: Entity

var healing: int
var resolution: HealResolution


func _init(
	_source: Object,
	_target: Entity,
	_healing: int,
	_resolution: HealResolution,
	_source_item: Item = null
) -> void:
	event_id = &"base:heal_applied"

	source = _source
	source_item = _source_item
	target = _target

	healing = _healing
	resolution = _resolution
