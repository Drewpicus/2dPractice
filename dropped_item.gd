extends Area3D
class_name DroppedItem

@export var item: Item
@onready var sprite: Sprite3D = $Sprite3D

func _ready() -> void:
	if item:
		sprite.texture = item.sprite
		if item.sprite:
			sprite.position.y = item.sprite.get_height() * sprite.pixel_size * 0.5
