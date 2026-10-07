extends GameResolution
class_name DeathResolution


var source: Object
var source_item: Item
var target: Entity


func _init(
	_source: Object,
	_target: Entity,
	_source_item: Item = null
) -> void:
	resolution_id = &"base:death"

	source = _source
	source_item = _source_item
	target = _target
