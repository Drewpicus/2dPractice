extends ItemComponent
class_name WeaponItemComponent

var weapon_type: StringName
var damage: float

func _init() -> void:
	component_id = &"base:weapon"
