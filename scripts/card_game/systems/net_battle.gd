extends RefCounted

# Souboj 1v1 po síti (D4). Host simuluje celý souboj (on = PLAYER_ID, klient = ENEMY_ID),
# po každé změně pošle snímek stavu. Klient snímek přečte otočeně (sám sebe vidí dole)
# a místo provedení akce ji pošle hostovi. Viz D-024.

signal remote_turn_finished
signal rematch_requested

const BattleState = preload("res://scripts/card_game/runtime/battle_state.gd")
const CardInstance = preload("res://scripts/card_game/runtime/card_instance.gd")
const PlayerBattleState = preload("res://scripts/card_game/runtime/player_battle_state.gd")

const HIDDEN_CARD_ID := &"stray_token"
const PLAYER_ID := 0
const ENEMY_ID := 1

var role: StringName = &""
var config: Dictionary = {}
var snapshot_count := 0
var _battle  # battle_controller.gd (bez typu kvůli cyklickému preloadu)
var _snapshot_queued := false
var _last_snapshot_hash := 0
# Efekty a zvuky od posledního snímku (host je pošle, klient je přehraje).
var _events: Array = []
const UNSHARED_SFX: Array[StringName] = [&"victory", &"defeat"]
var _remote_turn_active := false


func setup(battle, match_config: Dictionary) -> void:
	_battle = battle
	config = match_config
	role = config.get("role", &"")
	var manager := _manager()
	if is_host():
		manager.remote_action_received.connect(_on_remote_action)
	else:
		manager.snapshot_received.connect(_on_snapshot)


func is_host() -> bool:
	return role == &"host"


func is_client() -> bool:
	return role == &"client"


func get_opponent_name() -> String:
	return str(config.get("opponent_name", "Soupeř"))


func get_my_name() -> String:
	return str(config.get("my_name", "Hráč"))


func get_opponent_deck() -> Array[StringName]:
	var ids: Array[StringName] = []
	for card_id in config.get("opponent_deck", []):
		ids.append(StringName(card_id))
	return ids


func host_goes_first() -> bool:
	return bool(config.get("host_first", true))


func disconnect_signals() -> void:
	var manager := _manager()
	if manager == null:
		return
	if manager.remote_action_received.is_connected(_on_remote_action):
		manager.remote_action_received.disconnect(_on_remote_action)
	if manager.snapshot_received.is_connected(_on_snapshot):
		manager.snapshot_received.disconnect(_on_snapshot)


# --- Host ---------------------------------------------------------------------------

# Odeslání snímku nejvýš jednou za snímek obrazovky (refresh UI se volá často).
func queue_snapshot() -> void:
	if not is_host() or _snapshot_queued:
		return
	_snapshot_queued = true
	_send_snapshot.call_deferred()


func _send_snapshot() -> void:
	_snapshot_queued = false
	if not is_instance_valid(_battle) or _battle._battle_state == null:
		return
	var snapshot := serialize_state(_battle._battle_state, PLAYER_ID)
	snapshot["status"] = _battle.status_label.text
	var snapshot_hash := snapshot.hash()
	if snapshot_hash == _last_snapshot_hash and _events.is_empty():
		return
	_last_snapshot_hash = snapshot_hash
	snapshot["events"] = _events
	_events = []
	_manager().send_snapshot(snapshot)


func record_fx(owner_id: int, lane_index: int, method: StringName, args: Array, art_path: String) -> void:
	if not is_host():
		return
	var safe_args: Array = []
	for arg in args:
		safe_args.append(arg if typeof(arg) in [TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_BOOL] else null)
	_events.append({"k": "fx", "owner": _swap(owner_id), "lane": lane_index, "m": method, "a": safe_args, "art": art_path})
	queue_snapshot()


func record_sfx(sound_id: StringName) -> void:
	if is_host() and not UNSHARED_SFX.has(sound_id):
		_events.append({"k": "sfx", "id": sound_id})


# Tah klienta: host čeká, dokud klient nepošle konec tahu (nebo souboj neskončí).
func run_remote_turn() -> void:
	_remote_turn_active = true
	queue_snapshot()
	await remote_turn_finished
	_remote_turn_active = false


