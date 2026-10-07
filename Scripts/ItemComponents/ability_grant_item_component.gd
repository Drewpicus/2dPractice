extends ItemComponent
class_name AbilityGrantItemComponent

const WHEN_EQUIPPED := &"equipped"
const WHEN_IN_INVENTORY := &"in_inventory"

@export var ability_ids: Array = []
@export var grant_when: StringName = WHEN_EQUIPPED


func _init() -> void:
	component_id = &"base:ability_grant"


func on_added() -> void:
	if grant_when not in [
		WHEN_EQUIPPED,
		WHEN_IN_INVENTORY
	]:
		push_error(
			"Unsupported ability grant condition: %s"
			% grant_when
		)


func on_added_to_inventory(
	holder: Entity
) -> void:
	if grant_when != WHEN_IN_INVENTORY:
		return

	_grant_to(holder)


func on_removed_from_inventory(
	holder: Entity
) -> void:
	if grant_when != WHEN_IN_INVENTORY:
		return

	_revoke_from(holder)


func on_equipped(
	wearer: Entity,
	_slot: StringName
) -> void:
	if grant_when != WHEN_EQUIPPED:
		return

	_grant_to(wearer)


func on_unequipped(
	wearer: Entity,
	_slot: StringName
) -> void:
	if grant_when != WHEN_EQUIPPED:
		return

	_revoke_from(wearer)


func _grant_to(entity: Entity) -> void:
	var abilities := entity.get_component(
		&"base:ability"
	) as AbilityComponent

	if not abilities:
		return

	for id in ability_ids:
		abilities.grant_ability(
			StringName(id),
			self
		)


func _revoke_from(entity: Entity) -> void:
	var abilities := entity.get_component(
		&"base:ability"
	) as AbilityComponent

	if not abilities:
		return

	for id in ability_ids:
		abilities.revoke_ability(
			StringName(id),
			self
		)
