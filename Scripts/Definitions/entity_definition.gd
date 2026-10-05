extends Resource
class_name EntityDefinition

var entity_id: StringName
var entity_name: String
var sprite: Texture2D
var collision_shape: Shape2D
var solid: bool = true
var draw_layer: int = 0

var components: Array[EntityComponentDefinition]
