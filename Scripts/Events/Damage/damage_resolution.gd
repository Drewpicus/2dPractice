extends GameResolution
class_name DamageResolution


var source: Object
var target: Entity

var base_damage: float
var damage: float

var allowed: bool = true


func _init(
	_source: Object,
	_target: Entity,
	_base_damage: float
) -> void:
	resolution_id = &"base:damage"

	source = _source
	target = _target
	base_damage = _base_damage
	damage = _base_damage
