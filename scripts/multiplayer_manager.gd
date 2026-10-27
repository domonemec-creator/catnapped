extends Node

# Síť pro souboj 1v1 (D-022, D4): přímá IP přes ENet (LAN / Radmin VPN).
# Host je autorita: simuluje souboj, klientovi posílá snímky stavu, klient posílá jen akce.

signal session_state_changed
signal join_succeeded
signal join_failed(message: String)
signal session_disconnected(message: String)
signal peers_changed
signal match_ready  # oba hráči jsou domluvení, net_match je vyplněný
signal snapshot_received(snapshot: Dictionary)
signal remote_action_received(action: Dictionary)

const DEFAULT_PORT := 7000
const DEFAULT_ADDRESS := "127.0.0.1"
const MAX_CLIENTS := 1
const BATTLE_SCENE_PATH := "res://scenes/card_game/battle_scene.tscn"
# Zvyš při každé změně RPC nebo formátu snímku: různé verze hry spolu nehrají.
const PROTOCOL_VERSION := 7  # 3: Bojový nástup do prázdné lajny zraní soupeře, 4: Hostina nejvýš 3×, 5: hra ve dvou 30 životů / 10 Tun, 6: balík ve dvou přesně 30 karet, max 3 kopie, 7: Plíživost (D-031)

var session_mode: StringName = &"singleplayer"
var current_address: String = DEFAULT_ADDRESS
var current_port: int = DEFAULT_PORT
# Nastavení probíhajícího zápasu: role (&"host"/&"client"), my_name, opponent_name, opponent_deck, host_first.
var net_match: Dictionary = {}
# Poslední snímek pro klienta (může dorazit dřív, než se načte scéna souboje).
var last_snapshot: Dictionary = {}
var local_name: String = ""
var local_deck: Array[StringName] = []


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _bind_multiplayer_signals()


func start_singleplayer() -> void:
    disconnect_session(true)


# Hostitel: založí server a čeká na soupeře. Jméno a balík se pošlou v hello.
func host_session(port: int = DEFAULT_PORT, player_name: String = "", deck_ids: Array[StringName] = []) -> Error:
    disconnect_session(true)

    var peer := ENetMultiplayerPeer.new()
    var result := peer.create_server(port, MAX_CLIENTS)
    if result != OK:
        return result

    multiplayer.multiplayer_peer = peer
    session_mode = &"host"
    current_port = port
    current_address = DEFAULT_ADDRESS
    local_name = player_name
    local_deck = deck_ids
    session_state_changed.emit()
    peers_changed.emit()
    return OK


func join_session(address: String, port: int = DEFAULT_PORT, player_name: String = "", deck_ids: Array[StringName] = []) -> Error:
    disconnect_session(true)

    var peer := ENetMultiplayerPeer.new()
    var result := peer.create_client(address, port)
    if result != OK:
        return result

    multiplayer.multiplayer_peer = peer
    session_mode = &"client"
    current_address = address
    current_port = port
    local_name = player_name
    local_deck = deck_ids
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
    net_match = {}
    last_snapshot = {}
    session_state_changed.emit()
    peers_changed.emit()

    if not silent and was_active and previous_mode != &"singleplayer":
        session_disconnected.emit("Spojení ukončeno.")


func is_session_active() -> bool:
    var peer := multiplayer.multiplayer_peer
    if peer == null:
        return false
    return peer.get_class() != "OfflineMultiplayerPeer"


func is_host() -> bool:
    return session_mode == &"host" and multiplayer.is_server()


func is_client() -> bool:
    return session_mode == &"client" and is_session_active()


func is_in_match() -> bool:
    return not net_match.is_empty()


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


# IPv4 adresy tohoto PC, které má hostitel sdělit soupeři (Radmin VPN = 26.x.x.x první).
static func get_local_ipv4_addresses() -> Array[String]:
    var radmin: Array[String] = []
    var others: Array[String] = []
    for address in IP.get_local_addresses():
        if address.contains(":") or address.begins_with("127.") or address.begins_with("169.254."):
            continue
        if address.begins_with("26."):
            radmin.append(address)
        else:
            others.append(address)
    return radmin + others


func send_snapshot(snapshot: Dictionary) -> void:
    if is_host() and not multiplayer.get_peers().is_empty():
        _rpc_snapshot.rpc(snapshot)


