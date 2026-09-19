extends RefCounted
class_name ComponentRegistry

const COMPONENT_SCENES: Dictionary = {
	##Universal
	&"info": preload("res://Scenes/Components/info_component.tscn"),
	&"health": preload("res://Scenes/Components/health_component.tscn"),
	&"interactable": preload("res://Scenes/Components/interactable_component.tscn"),
	#material?
	
	##Player Specific
	&"player_controller": preload("res://Scenes/Components/player_controller_component.tscn"),
	&"interactor": preload("res://Scenes/Components/interactor_component.tscn"),
	
	##Creatures
	&"movement": preload("res://Scenes/Components/movement_component.tscn"),
	&"capability": preload("res://Scenes/Components/capability_component.tscn"),
	&"combat": preload("res://Scenes/Components/combat_component.tscn"),
	&"stat_block": preload("res://Scenes/Components/stat_block_component.tscn"),
	&"inventory": preload("res://Scenes/Components/inventory_component.tscn"),
	&"remains": preload("res://Scenes/Components/remains_component.tscn"),
	#ai controller
	#status effect
}

static func get_component_scene(component_name: StringName) -> PackedScene:
	return COMPONENT_SCENES.get(component_name)

static func get_component_name(component_name: StringName) -> String:
	return component_name.capitalize().replace(" ","") + "Component"
