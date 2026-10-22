extends SceneTree

# Simulace balík proti balíku pro hru ve dvou (E6, D-025): obě strany hraje stejná AI,
# stejné životy a Síla stolu jako v síťové hře, obě pořadí tahů.
# Balík = id z data/decks (základní počty, bez hrozby) nebo cesta k .txt (řádek: id počet).
# Použití (headless):
#   Godot --headless --path . --script res://scripts/card_game/tools/sim_deck_vs_deck.gd -- <hry_na_pořadí> <balíkA> <balíkB>
#   Godot ... -- <hry_na_pořadí> all      (každý balík z data/decks proti každému)

const CardGameConstants = preload("res://scripts/card_game/data/card_game_constants.gd")
const TURN_CAP := 60
const RNG_SEED := 20261022
const DECKS_DIR := "res://data/decks"

var _packed_scene: PackedScene
var _first_wins_sum := 0.0
var _games_sum := 0
var _second_extra_life := 0  # argument lifeN: druhý na tahu má N životů navíc
var _second_extra_cards := 0  # argument extraN: druhý na tahu má v ruce N karet navíc
var _pvp_rules := true  # argument old: staré životy a Tuny (jako trénink)
var _pad := false  # argument pad: balíky na 30 karet / 3 kopie jako ve hře ve dvou
var _coin_id := StringName()  # argument coin[=id]: druhý na tahu dostane tuhle kartu do ruky


func _init() -> void:
	call_deferred("_run")


# pad: balík jako ve hře ve dvou (D-029) – max 3 kopie, doplněno na 30 nejdřív vlastními kartami.
func _deck_ids(source: String) -> Array[StringName]:
	var ids := _raw_deck_ids(source)
	if not _pad or ids.is_empty():
		return ids
	var p := ProgressionSystem.new()
	var trimmed: Array[StringName] = []
	var own: Array[StringName] = []
	for card_id in ids:
		if trimmed.count(card_id) < p.get_card_copy_limit(card_id, true):
			trimmed.append(card_id)
		if not own.has(card_id):
			own.append(card_id)
	var filled := p.fill_deck_card_ids(trimmed, own, ProgressionSystem.PVP_DECK_SIZE, true)
	return p.fill_deck_card_ids(filled, p.get_all_collectible_card_ids(), ProgressionSystem.PVP_DECK_SIZE, true)


func _raw_deck_ids(source: String) -> Array[StringName]:
	var ids: Array[StringName] = []
	if source.ends_with(".txt"):
		var f := FileAccess.open(source, FileAccess.READ)
		if f == null:
			return ids
		while not f.eof_reached():
			var line := f.get_line().strip_edges()
			if line.is_empty() or line.begins_with("#"):
				continue
			var parts := line.split(" ", false)
			var count := maxi(1, int(parts[1])) if parts.size() > 1 else 1
			for _i in range(count):
				ids.append(StringName(parts[0]))
		return ids
	var deck := load("%s/%s.tres" % [DECKS_DIR, source]) as DeckDefinition
	if deck == null:
		return ids
	for entry in deck.cards:
		for _i in range(entry.count):
			ids.append(entry.card_id)
	return ids


func _other(battle, id: int) -> int:
	return battle.ENEMY_ID if id == battle.PLAYER_ID else battle.PLAYER_ID


