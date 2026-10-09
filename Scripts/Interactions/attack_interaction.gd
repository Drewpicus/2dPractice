#NOTE: Right now this is just a mainhand attack, it might be good to
#generalize this in the future.

extends Interaction
class_name AttackInteraction

func _init() -> void:
	interaction_id = &"base:attack"
	interaction_name = "Attack"

func should_show(_interactor: Entity, _target: Entity) -> bool:
	return true

func can_perform(
	interactor: Entity,
	target: Entity
) -> bool:
	if not interactor.has_component(
		&"base:interactor"
	):
		return false

	if not target.has_component(
		&"base:health"
	):
		return false

	var interactor_component := interactor.get_component(
		&"base:interactor"
	) as InteractorComponent

	if (
		interactor.global_position.distance_to(
			target.global_position
		)
		> interactor_component.reach
	):
		return false

	var combat := interactor.get_component(
		&"base:combat"
	) as CombatComponent

	if (
		combat
		and combat.current_combat
		and combat.current_combat.started
	):
		if not combat.current_combat.is_active(
			interactor
		):
			return false

		if not combat.can_spend_action():
			return false

	return true

func perform(
	interactor: Entity,
	target: Entity
) -> void:
	var resolution := (
		AttackSystem.perform_mainhand_attack(
			interactor,
			target
		)
	)

	if not resolution:
		return

	var combat := interactor.get_component(
		&"base:combat"
	) as CombatComponent

	if (
		combat
		and combat.current_combat
		and combat.current_combat.started
	):
		combat.spend_action()

		print(
			interactor.entity_name,
			" used their Action."
		)

func is_hostile() -> bool:
	return true

func requires_authority() -> bool:
	return true
