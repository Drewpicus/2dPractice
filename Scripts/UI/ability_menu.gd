extends PanelContainer
class_name AbilityMenu

var _abilities: Array[Ability] = []
var _user: Entity

@onready var _list: VBoxContainer = $VBoxContainer

signal ability_selected(
	ability: Ability,
	user: Entity
)


func _ready() -> void:
	hide()


func show_abilities(user: Entity) -> void:
	if not user:
		hide()
		return

	var ability_component := user.get_component(
		&"base:ability"
	) as AbilityComponent

	if not ability_component:
		hide()
		return

	_user = user
	_abilities = ability_component.get_abilities()

	if _abilities.is_empty():
		hide()
		return

	_rebuild_buttons()
	show()


func close_menu() -> void:
	hide()
	_abilities.clear()
	_user = null


func _rebuild_buttons() -> void:
	var needed := _abilities.size()

	while _list.get_child_count() > needed:
		var extra := _list.get_child(
			_list.get_child_count() - 1
		)
		_list.remove_child(extra)
		extra.free()

	while _list.get_child_count() < needed:
		var button := Button.new()
		button.pressed.connect(
			_on_button_pressed.bind(button)
		)
		_list.add_child(button)

	for i in needed:
		var button := _list.get_child(i) as Button
		var ability := _abilities[i]

		button.text = ability.ability_name


func _on_button_pressed(button: Button) -> void:
	var index := button.get_index()

	if index < 0 or index >= _abilities.size():
		return

	var ability := _abilities[index]

	ability_selected.emit(
		ability,
		_user
	)

	close_menu()
