##This autoload class manages multiplayer and network-related signals and functions.
extends Node

##The maximum number of players that can be on the same server.
const MAX_PLAYERS: int = 4
##The main game scene, where the magic happens
const GAME_SCENE: String = "res://Scenes/main.tscn"

##True for the player hosting the world
var is_host: bool = false
##True if a valid multiplayer session is active for both hosts and joined clients
var session_active: bool = false
##True if the game has started
var game_started: bool = false
##Temporary boolean which can block things from happening if the game is loading something
var _waiting_for_load: bool = false
##Dictionary of loaded peers. [code]_loaded_peers[1][/code] will return [code]true[/code]
##when the host is loaded, for example.
var _loaded_peers: Dictionary[int, bool] = {}

signal status_changed(message: String)
signal session_role_changed(is_host: bool)
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)
signal game_ready

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

##Begins hosting a game on a given [param port]. For now, must be port forwarded for online multiplayer.
##This function creates an ENetMultiplayerPeer server.
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

##Joins a game at the given [param address] and [param port].
##This function creates an ENetMultiplayerPeer client.
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

##Only can be called by the host, this function marks all peers as unloaded and attempts to
##remotely call [method _load_game] on everyone's game.
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

##Attempts to load the [constant GAME_SCENE] on everyone's scene tree.
##Once the scene loads, the host is marked as loaded and all clients
##are pinged to report that they've successfully loaded as well.
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

##This function is run ON the server BY each loaded client,
##so the server can mark the client that executed this function
##on it as being loaded.
@rpc("any_peer", "reliable")
func _report_game_loaded() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()

	_mark_peer_loaded(peer_id)

##Marks the given peer as loaded and checks if all
##peers have yet been loaded
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

##If all [member _loaded_peers] have been marked as loaded,
##begin the game and communicate this to all clients.
func _check_all_peers_loaded() -> void:
	if not _waiting_for_load:
		return

	for loaded in _loaded_peers.values():
		if not loaded:
			return

	_waiting_for_load = false
	game_started = true

	print("Every peer has loaded the game.")

	_begin_game.rpc()

##Emits the [signal game_ready] signal on every client.
@rpc("authority", "call_local", "reliable")
func _begin_game() -> void:
	print("Game ready on peer ", multiplayer.get_unique_id())
	game_ready.emit()

##Resets the session and announces the disconnect.
func disconnect_session() -> void:
	_reset_session()
	status_changed.emit("Disconnected.")

##Clears all multiplayer session-related data
func _reset_session() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer = null

	is_host = false
	session_active = false
	game_started = false
	_waiting_for_load = false
	_loaded_peers.clear()

	session_role_changed.emit(false)

##Runs automatically when a peer connects and announces their [param peer_id].
##NOTE: This just blocks late joins, that will need to be changed in the future somehow
func _on_peer_connected(peer_id: int) -> void:
	print("Peer connected: ", peer_id)

	if is_host and game_started:
		print("Rejecting peer %s: game already started." % peer_id)

		multiplayer.multiplayer_peer.disconnect_peer(peer_id)
		return

	peer_joined.emit(peer_id)

	if is_host:
		status_changed.emit("Peer %s joined." % peer_id)

##Runs automatically when a peer disconnects
func _on_peer_disconnected(peer_id: int) -> void:
	print("Peer disconnected: ", peer_id)

	peer_left.emit(peer_id)

	if _waiting_for_load:
		_loaded_peers.erase(peer_id)
		_check_all_peers_loaded()

##Runs automatically when this game connects to a server to tell you the connection was successful
func _on_connected_to_server() -> void:
	status_changed.emit("Successfully connected! Peer ID: %s" % multiplayer.get_unique_id())

	print("Connected as peer ",multiplayer.get_unique_id())

##Runs automatically when the game fails to connect to a server and cleans up for the next attempt.
func _on_connection_failed() -> void:
	status_changed.emit("Connection failed.")

	_reset_session()

##Runs when the server you're connected to disconnects and cleans up for the next connection attempt.
func _on_server_disconnected() -> void:
	status_changed.emit("Server disconnected.")

	_reset_session()

##True if your game is the host server; honest runtime check every time
func is_world_authority() -> bool:
	return multiplayer.is_server()

##True if there are any clients on the server
func has_remote_peers() -> bool:
	return not multiplayer.get_peers().is_empty()
