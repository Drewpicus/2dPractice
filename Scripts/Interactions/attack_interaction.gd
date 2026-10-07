#NOTE: Right now this is just a mainhand attack, it might be good to
#generalize this in the future.

extends Interaction
class_name AttackInteraction

func _init() -> void:
	interaction_id = &"base:attack"
	interaction_name = "Attack"

func should_show(_interactor: Entity, _target: Entity) -> bool:
	return true

func can_perform(_interactor: Entity, _target: Entity) -> bool:
	if not _interactor.has_component(&"base:interactor"):
		return false
	if not _target.has_component(&"base:health"):
		return false
	if _interactor.global_position.distance_to(_target.global_position) > _interactor.get_component(&"base:interactor").reach:
		return false
	return true

func perform(
	interactor: Entity,
	target: Entity
) -> void:
	AttackSystem.perform_mainhand_attack(
		interactor,
		target
	)

func requires_authority() -> bool:
	return true
