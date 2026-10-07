extends ItemComponent
class_name AbilityGrantItemComponent

@export var ability_ids: Array = []


func _init() -> void:
	component_id = &"base:ability_grant"


func on_equipped(
	wearer: Entity,
	_slot: StringName
) -> void:
	var abilities := wearer.get_component(
		&"base:ability"
	) as AbilityComponent

	if not abilities:
		return

	for id in ability_ids:
		abilities.grant_ability(
			StringName(id),
			self
		)


func on_unequipped(
	wearer: Entity,
	_slot: StringName
) -> void:
	var abilities := wearer.get_component(
		&"base:ability"
	) as AbilityComponent

	if not abilities:
		return

	for id in ability_ids:
		abilities.revoke_ability(
			StringName(id),
			self
		)
