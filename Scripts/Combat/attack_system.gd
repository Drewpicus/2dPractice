extends RefCounted
class_name AttackSystem


static func perform_mainhand_attack(
	attacker: Entity,
	target: Entity
) -> DamageResolution:
	if not attacker or not target:
		return null

	var attack_damage: float = 1.0

	var stats := attacker.get_component(
		&"base:stat_block"
	) as StatBlockComponent

	if stats:
		attack_damage = stats.get_stat(
			Stat.STRENGTH
		)

	var source_item: Item

	var equipment := attacker.get_component(
		&"base:equipment"
	) as EquipmentComponent

	if equipment:
		source_item = equipment.get_equipment(
			&"mainhand"
		)

	return DamageSystem.apply_damage(
		attacker,
		target,
		attack_damage,
		source_item
	)