func send_action(action: Dictionary) -> void:
    if is_client():
        _rpc_action.rpc_id(1, action)


func leave_match() -> void:
    if is_session_active():
        _rpc_leave.rpc()
    disconnect_session(true)


func _start_match_as_host(opponent_name: String, opponent_deck: Array) -> void:
    var host_first := randi() % 2 == 0
    net_match = {
        "role": &"host",
        "my_name": local_name,
        "opponent_name": opponent_name,
        "opponent_deck": _to_card_ids(opponent_deck),
        "host_first": host_first,
    }
    _rpc_start.rpc({"opponent_name": local_name, "host_first": host_first})
    match_ready.emit()


@rpc("any_peer", "reliable")
func _rpc_hello(player_name: String, deck_ids: Array, protocol_version: int) -> void:
    if not is_host() or is_in_match():
        return
    var sender := multiplayer.get_remote_sender_id()
    if protocol_version != PROTOCOL_VERSION:
        _reject_peer(sender, "Hostitel má jinou verzi hry (%s, ty %s). Aktualizujte oba na stejnou." % [PROTOCOL_VERSION, protocol_version])
        return
    var deck := _validated_deck(deck_ids)
    if deck.is_empty():
        _reject_peer(sender, "Tvůj balík hostitel nezná nebo nemá přesně %s karet (nejvýš %s kopie). Máte stejnou verzi hry?" % [ProgressionSystem.PVP_DECK_SIZE, ProgressionSystem.PVP_MAX_COPIES])
        return
    _start_match_as_host(player_name.left(24), deck)


@rpc("authority", "reliable")
func _rpc_reject(message: String) -> void:
    disconnect_session(true)
    join_failed.emit(message)


func _reject_peer(peer_id: int, message: String) -> void:
    _rpc_reject.rpc_id(peer_id, message)
    # Odpojení až po doručení zprávy.
    get_tree().create_timer(0.5).timeout.connect(func():
        if multiplayer.multiplayer_peer is ENetMultiplayerPeer and is_host():
            (multiplayer.multiplayer_peer as ENetMultiplayerPeer).disconnect_peer(peer_id))


# Balík od klienta: jen známé karty a povolená velikost, jinak prázdné pole.
func _validated_deck(values: Array) -> Array[StringName]:
    var ids: Array[StringName] = []
    for value in values:
        if typeof(value) != TYPE_STRING and typeof(value) != TYPE_STRING_NAME:
            return []
        if not ResourceLoader.exists("res://data/cards/%s.tres" % String(value)):
            return []
        ids.append(StringName(value))
    if not ProgressionSystem.new().get_deck_problem(ids, true).is_empty():
        return []
    return ids


@rpc("authority", "reliable")
func _rpc_start(config: Dictionary) -> void:
    net_match = {
        "role": &"client",
        "my_name": local_name,
        "opponent_name": str(config.get("opponent_name", "Soupeř")),
        "opponent_deck": [],
        "host_first": bool(config.get("host_first", true)),
    }
    last_snapshot = {}
    match_ready.emit()


@rpc("authority", "reliable")
func _rpc_snapshot(snapshot: Dictionary) -> void:
    last_snapshot = snapshot
    snapshot_received.emit(snapshot)


@rpc("any_peer", "reliable")
func _rpc_action(action: Dictionary) -> void:
    if is_host():
        remote_action_received.emit(action)


@rpc("any_peer", "reliable")
func _rpc_leave() -> void:
    disconnect_session(true)
    session_disconnected.emit("Soupeř odešel ze hry.")


func _to_card_ids(values: Array) -> Array[StringName]:
    var ids: Array[StringName] = []
    for value in values:
        ids.append(StringName(value))
    return ids


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
    if is_host() and is_in_match():
        net_match = {}
        disconnect_session(true)
        session_disconnected.emit("Soupeř se odpojil.")


func _on_connected_to_server() -> void:
    peers_changed.emit()
    join_succeeded.emit()
    _rpc_hello.rpc_id(1, local_name, local_deck.map(func(id): return String(id)), PROTOCOL_VERSION)


func _on_connection_failed() -> void:
    disconnect_session(true)
    join_failed.emit("Nepodařilo se připojit k hostiteli. Zkontroluj IP a firewall.")


func _on_server_disconnected() -> void:
    disconnect_session(true)
    session_disconnected.emit("Spojení s hostitelem se ztratilo.")
