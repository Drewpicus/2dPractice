extends RefCounted
class_name HealSystem


static func apply_healing(
	source: Object,
	target: Entity,
	base_healing: float,
	source_item: Item = null
) -> HealResolution:
	if not target:
		return null

	var health := target.get_component(
		&"base:health"
	) as HealthComponent

	if not health:
		return null

	var resolution := HealResolution.new(
		source,
		target,
		base_healing,
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

	if not resolution.allowed:
		return resolution

	var final_healing := int(
		resolution.healing
	)

	if final_healing <= 0:
		return resolution

	var old_health := health.health

	health.heal(final_healing)

	var applied_healing := health.health - old_health

	if applied_healing <= 0:
		return resolution

	var event := HealAppliedEvent.new(
		source,
		target,
		applied_healing,
		resolution,
		source_item
	)

	target.dispatch_event(event)

	if source is Entity and source != target:
		(source as Entity).dispatch_event(event)

	if source is Item:
		(source as Item).dispatch_event(event)

	return resolution
