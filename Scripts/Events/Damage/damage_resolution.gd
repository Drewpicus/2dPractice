extends GameResolution
class_name DamageResolution


var source: Object
var source_item: Item
var target: Entity

var base_damage: float
var damage: float


func _init(
	_source: Object,
	_target: Entity,
	_base_damage: float,
	_source_item: Item = null
) -> void:
	resolution_id = &"base:damage"

	source = _source
	source_item = _source_item
	target = _target

	base_damage = _base_damage
	damage = _base_damage
