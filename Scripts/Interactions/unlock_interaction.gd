extends Interaction
class_name UnlockInteraction


func _init() -> void:
	interaction_id = &"base:unlock"
	interaction_name = "Unlock"


func can_perform(interactor: Entity, target: Entity) -> bool:
	if not target.has_component(&"base:locked"):
		return false

	var interactor_component := interactor.get_component(&"base:interactor") as InteractorComponent

	if not interactor_component:
		return false

	return (interactor.global_position.distance_to(target.global_position) <= interactor_component.reach)


func perform(_interactor: Entity, target: Entity) -> void:
	target.remove_component(&"base:locked")


func requires_authority() -> bool:
	return true
