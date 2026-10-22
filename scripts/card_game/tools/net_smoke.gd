extends SceneTree

# Síťový souboj od začátku do konce: dva procesy (host + klient na 127.0.0.1), za oba hraje AI.
#   Godot --headless --path . --script res://scripts/card_game/tools/net_smoke.gd -- host [port]
#   Godot --headless --path . --script res://scripts/card_game/tools/net_smoke.gd -- client [port]
# Na konci vypíše „NET RESULT ...“; výsledek hosta a klienta musí sedět (otočeně).
# Volitelně 3. argument = cesta PNG: screenshot ve 3. kole (spouštět S oknem, ne --headless).

const AiController = preload("res://scripts/card_game/systems/ai_controller.gd")
const BATTLE_SCENE := "res://scenes/card_game/battle_scene.tscn"
const TIMEOUT_MSEC := 150000
const ACTION_WAIT_MSEC := 3000

var _ai := AiController.new()
var _role := "host"
var _busy := false
var _shot_taken := false


var _seen_enemy_plays := {}  # karty soupeře ukázané v pravém panelu


# Kdo spadne při NET_DROP (env NET_DROP_ROLE, výchozí klient).
func _drop_role() -> String:
	var role := OS.get_environment("NET_DROP_ROLE")
	return role if role != "" else "client"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_role = args[0] if args.size() > 0 else "host"
	var port := int(args[1]) if args.size() > 1 else 7031
	var mm := root.get_node("MultiplayerManager")
	# Jen čtení: v okně by reset_state() přepsal skutečný save hráče.
	var deck := ProgressionSystem.new().get_player_deck_card_ids(ProgressionSystem.new().load_state())
	var result: Error
	if _role == "host":
		result = mm.host_session(port, "Host", deck)
	else:
		result = mm.join_session("127.0.0.1", port, "Klient", deck)
	if result != OK:
		_finish("NET FAIL nelze otevřít spojení (%s)" % result, 1)
		return

	var start := Time.get_ticks_msec()
	while not mm.is_in_match():
		if Time.get_ticks_msec() - start > 20000:
			_finish("NET FAIL soupeř se nepřipojil", 1)
			return
		await process_frame

	var battle = (load(BATTLE_SCENE) as PackedScene).instantiate()
	root.add_child(battle)
	current_scene = battle
	# NET_REMATCH=1: po prvním zápase odveta (klient požádá, host spustí) a hraje se znovu.
	var games_left := 2 if OS.get_environment("NET_REMATCH") != "" else 1
	while Time.get_ticks_msec() - start < TIMEOUT_MSEC * games_left:
		await process_frame
		var state = battle._battle_state
		if state == null:
			continue
		# NET_DROP=N: hráč (NET_DROP_ROLE, výchozí klient) v N. kole tvrdě skončí (jako pád hry), druhý musí zápas ukončit sám.
		if _role == _drop_role() and OS.get_environment("NET_DROP") != "" and state.turn_number >= int(OS.get_environment("NET_DROP")):
			print("NET DROP %s spadl v kole %s" % [_role, state.turn_number])
			OS.kill(OS.get_process_id())
		if battle._enemy_last_played != null:
			_seen_enemy_plays[battle._enemy_last_played.instance_id] = true
		if state.battle_over:
			if games_left <= 1:
				break
			if not _busy:
				_busy = true
				print("NET GAME1 role=%s vítěz=%s" % [_role, state.winner_player_id])
				await create_timer(0.5).timeout
				if _role == "client":
					battle._on_rematch_button_pressed()
					var waited_client := 0
					while battle._battle_state.battle_over and waited_client < 600:
						await process_frame
						waited_client += 1
					print("NET REMATCH klient nový stůl=%s" % (not battle._battle_state.battle_over))
				else:
					var waited := 0
					while battle.post_match_rematch_button.text != "Odveta (soupeř chce)" and waited < 300:
						await process_frame
						waited += 1
					var old_battle = battle
					battle._on_rematch_button_pressed()
					while current_scene == old_battle or current_scene == null or not is_instance_valid(current_scene):
						await process_frame
					battle = current_scene
					while battle._battle_state == null:
						await process_frame
					print("NET REMATCH host nová scéna=%s konec=%s kolo=%s" % [battle != old_battle, battle._battle_state.battle_over, battle._battle_state.turn_number])
				games_left -= 1
				_busy = false
			continue
		if _busy or state.active_player_id != battle.PLAYER_ID or battle._enemy_turn_running:
			continue
		_busy = true
		if args.size() > 2 and state.turn_number >= 3 and not _shot_taken:
			_shot_taken = true
			root.size = Vector2i(1600, 900)
			await create_timer(0.6).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(args[2])
		if OS.get_environment("NET_TRACE") != "":
			var a = state.get_player_state(battle.PLAYER_ID)
			var b = state.get_player_state(battle.ENEMY_ID)
			print("TRACE %s kolo %s | já %s ŽIV ruka %s balík %s Tuna %s/%s stůl %s | soupeř %s ŽIV ruka %s balík %s stůl %s" % [_role, state.turn_number, a.life, a.hand.size(), a.deck.size(), a.tuna_current, a.tuna_max, a.board.filter(func(x): return x.occupant != null).size(), b.life, b.hand.size(), b.deck.size(), b.board.filter(func(x): return x.occupant != null).size()])
		await _auto_turn(battle)
		if not battle._battle_state.battle_over:
			battle._on_end_turn_pressed()
		# Host po konci tahu čeká na tah klienta; klient čeká na snímek s tahem hosta.
		await create_timer(0.2).timeout
		_busy = false

	var final_state = battle._battle_state
	if final_state == null or not final_state.battle_over:
		_finish("NET FAIL souboj neskončil včas (%s)" % _role, 1)
		return
	if OS.get_environment("NET_DROP") != "":
		print("NET DROP %s stav=\"%s\" overlay=%s" % [_role, battle.status_label.text, battle.post_match_overlay.visible])
	var me = final_state.get_player_state(battle.PLAYER_ID)
	var opponent = final_state.get_player_state(battle.ENEMY_ID)
	var winner: String = "remíza" if final_state.winner_player_id < 0 else (me.display_name if final_state.winner_player_id == battle.PLAYER_ID else opponent.display_name)
	await create_timer(0.5).timeout
	_finish("NET RESULT role=%s vítěz=%s %s=%s %s=%s kolo=%s panel_soupeře=%s" % [_role, winner, me.display_name, me.life, opponent.display_name, opponent.life, final_state.turn_number, _seen_enemy_plays.size()], 0)


