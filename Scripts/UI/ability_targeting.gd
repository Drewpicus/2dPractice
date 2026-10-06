extends Node
class_name AbilityTargeting

var ability: Ability
var use: AbilityUse

var _requirement_index: int = 0


func begin(
	selected_ability: Ability,
	user: Entity
) -> void:
	if not selected_ability or not user:
		return

	ability = selected_ability

	use = AbilityUse.new()
	use.user = user

	_requirement_index = 0

func get_current_requirement() -> Variant:
	if not ability:
		return null

	if _requirement_index >= ability.target_requirements.size():
		return null

	return ability.target_requirements[
		_requirement_index
	]

func _advance() -> void:
	_requirement_index += 1

	if (
		_requirement_index
		>= ability.target_requirements.size()
	):
		_submit()

func provide_position(
	position: Vector2
) -> void:
	if (
		get_current_requirement()
		!= Ability.TARGET_TYPE.POSITION
	):
		return

	use.set_target_position(position)

	_advance()

func provide_entity(
	entity: Entity
) -> void:
	if (
		get_current_requirement()
		!= Ability.TARGET_TYPE.ENTITY
	):
		return

	if not entity:
		return

	use.target_entity = entity

	_advance()

func _submit() -> void:
	if not ability or not use:
		return

	var world := GameWorld.find_world(
		use.user
	)

	if not world:
		return

	world.submit_ability(
		ability,
		use
	)

	cancel()

func cancel() -> void:
	ability = null
	use = null
	_requirement_index = 0
