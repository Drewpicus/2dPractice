extends GameEvent
class_name DamageAppliedEvent


var source: Object
var source_item: Item
var target: Entity

var damage: int
var resolution: DamageResolution


func _init(
	_source: Object,
	_target: Entity,
	_damage: int,
	_resolution: DamageResolution,
	_source_item: Item = null
) -> void:
	event_id = &"base:damage_applied"

	source = _source
	source_item = _source_item
	target = _target

	damage = _damage
	resolution = _resolution