# Jeden tah za hráče dole (stejná AI jako soupeř v tréninku). Na klientovi akce odcházejí
# hostovi, proto se po každé čeká na nový snímek stavu.
func _auto_turn(battle) -> void:
	for _i in 10:
		var me = battle._battle_state.get_player_state(battle.PLAYER_ID)
		var opponent = battle._battle_state.get_player_state(battle.ENEMY_ID)
		var choice: Dictionary = _ai.choose_play(me, opponent, battle._battle_rules)
		if choice.is_empty() or battle._battle_state.battle_over:
			break
		var card = choice["card"]
		match str(choice.get("play_type", "lane")):
			"targeted":
				var own: bool = int(choice.get("target_owner_id", opponent.player_id)) == me.player_id
				var target_state = me if own else opponent
				var target = target_state.board[int(choice.get("lane_index", 0))].occupant
				if target == null:
					break
				battle._play_targeted_card(me, opponent, card, target)
			"instant":
				break
			_:
				battle._play_card_to_lane(me, int(choice.get("lane_index", 0)), card)
		battle._refresh_ui()
		if not await _wait_for_sync(battle):
			break
	for _i in 12:
		var me = battle._battle_state.get_player_state(battle.PLAYER_ID)
		var opponent = battle._battle_state.get_player_state(battle.ENEMY_ID)
		var attack: Dictionary = _ai.choose_attack_action(me, opponent, battle._battle_rules)
		if attack.is_empty() or battle._battle_state.battle_over:
			break
		battle._perform_attack(me, opponent, attack["attacker"], int(attack["lane_index"]))
		battle._refresh_ui()
		if not await _wait_for_sync(battle):
			break


# Host: stav se mění hned. Klient: počká na snímek (false = host akci odmítl / nic se nezměnilo).
func _wait_for_sync(battle) -> bool:
	if _role == "host":
		await process_frame
		return true
	var before: int = battle._net.snapshot_count
	var start := Time.get_ticks_msec()
	while battle._net.snapshot_count == before:
		if Time.get_ticks_msec() - start > ACTION_WAIT_MSEC:
			return false
		await process_frame
	return true


func _finish(message: String, code: int) -> void:
	print(message)
	var mm := root.get_node("MultiplayerManager")
	mm.disconnect_session(true)
	quit(code)
