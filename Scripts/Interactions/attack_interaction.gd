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
	var attack_damage: float = 1.0

	var interactor_stats := interactor.get_component(
		&"base:stat_block"
	) as StatBlockComponent

	if interactor_stats:
		attack_damage = interactor_stats.get_stat(
			Stat.STRENGTH
		)

	var source_item: Item

	var equipment := interactor.get_component(
		&"base:equipment"
	) as EquipmentComponent

	if equipment:
		var mainhand_item := equipment.get_equipment(
			&"mainhand"
		)

		if (
			mainhand_item
			and mainhand_item.has_component(
				&"base:weapon"
			)
		):
			source_item = mainhand_item

	var resolution := DamageResolution.new(
		interactor,
		target,
		attack_damage,
		source_item
	)

	interactor.contribute_to_resolution(
		resolution
	)

	if target != interactor:
		target.contribute_to_resolution(
			resolution
		)

	resolution.apply_modifiers()

	if not resolution.allowed:
		return

	var target_health := target.get_component(
		&"base:health"
	) as HealthComponent

	if not target_health:
		return

	var final_damage := int(resolution.damage)

	if final_damage <= 0:
		return

	target_health.damage(final_damage)

	print(
		"%s attacks %s for %d damage!"
		% [
			interactor.entity_name,
			target.entity_name,
			final_damage
		]
	)

func requires_authority() -> bool:
	return true
