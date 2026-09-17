extends Interaction
class_name PickpocketInteraction

func _init() -> void:
	interaction_id = &"pickpocket"
	interaction_name = "Pickpocket"

func can_perform(_interactor: Entity, _target: Entity) -> bool:
	if not _target.has_component(&"inventory"):
		return false
	if _interactor.global_position.distance_to(_target.global_position) > _interactor.get_component(&"interactor").reach:
		return false
	return true

func perform(_interactor: Entity, _target: Entity) -> void:
	print(_target.get_component(&"inventory").items)
