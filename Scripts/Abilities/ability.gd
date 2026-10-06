##An ability a player can execute at will, with limitations of course.

extends RefCounted
class_name Ability

enum TARGET_TYPE {
	POSITION,
	ENTITY,
	ITEM
}

var ability_id: StringName
var ability_name: String

var target_requirements: Array = []

##True if the [AbilityUse] can be used
func can_use(_use: AbilityUse) -> bool:
	return false

##Attempts to perform the [AbilityUse]
##True if the [Ability] was performed successfully
func perform(_use: AbilityUse) -> bool:
	return false
