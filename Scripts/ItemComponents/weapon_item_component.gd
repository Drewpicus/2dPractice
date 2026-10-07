extends ItemComponent
class_name WeaponItemComponent

var weapon_type: StringName
var damage: float

func _init() -> void:
	component_id = &"base:weapon"

func on_resolution(
	resolution: GameResolution
) -> void:
	if not resolution is DamageResolution:
		return

	var damage_resolution := resolution as DamageResolution

	if damage_resolution.source_item != root_item:
		return

	contribute_modifier(
		resolution,
		DamageFlatModifier.new(damage)
	)
