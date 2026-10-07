extends GameResolution
class_name TeleportResolution


var source: Object
var source_item: Item
var target: Entity

var origin: Vector2
var destination: Vector2


func _init(
	_source: Object,
	_target: Entity,
	_destination: Vector2,
	_source_item: Item = null
) -> void:
	resolution_id = &"base:teleport"

	source = _source
	source_item = _source_item
	target = _target

	origin = target.global_position
	destination = _destination
