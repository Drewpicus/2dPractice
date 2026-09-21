extends Node
class_name EntityComponent

@export var component_id: StringName

@onready var root_entity: Entity = Entity.find_entity(self)

func get_component(component: StringName) -> Node:
	if root_entity == null:
		return null

	return root_entity.get_component(component)

func has_component(component: StringName) -> bool:
	if root_entity == null:
		return false

	return root_entity.has_component(component)

func get_interaction_suggestions() -> Array[StringName]:
	return []
