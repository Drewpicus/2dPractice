extends Resource
class_name EntityDefinition

@export var entity_id: StringName
@export var entity_name: String
@export var sprite: Texture2D
@export var sprite_orientation: StringName = &"upright"
@export var collision_shape: Shape3D
@export var solid: bool = true

@export var components: Array[EntityComponentDefinition]
