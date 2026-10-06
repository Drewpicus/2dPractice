##The instance of the use of any particular ability. When the ability is used,
##an [AbilityUse] is created describing its use.

extends RefCounted
class_name AbilityUse

var user: Entity
var target_entity: Entity
var target_position: Vector2
var item: Item
