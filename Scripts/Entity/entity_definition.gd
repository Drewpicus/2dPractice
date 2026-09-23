extends Resource
class_name EntityDefinition

@export var entity_id: StringName
@export var entity_name: String
@export var sprite: Texture2D
@export var collision_shape: Shape2D
@export var solid: bool = true

@export var components: Array[EntityComponentDefinition]
