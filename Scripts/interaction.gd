extends RefCounted
class_name Interaction

var interaction_id: StringName
var interaction_name: String

func can_perform(_interactor: Entity, _target: Entity) -> bool:
	return false

func perform(_interactor: Entity, _target: Entity) -> void:
	pass
