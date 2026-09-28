extends Interaction
class_name BeInteraction

func _init() -> void:
	interaction_id = &"base:be"
	interaction_name = "Be"

func should_show(_interactor: Entity, _target: Entity) -> bool:
	return true

func can_perform(_interactor: Entity, _target: Entity) -> bool:
	if not _interactor.has_component(&"base:interactor"):
		return false
	if not _target.has_component(&"base:interactor"):
		return false
	return true

func perform(_interactor: Entity, _target: Entity) -> void:
	_interactor.remove_component("base:player_controller")
	_target.add_component("base:player_controller")
	_target.remove_component("base:ai_controller")