# Stejný tah AI jako sim_ai_matches.gd / _run_enemy_stub_turn.
func _drive_turn(battle, acting_id: int, defender_id: int) -> void:
	var bs = battle._battle_state
	var me = bs.get_player_state(acting_id)
	var foe = bs.get_player_state(defender_id)
	var ai = battle._ai_controller
	var rules = battle._battle_rules
	var plays := 0
	while not bs.battle_over and plays < 10:
		var choice: Dictionary = ai.choose_play(me, foe, rules)
		if choice.is_empty():
			break
		var card = choice["card"]
		match str(choice.get("play_type", "lane")):
			"targeted":
				var toid := int(choice.get("target_owner_id", foe.player_id))
				var tlane := int(choice.get("lane_index", -1))
				var tstate = me if toid == me.player_id else foe
				if tlane < 0 or tlane >= tstate.board.size() or tstate.board[tlane].occupant == null:
					break
				battle._play_targeted_card(me, foe, card, tstate.board[tlane].occupant)
			"instant":
				battle._play_targeted_card(me, foe, card, null)
			_:
				var lane := int(choice.get("lane_index", -1))
				if lane < 0:
					break
				battle._play_card_to_lane(me, lane, card)
		plays += 1
	var power = battle._get_table_power_definition(me)
	var pc: Dictionary = ai.choose_table_power(me, foe, power, rules)
	if not pc.is_empty():
		battle._activate_table_power(me, foe, power, int(pc.get("lane_index", -1)))
	var attacks := 0
	while not bs.battle_over and attacks < 12:
		var ac: Dictionary = ai.choose_attack_action(me, foe, rules)
		if ac.is_empty():
			break
		battle._perform_attack(me, foe, ac["attacker"], ac["lane_index"])
		attacks += 1


# Přestaví stranu jako ve hře ve dvou: plné životy, Síla stolu hráče, daný balík, nová ruka.
func _prepare_side(battle, state, ids: Array[StringName]) -> void:
	state.initialize(state.player_id, state.display_name, battle.get_starting_life(), battle.STARTING_TUNA, battle.PLAYER_TABLE_POWER_ID, battle.LANE_COUNT)
	var result: Dictionary = battle._deck_system.build_runtime_deck_from_card_ids(ids, battle._card_library, state.player_id, battle._next_instance_id)
	battle._next_instance_id = int(result["next_instance_id"])
	state.deck = result["cards"]
	battle._deck_system.draw_cards(state, CardGameConstants.starting_hand)


# Vrací {winner: 0 = A, 1 = B, -1 remíza, -2 limit kol, turns}. A sedí na místě hráče.
func _play_one(deck_a: Array[StringName], deck_b: Array[StringName], a_first: bool) -> Dictionary:
	var battle = _packed_scene.instantiate()
	battle.pvp_rules = _pvp_rules
	root.add_child(battle)
	await process_frame
	await process_frame
	var bs = battle._battle_state
	_prepare_side(battle, bs.get_player_state(battle.PLAYER_ID), deck_a)
	_prepare_side(battle, bs.get_player_state(battle.ENEMY_ID), deck_b)
	var first_id: int = battle.PLAYER_ID if a_first else battle.ENEMY_ID
	var second_id: int = _other(battle, first_id)
	bs.get_player_state(first_id).has_started_turn = true
	bs.get_player_state(second_id).has_started_turn = false
	if _coin_id != StringName():
		bs.get_player_state(second_id).hand.append(battle._create_card_instance(_coin_id, second_id))
	if _second_extra_life > 0:
		bs.get_player_state(second_id).life += _second_extra_life
		bs.get_player_state(second_id).max_life += _second_extra_life
	if _second_extra_cards > 0:
		battle._deck_system.draw_cards(bs.get_player_state(second_id), _second_extra_cards)
	bs.active_player_id = first_id
	_drive_turn(battle, first_id, second_id)
	if not bs.battle_over:
		battle._clear_end_of_turn_modifiers(bs.get_player_state(first_id))
	var actor := second_id
	var turns := 0
	while not bs.battle_over and turns < TURN_CAP:
		bs.active_player_id = actor
		battle._start_turn(bs.get_player_state(actor))
		_drive_turn(battle, actor, _other(battle, actor))
		if not bs.battle_over:
			battle._clear_end_of_turn_modifiers(bs.get_player_state(actor))
		actor = _other(battle, actor)
		turns += 1
	var winner := -2
	if bs.battle_over:
		if bs.winner_player_id == battle.PLAYER_ID:
			winner = 0
		elif bs.winner_player_id == battle.ENEMY_ID:
			winner = 1
		else:
			winner = -1
	battle.queue_free()
	await process_frame
	return {"winner": winner, "turns": turns}


