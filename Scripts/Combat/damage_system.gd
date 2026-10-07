extends RefCounted
class_name DamageSystem


static func apply_damage(
	source: Object,
	target: Entity,
	base_damage: float,
	source_item: Item = null
) -> DamageResolution:
	if not target:
		return null

	var health := target.get_component(
		&"base:health"
	) as HealthComponent

	if not health:
		return null

	var resolution := DamageResolution.new(
		source,
		target,
		base_damage,
		source_item
	)

	if source is Entity:
		(source as Entity).contribute_to_resolution(
			resolution
		)

	if source is Item:
		(source as Item).contribute_to_resolution(
			resolution
		)

	if source_item:
		source_item.contribute_to_resolution(
			resolution
		)

	if target != source:
		target.contribute_to_resolution(
			resolution
		)

	resolution.apply_modifiers()

	if resolution.cancelled:
		return resolution

	var final_damage := int(
		resolution.damage
	)

	if final_damage <= 0:
		return resolution

	var old_health := health.health

	health.damage(final_damage)

	var applied_damage := old_health - health.health

	if applied_damage <= 0:
		return resolution

	var event := DamageAppliedEvent.new(
		source,
		target,
		applied_damage,
		resolution,
		source_item
	)

	target.dispatch_event(event)

	if source is Entity and source != target:
		(source as Entity).dispatch_event(event)

	if source is Item:
		(source as Item).dispatch_event(event)

	if not health.is_alive():
		DeathSystem.apply_death(
			source,
			target,
			source_item
		)

	return resolution
