extends GameResolution
class_name HealResolution


var source: Object
var source_item: Item
var target: Entity

var base_healing: float
var healing: float

var allowed: bool = true


func _init(
	_source: Object,
	_target: Entity,
	_base_healing: float,
	_source_item: Item = null
) -> void:
	resolution_id = &"base:heal"

	source = _source
	source_item = _source_item
	target = _target

	base_healing = _base_healing
	healing = _base_healing