# Vrací procento výher balíku A (obě pořadí dohromady).
func _match(name_a: String, name_b: String, games_per: int) -> float:
	var deck_a := _deck_ids(name_a)
	var deck_b := _deck_ids(name_b)
	if deck_a.is_empty() or deck_b.is_empty():
		push_error("Prázdný nebo neznámý balík: %s / %s" % [name_a, name_b])
		return -1.0
	CardGameConstants.stat_cat_attacks = 0
	CardGameConstants.stat_mutual_kills = 0
	var wins_first := 0
	var wins_second := 0
	var turns := 0
	var timeouts := 0
	for a_first in [true, false]:
		for _i in range(games_per):
			var r: Dictionary = await _play_one(deck_a, deck_b, a_first)
			turns += int(r["turns"])
			if int(r["winner"]) == -2:
				timeouts += 1
			elif int(r["winner"]) == 0:
				if a_first:
					wins_first += 1
				else:
					wins_second += 1
	var games := float(games_per * 2)
	_first_wins_sum += 100.0 * float(wins_first + (games_per - wins_second))
	_games_sum += games_per * 2
	var overall := 100.0 * float(wins_first + wins_second) / games
	var mutual := 100.0 * float(CardGameConstants.stat_mutual_kills) / float(maxi(1, CardGameConstants.stat_cat_attacks))
	print("%s,%s,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f" % [name_a, name_b, 100.0 * wins_first / games_per, 100.0 * wins_second / games_per, overall, float(turns) / games, mutual, 100.0 * timeouts / games])
	return overall


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var games_per := 40
	if args.size() > 0:
		games_per = maxi(1, int(args[0]))
	for arg in args.duplicate():
		if String(arg).begins_with("extra"):
			_second_extra_cards = int(String(arg).substr(5))
			args.erase(arg)
		elif arg == "old":
			_pvp_rules = false
		elif arg == "pad":
			_pad = true
			args.erase(arg)
		elif String(arg).begins_with("life"):
			_second_extra_life = int(String(arg).substr(4))
			args.erase(arg)
	for arg in args:
		if String(arg).begins_with("coin"):
			_coin_id = StringName(String(arg).substr(5)) if String(arg).length() > 5 else &"sardine_can"
			args.erase(arg)
			break
	seed(RNG_SEED)
	_packed_scene = load("res://scenes/card_game/battle_scene.tscn") as PackedScene
	var progression := ProgressionSystem.new()
	var original_state := progression.load_state()  # headless = testovací save, battle_scene ho čte
	print("=== BALÍK PROTI BALÍKU (%s her na pořadí, seed %s) ===" % [games_per, RNG_SEED])
	print("# mince pro druhého: %s, karty navíc: %s, životy navíc: %s" % [_coin_id if _coin_id != StringName() else "žádná", _second_extra_cards, _second_extra_life])
	print("deck_a,deck_b,a_first_wr,a_second_wr,a_overall_wr,avg_turns,mutual_kill_pct,timeout_pct")
	if args.size() > 1 and args[1] == "all":
		var names: Array[String] = []
		for file_name in ResourceLoader.list_directory(DECKS_DIR):
			if file_name.ends_with(".tres"):
				names.append(file_name.get_basename())
		names.sort()
		var totals: Dictionary = {}
		for deck_name in names:
			totals[deck_name] = 0.0
		for i in names.size():
			for j in range(i + 1, names.size()):
				var wr := await _match(names[i], names[j], games_per)
				totals[names[i]] += wr
				totals[names[j]] += 100.0 - wr
		print("--- první na tahu vyhrává %.1f %% ---" % (_first_wins_sum / float(maxi(1, _games_sum))))
		print("--- průměr výher proti ostatním ---")
		for deck_name in names:
			print("%s,%.1f" % [deck_name, totals[deck_name] / float(names.size() - 1)])
	elif args.size() > 2:
		await _match(args[1], args[2], games_per)
	else:
		push_error("Použití: -- <hry_na_pořadí> <balíkA> <balíkB> | all")
	progression.save_state(original_state)
	print("=== HOTOVO ===")
	quit()