func _on_remote_action(action: Dictionary) -> void:
	if str(action.get("type", "")) == "rematch":
		rematch_requested.emit()
		return
	if not _remote_turn_active or _battle == null or _battle._battle_state == null:
		push_warning("Síť: akce mimo tah soupeře zahozena: %s" % action)
		return
	var state: BattleState = _battle._battle_state
	if state.battle_over:
		remote_turn_finished.emit()
		return
	var me: PlayerBattleState = state.get_player_state(ENEMY_ID)
	var opponent: PlayerBattleState = state.get_player_state(PLAYER_ID)
	var summary := ""
	match str(action.get("type", "")):
		"play_lane":
			var card := _find_in_hand(me, int(action.get("card", -1)))
			var lane := int(action.get("lane", -1))
			if card != null and _battle._battle_rules.get_valid_play_lanes(card, me).has(lane):
				_battle._play_card_to_lane(me, lane, card)
				summary = "%s vykládá %s do lajny %s." % [me.display_name, card.definition.display_name, lane + 1]
		"play_target":
			var card := _find_in_hand(me, int(action.get("card", -1)))
			var target_state: PlayerBattleState = me if bool(action.get("own", false)) else opponent
			var lane := int(action.get("lane", -1))
			if card != null and lane >= 0 and lane < target_state.board.size():
				var target: CardInstance = target_state.board[lane].occupant
				if target != null and _battle._can_play_card_from_hand(card, me, opponent) and _battle._is_valid_card_target(card, target, target_state.player_id, me, opponent):
					summary = _battle._play_targeted_card(me, opponent, card, target)
		"play_instant":
			var card := _find_in_hand(me, int(action.get("card", -1)))
			if card != null and not _battle._card_requires_board_target(card) and _battle._can_play_card_from_hand(card, me, opponent):
				summary = _battle._play_targeted_card(me, opponent, card, null)
		"attack":
			var from_lane := int(action.get("from", -1))
			if from_lane >= 0 and from_lane < me.board.size():
				var attacker: CardInstance = me.board[from_lane].occupant
				if attacker != null and attacker.can_attack and not attacker.has_attacked:
					summary = _battle._perform_attack(me, opponent, attacker, int(action.get("lane", -1)))
		"power":
			summary = _battle._activate_table_power(me, opponent, _battle._get_table_power_definition(me), int(action.get("lane", -1)))
		"end_turn":
			remote_turn_finished.emit()
			return
	if summary.is_empty():
		push_warning("Síť: host odmítl akci %s (tah %s, aktivní %s, Tuna %s, ruka %s)." % [action, state.turn_number, state.active_player_id, me.tuna_current, me.hand.map(func(c): return "%s:%s" % [c.instance_id, c.definition.cost])])
	else:
		_battle.status_label.text = summary
	_battle._refresh_ui()
	if state.battle_over:
		remote_turn_finished.emit()


func _find_in_hand(player_state: PlayerBattleState, instance_id: int) -> CardInstance:
	for card in player_state.hand:
		if card.instance_id == instance_id:
			return card
	return null


# --- Klient -------------------------------------------------------------------------

# Akce hráče na klientovi: místo provedení se pošle hostovi. Vrací true, když se odeslala.
func intercept(owner_state: PlayerBattleState, action: Dictionary) -> bool:
	if not is_client() or owner_state == null or owner_state.player_id != PLAYER_ID:
		return false
	_manager().send_action(action)
	return true


func _on_snapshot(snapshot: Dictionary) -> void:
	if _battle == null or not is_instance_valid(_battle):
		return
	snapshot_count += 1
	_battle._apply_net_snapshot(deserialize_state(snapshot, _battle._card_library), str(snapshot.get("status", "")))
	_battle._replay_net_events(snapshot.get("events", []))


# --- Snímek stavu -------------------------------------------------------------------

# Klient vidí stav otočeně: host je pro něj soupeř (ENEMY_ID), on sám PLAYER_ID.
# hidden_player_id: hráč, jehož ruka a balík se pošlou jen jako počet (klient nemá vidět karty hosta).
static func serialize_state(state: BattleState, hidden_player_id: int = -1) -> Dictionary:
	var players: Array = []
	for player_state in state.player_states:
		players.append(_serialize_player(player_state, player_state.player_id == hidden_player_id))
	return {
		"turn": state.turn_number,
		"active": _swap(state.active_player_id),
		"priority": _swap(state.priority_player_id),
		"over": state.battle_over,
		"winner": _swap(state.winner_player_id),
		"players": players,
	}


static func deserialize_state(data: Dictionary, card_library: Dictionary) -> BattleState:
	var state := BattleState.new()
	state.turn_number = int(data.get("turn", 1))
	state.active_player_id = int(data.get("active", PLAYER_ID))
	state.priority_player_id = int(data.get("priority", PLAYER_ID))
	state.battle_over = bool(data.get("over", false))
	state.winner_player_id = int(data.get("winner", -1))
	var players: Array[PlayerBattleState] = []
	for player_data in data.get("players", []):
		players.append(_deserialize_player(player_data, card_library))
	players.sort_custom(func(a, b): return a.player_id < b.player_id)
	state.player_states = players
	return state


static func _swap(player_id: int) -> int:
	if player_id == PLAYER_ID:
		return ENEMY_ID
	if player_id == ENEMY_ID:
		return PLAYER_ID
	return player_id


