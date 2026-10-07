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

	if target != source:
		target.contribute_to_resolution(
			resolution
		)

	resolution.apply_modifiers()

	if not resolution.allowed:
		return resolution

	var final_damage := int(
		resolution.damage
	)

	if final_damage <= 0:
		return resolution

	health.damage(final_damage)

	return resolution
