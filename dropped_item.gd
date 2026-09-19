extends Area2D
class_name DroppedItem

@export var item: Item
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if item:
		sprite.texture = item.sprite
