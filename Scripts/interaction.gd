extends RefCounted
class_name Interaction

var interaction_id: StringName
var interaction_name: String

func should_show(_interactor: Entity, _target: Entity) -> bool:
	return true

func can_perform(_interactor: Entity, _target: Entity) -> bool:
	return false

func perform(_interactor: Entity, _target: Entity) -> void:
	pass
