extends Node

signal status_changed(message: String)
signal session_role_changed(is_host: bool)
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)
signal game_ready

const MAX_PLAYERS: int = 4
const GAME_SCENE: String = "res://Scenes/main.tscn"

var is_host: bool = false
var session_active: bool = false

var _waiting_for_load: bool = false
var _loaded_peers: Dictionary[int, bool] = {}

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game(port: int) -> Error:
	_reset_session()
	
	var peer := ENetMultiplayerPeer.new()
	
	var error = peer.create_server(port,MAX_PLAYERS-1)
	
	if error != OK:
		status_changed.emit("Could not host game. Error: %s" % error)
		return error
	
	multiplayer.multiplayer_peer = peer
	
	is_host = true
	session_active = true
	status_changed.emit("Server active")
	session_role_changed.emit(true)
	print("Hosting. Peer ID: ",multiplayer.get_unique_id())
	return error

func join_game(address: String, port: int) -> Error:
	_reset_session()
	
	var peer := ENetMultiplayerPeer.new()
	
	var error := peer.create_client(address, port)
	
	if error != OK:
		status_changed.emit("Could not begin connect. Error: %s" % error)
		return error
	
	multiplayer.multiplayer_peer = peer
	
	is_host = false
	session_active = true
	status_changed.emit("Connecting to %s:%s..." % [address, port])
	session_role_changed.emit(false)

	return error

func start_game() -> void:
	if not session_active:
		return
	
	if not is_host:
		return
	
	_loaded_peers.clear()
	_loaded_peers[1] = false
	for peer_id in multiplayer.get_peers():
		_loaded_peers[int(peer_id)] = false
	
	_waiting_for_load = true
	
	print("Starting game for peers: ",_loaded_peers.keys())

	_load_game.rpc(GAME_SCENE)

@rpc("authority", "call_local", "reliable")
func _load_game(scene_path: String) -> void:
	var error := get_tree().change_scene_to_file(scene_path)

	if error != OK:
		push_error("Could not load game scene: %s" % error)
		return

	await get_tree().scene_changed

	if multiplayer.is_server():
		_mark_peer_loaded(multiplayer.get_unique_id())
	else:
		_report_game_loaded.rpc_id(1)


@rpc("any_peer", "reliable")
func _report_game_loaded() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()

	_mark_peer_loaded(peer_id)


func _mark_peer_loaded(peer_id: int) -> void:
	if not _waiting_for_load:
		return

	if not _loaded_peers.has(peer_id):
		return

	if _loaded_peers[peer_id]:
		return

	_loaded_peers[peer_id] = true

	print("Peer finished loading: ", peer_id)

	_check_all_peers_loaded()


func _check_all_peers_loaded() -> void:
	if not _waiting_for_load:
		return

	for loaded in _loaded_peers.values():
		if not loaded:
			return

	_waiting_for_load = false

	print("Every peer has loaded the game.")

	_begin_game.rpc()


@rpc("authority", "call_local", "reliable")
func _begin_game() -> void:
	print("Game ready on peer ", multiplayer.get_unique_id())
	game_ready.emit()


func disconnect_session() -> void:
	_reset_session()
	status_changed.emit("Disconnected.")


func _reset_session() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer = null

	is_host = false
	session_active = false
	_waiting_for_load = false
	_loaded_peers.clear()

	session_role_changed.emit(false)


func _on_peer_connected(peer_id: int) -> void:
	print("Peer connected: ", peer_id)

	peer_joined.emit(peer_id)

	if is_host:
		status_changed.emit("Peer %s joined." % peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	print("Peer disconnected: ", peer_id)

	peer_left.emit(peer_id)

	if _waiting_for_load:
		_loaded_peers.erase(peer_id)
		_check_all_peers_loaded()


func _on_connected_to_server() -> void:
	status_changed.emit(
		"Connected. Peer ID: %s" % multiplayer.get_unique_id())

	print("Connected as peer ",multiplayer.get_unique_id())


func _on_connection_failed() -> void:
	status_changed.emit("Connection failed.")

	_reset_session()


func _on_server_disconnected() -> void:
	status_changed.emit("Server disconnected.")

	_reset_session()

func is_world_authority() -> bool:
	if not session_active:
		return true

	return multiplayer.is_server()
