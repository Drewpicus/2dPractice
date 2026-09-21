extends RefCounted
class_name EntityComponentRegistry

const COMPONENT_SCENES: Dictionary = {
	##Universal
	&"base:info": preload("res://Scenes/Components/info_component.tscn"),
	&"base:health": preload("res://Scenes/Components/health_component.tscn"),
	&"base:interactable": preload("res://Scenes/Components/interactable_component.tscn"),
	#material?
	
	##Player Specific
	&"base:player_controller": preload("res://Scenes/Components/player_controller_component.tscn"),
	&"base:interactor": preload("res://Scenes/Components/interactor_component.tscn"),
	
	##Creatures
	&"base:ai_controller": preload("res://Scenes/Components/ai_controller_component.tscn"),
	&"base:movement": preload("res://Scenes/Components/movement_component.tscn"),
	&"base:capability": preload("res://Scenes/Components/capability_component.tscn"),
	&"base:combat": preload("res://Scenes/Components/combat_component.tscn"),
	&"base:stat_block": preload("res://Scenes/Components/stat_block_component.tscn"),
	&"base:inventory": preload("res://Scenes/Components/inventory_component.tscn"),
	&"base:equipment": preload("res://Scenes/Components/equipment_component.tscn"),
	&"base:remains": preload("res://Scenes/Components/remains_component.tscn"),
	#status effect
}

static func get_component_scene(component_name: StringName) -> PackedScene:
	return COMPONENT_SCENES.get(component_name)
