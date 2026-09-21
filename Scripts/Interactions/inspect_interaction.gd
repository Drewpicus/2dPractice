extends Interaction
class_name InspectInteraction

func _init() -> void:
	interaction_id = &"base:inspect"
	interaction_name = "Inspect"

func can_perform(_interactor: Entity, _target: Entity) -> bool:
	if not _interactor.has_component(&"base:interactor"):
		return false
	if not _target.has_component(&"base:info"):
		return false
	return true

func perform(_interactor: Entity, _target: Entity) -> void:
	print(_target.get_component(&"base:info").description)
