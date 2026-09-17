extends Control

const PORT : int = 7777
const MAX_PLAYERS : int = 4

@export var player_scene: PackedScene

@onready var address_input: LineEdit = $VBoxContainer/AddressInput
@onready var host_button: Button = $VBoxContainer/HostButton
@onready var join_button: Button = $VBoxContainer/JoinButton
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var players: Node2D = $Players
@onready var player_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var alt_sprite: Texture2D = preload("res://real man2.png")

func _ready() -> void:
	host_button.pressed.connect(host_game)
	join_button.pressed.connect(join_game)
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	player_spawner.spawn_function = _spawn_player

func host_game() -> void:
	var peer := ENetMultiplayerPeer.new()
	
	var error := peer.create_server(PORT, MAX_PLAYERS)
	
	if error != OK:
		status_label.text = "Could not host game"
		print("Host error: ",error)
		return
	
	multiplayer.multiplayer_peer = peer
	
	status_label.text = "Hosting game"
	print("Server started")
	print("My peer ID: ",multiplayer.get_unique_id())
	player_spawner.spawn(multiplayer.get_unique_id())

func join_game() -> void:
	var peer := ENetMultiplayerPeer.new()
	var address := address_input.text.strip_edges()
	
	var error := peer.create_client(address,PORT)
	
	if error != OK:
		status_label.text = "Could not begin connection."
		print("Join error: ", error)
		return

	multiplayer.multiplayer_peer = peer

	status_label.text = "Connecting..."
	print("Attempting connection...")

func _on_peer_connected(id:int) -> void:
	print("Peer connected: ",id)
	
	if multiplayer.is_server():
		player_spawner.spawn(id)

func _on_peer_disconnected(id:int) -> void:
	print("Peer disconnected: ",id)

func _on_connected_to_server() -> void:
	status_label.text = "Connected to server!"
	print("Successfully connected to server")
	print("My peer ID: ",multiplayer.get_unique_id())

func _on_connection_failed() -> void:
	status_label.text = "Connection failed."
	print("Connection failed.")

func _on_server_disconnected() -> void:
	status_label.text = "Server disconnected."
	print("Server disconnected.")

func _spawn_player(peer_id:int):
	var player = player_scene.instantiate()
	
	player.name = str(peer_id)
	player.set_multiplayer_authority(peer_id)
	
	player.position = Vector2(
		20 + (players.get_child_count() + 1) * 80,
		20
	)
	
	if peer_id != 1:
		var sprite = player.get_node_or_null("Sprite2D")
		if sprite:
			sprite.texture = alt_sprite
	
	print("Spawner created player for peer: ", peer_id)
	return player
