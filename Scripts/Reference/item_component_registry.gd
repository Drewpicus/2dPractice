extends RefCounted
class_name ItemComponentRegistry

const COMPONENT_SCRIPTS: Dictionary = {
	&"equippable": preload("res://Scripts/ItemComponents/equippable_item_component.gd"),
}

static func get_component_resource(component_name: StringName) -> ItemComponent:
	var script = COMPONENT_SCRIPTS.get(component_name)
	if not script:
		return null
	
	return script.new() as ItemComponent

static func get_component_name(component_name: StringName) -> String:
	return component_name.capitalize().replace(" ","") + "ItemComponent"
