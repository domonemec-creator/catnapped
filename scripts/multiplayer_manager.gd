extends Node

signal session_state_changed
signal join_succeeded
signal join_failed(message: String)
signal session_disconnected(message: String)
signal peers_changed

const DEFAULT_PORT := 7000
const DEFAULT_ADDRESS := "127.0.0.1"
const MAX_CLIENTS := 8

var session_mode: StringName = &"singleplayer"
var current_address: String = DEFAULT_ADDRESS
var current_port: int = DEFAULT_PORT


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _bind_multiplayer_signals()


func start_singleplayer() -> void:
    disconnect_session(true)


func host_session(port: int = DEFAULT_PORT) -> Error:
    disconnect_session(true)

    var peer := ENetMultiplayerPeer.new()
    var result := peer.create_server(port, MAX_CLIENTS)
    if result != OK:
        return result

    multiplayer.multiplayer_peer = peer
    session_mode = &"host"
    current_port = port
    current_address = DEFAULT_ADDRESS
    session_state_changed.emit()
    peers_changed.emit()
    return OK


func join_session(address: String, port: int = DEFAULT_PORT) -> Error:
    disconnect_session(true)

    var peer := ENetMultiplayerPeer.new()
    var result := peer.create_client(address, port)
    if result != OK:
        return result

    multiplayer.multiplayer_peer = peer
    session_mode = &"client"
    current_address = address
    current_port = port
    session_state_changed.emit()
    return OK


func disconnect_session(silent: bool = false) -> void:
    var was_active := is_session_active()
    var previous_mode := session_mode

    if multiplayer.multiplayer_peer != null:
        multiplayer.multiplayer_peer.close()
        multiplayer.multiplayer_peer = null

    session_mode = &"singleplayer"
    current_address = DEFAULT_ADDRESS
    current_port = DEFAULT_PORT
    session_state_changed.emit()
    peers_changed.emit()

    if not silent and was_active and previous_mode != &"singleplayer":
        session_disconnected.emit("Network session closed.")


func is_session_active() -> bool:
    var peer := multiplayer.multiplayer_peer
    if peer == null:
        return false
    return peer.get_class() != "OfflineMultiplayerPeer"


func is_host() -> bool:
    return session_mode == &"host" and multiplayer.is_server()


func is_client() -> bool:
    return session_mode == &"client" and is_session_active()


func get_unique_id() -> int:
    if is_session_active():
        return multiplayer.get_unique_id()
    return 1


func get_connected_peers() -> Array[int]:
    var peers: Array[int] = []
    if not is_session_active():
        return peers

    for peer_id in multiplayer.get_peers():
        peers.append(peer_id)
    return peers


func _bind_multiplayer_signals() -> void:
    if not multiplayer.peer_connected.is_connected(_on_peer_connected):
        multiplayer.peer_connected.connect(_on_peer_connected)
    if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
        multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
        multiplayer.connected_to_server.connect(_on_connected_to_server)
    if not multiplayer.connection_failed.is_connected(_on_connection_failed):
        multiplayer.connection_failed.connect(_on_connection_failed)
    if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
        multiplayer.server_disconnected.connect(_on_server_disconnected)


func _on_peer_connected(_peer_id: int) -> void:
    peers_changed.emit()


func _on_peer_disconnected(_peer_id: int) -> void:
    peers_changed.emit()


func _on_connected_to_server() -> void:
    peers_changed.emit()
    join_succeeded.emit()


func _on_connection_failed() -> void:
    disconnect_session(true)
    join_failed.emit("Could not connect to the host.")


func _on_server_disconnected() -> void:
    disconnect_session(true)
    session_disconnected.emit("Lost connection to the host.")
