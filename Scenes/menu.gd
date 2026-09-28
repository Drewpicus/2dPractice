extends Node2D

@onready var port_input: LineEdit = $CanvasLayer/VBoxContainer/Port
@onready var address_input: LineEdit = $CanvasLayer/VBoxContainer/IPAddress

@onready var host_button: Button = $CanvasLayer/VBoxContainer/HostButton
@onready var join_button: Button = $CanvasLayer/VBoxContainer/JoinButton
@onready var start_button: Button = $CanvasLayer/VBoxContainer/StartButton

@onready var status_label: Label = $CanvasLayer/VBoxContainer/StatusLabel


func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	start_button.pressed.connect(_on_start_pressed)

	MultiplayerManager.status_changed.connect(
		_on_status_changed
	)

	MultiplayerManager.session_role_changed.connect(
		_on_session_role_changed
	)

	start_button.visible = false


func _on_host_pressed() -> void:
	var port := _get_port()

	if port == -1:
		return

	MultiplayerManager.host_game(port)


func _on_join_pressed() -> void:
	var port := _get_port()

	if port == -1:
		return

	var address := address_input.text.strip_edges()

	if address.is_empty():
		address = "127.0.0.1"

	MultiplayerManager.join_game(
		address,
		port
	)


func _on_start_pressed() -> void:
	MultiplayerManager.start_game()


func _get_port() -> int:
	if not port_input.text.is_valid_int():
		status_label.text = "Port must be a number."
		return -1

	var port := port_input.text.to_int()

	if port < 1 or port > 65535:
		status_label.text = "Port must be between 1 and 65535."
		return -1

	return port


func _on_status_changed(message: String) -> void:
	status_label.text = message


func _on_session_role_changed(hosting: bool) -> void:
	start_button.visible = hosting
