extends RefCounted
class_name ItemComponentRegistry

const COMPONENT_SCRIPTS: Dictionary = {
	&"base:equippable": preload("res://Scripts/ItemComponents/equippable_item_component.gd"),
	&"base:weapon": preload("res://Scripts/ItemComponents/weapon_item_component.gd"),
	&"base:consumable": preload("res://Scripts/ItemComponents/consumable_item_component.gd"),
	&"base:ability_grant": preload("res://Scripts/ItemComponents/ability_grant_item_component.gd"),
}

static func get_component_resource(component_name: StringName) -> ItemComponent:
	var script = COMPONENT_SCRIPTS.get(component_name)
	if not script:
		return null
	
	return script.new() as ItemComponent
