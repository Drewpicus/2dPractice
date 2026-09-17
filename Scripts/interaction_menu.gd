extends PanelContainer
class_name InteractionMenu

var _interactions: Array = []
var _interactor: Entity
var _target: Entity

@onready var _list: VBoxContainer = $VBoxContainer

func _ready() -> void:
	hide()

func show_interactions(interactions: Array, interactor: Entity, target: Entity) -> void:
	_interactions = interactions
	_interactor = interactor
	_target = target
	_rebuild_buttons()
	_follow_target()
	show()

func _rebuild_buttons() -> void:
	var needed := _interactions.size()

	while _list.get_child_count() > needed:
		var extra := _list.get_child(_list.get_child_count() - 1)
		_list.remove_child(extra)
		extra.free()

	while _list.get_child_count() < needed:
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_button_pressed.bind(button))
		_list.add_child(button)

	for i in needed:
		var button := _list.get_child(i) as Button
		var interaction = _interactions[i]
		button.text = interaction.interaction_name
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = not interaction.can_perform(_interactor, _target)

	reset_size()

func _on_button_pressed(button: Button) -> void:
	var id := button.get_index()
	_interactions[id].perform(_interactor, _target)
	hide()

func _on_empty_pressed() -> void:
	hide()

func _process(_delta: float) -> void:
	if not visible:
		return
	if not is_instance_valid(_target):
		hide()
		return

	_follow_target()

	var buttons := _list.get_children()
	for i in _interactions.size():
		if i >= buttons.size():
			break
		var button := buttons[i] as Button
		if button:
			button.disabled = not _interactions[i].can_perform(_interactor, _target)

func _follow_target() -> void:
	global_position = _target.get_global_transform_with_canvas().origin
