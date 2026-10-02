extends PanelContainer
class_name InspectWindow


@onready var title: Label = (
	$VBoxContainer/Title
)

@onready var description: Label = (
	$VBoxContainer/Description
)

@onready var texture: TextureRect = (
	$VBoxContainer/Texture
)

@onready var close_button: Button = (
	$VBoxContainer/Close
)


func _ready() -> void:
	hide()

	close_button.pressed.connect(
		hide
	)


func show_inspection(
	target: Entity
) -> void:
	if not target:
		hide()
		return

	title.text = target.entity_name
	
	var sprite := target.get_node_or_null(
		"Sprite2D"
	) as Sprite2D

	if sprite:
		texture.texture = sprite.texture

	var info := target.get_component(
		&"base:info"
	) as InfoComponent

	if info:
		description.text = info.description
	else:
		description.text = ""

	show()
