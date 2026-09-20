extends Resource
class_name ItemDefinition

@export var item_name: String
@export var sprite: Texture2D
@export var components: Array[ItemComponent]

func get_component(id: StringName) -> ItemComponent:
	for component in components:
		if component and component.get_id() == id:
			return component
	return null

func has_component(id: StringName) -> bool:
	return get_component(id) != null