static func _serialize_player(player_state: PlayerBattleState, hide_cards: bool = false) -> Dictionary:
	var board: Array = []
	for slot in player_state.board:
		board.append(_serialize_card(slot.occupant) if slot.occupant != null else {})
	return {
		"id": _swap(player_state.player_id),
		"name": player_state.display_name,
		"life": player_state.life,
		"max_life": player_state.max_life,
		"tuna": player_state.tuna_current,
		"tuna_max": player_state.tuna_max,
		"saved_tuna": player_state.saved_tuna_current,
		"deck": _serialize_cards(player_state.deck, hide_cards),
		"hand": _serialize_cards(player_state.hand, hide_cards),
		"discard": _serialize_cards(player_state.discard),
		"board": board,
		"power": player_state.table_power_id,
		"power_used": player_state.table_power_used_this_turn,
		"entry_used": player_state.immediate_entry_attack_used_this_turn,
		"started": player_state.has_started_turn,
		"hunger": player_state.hunger_count,
	}


static func _deserialize_player(data: Dictionary, card_library: Dictionary) -> PlayerBattleState:
	var player_state := PlayerBattleState.new()
	var board_data: Array = data.get("board", [])
	player_state.initialize(int(data.get("id", 0)), str(data.get("name", "")), int(data.get("max_life", 10)), 0, StringName(data.get("power", "")), board_data.size())
	player_state.life = int(data.get("life", 10))
	player_state.tuna_current = int(data.get("tuna", 0))
	player_state.tuna_max = int(data.get("tuna_max", 0))
	player_state.saved_tuna_current = int(data.get("saved_tuna", 0))
	player_state.table_power_used_this_turn = bool(data.get("power_used", false))
	player_state.immediate_entry_attack_used_this_turn = bool(data.get("entry_used", false))
	player_state.has_started_turn = bool(data.get("started", false))
	player_state.hunger_count = int(data.get("hunger", 0))
	for pile in ["deck", "hand", "discard"]:
		var cards: Array[CardInstance] = []
		for card_data in data.get(pile, []):
			var card := _deserialize_card(card_data, card_library)
			if card != null:
				cards.append(card)
		match pile:
			"deck":
				player_state.deck = cards
			"hand":
				player_state.hand = cards
			"discard":
				player_state.discard = cards
	for lane_index in board_data.size():
		var card_data: Dictionary = board_data[lane_index]
		if not card_data.is_empty():
			player_state.board[lane_index].occupant = _deserialize_card(card_data, card_library)
	return player_state


static func _serialize_card(card: CardInstance) -> Dictionary:
	if card == null or card.definition == null:
		return {}
	var data := {
		"iid": card.instance_id,
		"cid": card.definition.id,
		"owner": _swap(card.owner_id),
		"atk": card.current_attack,
		"hp": card.current_life,
		"lane": card.lane_index,
		"can_attack": card.can_attack,
		"attacked": card.has_attacked,
		"entered": card.entered_this_turn,
		"entry_attack": card.immediate_entry_attack_granted,
		"tmp_kw": card.temporary_keywords,
		"granted_kw": card.granted_keywords,
		"tmp_atk": card.temporary_attack_bonus,
		"tmp_hp": card.temporary_life_bonus,
	}
	if card.attached_item != null:
		data["item"] = _serialize_card(card.attached_item)
	return data


static func _deserialize_card(data: Dictionary, card_library: Dictionary) -> CardInstance:
	if data.is_empty():
		return null
	var definition = card_library.get(StringName(data.get("cid", "")))
	if definition == null:
		push_warning("Síť: neznámá karta %s." % data.get("cid", ""))
		return null
	var card := CardInstance.new()
	card.instance_id = int(data.get("iid", -1))
	card.definition = definition
	card.owner_id = int(data.get("owner", -1))
	card.current_attack = int(data.get("atk", 0))
	card.current_life = int(data.get("hp", 0))
	card.lane_index = int(data.get("lane", -1))
	card.can_attack = bool(data.get("can_attack", false))
	card.has_attacked = bool(data.get("attacked", false))
	card.entered_this_turn = bool(data.get("entered", false))
	card.immediate_entry_attack_granted = bool(data.get("entry_attack", false))
	for keyword in data.get("tmp_kw", []):
		card.temporary_keywords.append(StringName(keyword))
	for keyword in data.get("granted_kw", []):
		card.granted_keywords.append(StringName(keyword))
	card.temporary_attack_bonus = int(data.get("tmp_atk", 0))
	card.temporary_life_bonus = int(data.get("tmp_hp", 0))
	var item_data: Dictionary = data.get("item", {})
	if not item_data.is_empty():
		card.attached_item = _deserialize_card(item_data, card_library)
		if card.attached_item != null:
			card.attached_item_instance_id = card.attached_item.instance_id
	return card


func _manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("MultiplayerManager") if tree != null else null


static func _serialize_cards(cards: Array[CardInstance], hide_cards: bool = false) -> Array:
	var result: Array = []
	for card in cards:
		var data := _serialize_card(card)
		if hide_cards and not data.is_empty():
			# Skrytá karta: jen rub (Tulák jako zástupná definice), zachová počet.
			data = {"iid": data["iid"], "cid": HIDDEN_CARD_ID, "owner": data["owner"]}
		result.append(data)
	return result
