extends ItemComponent
class_name WeaponItemComponent

#NOTE: make weapon type data driven, add 
var weapon_type
var damage


func _init() -> void:
	component_id = &"base:weapon"
