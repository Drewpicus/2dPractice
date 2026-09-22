extends Node
class_name EntityComponent

@export var component_id: StringName

var root_entity: Entity

func _set_owner(owner: Entity) -> void:
	root_entity = owner

func _clear_owner() -> void:
	root_entity = null

func on_added() -> void:
	pass

func on_removing() -> void:
	pass

func get_component(component: StringName) -> EntityComponent:
	if root_entity == null:
		return null

	return root_entity.get_component(component)

func has_component(component: StringName) -> bool:
	if root_entity == null:
		return false

	return root_entity.has_component(component)

func get_interaction_suggestions() -> Array[StringName]:
	return []
