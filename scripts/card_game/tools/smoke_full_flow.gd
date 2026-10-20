extends SceneTree

# Kouřový test v okně: menu → run → souboj → hráč (AI) a soupeř se střídají, dokud zápas neskončí.
# Hlídá, že se tahy dokončují (žádné uvíznutí coroutine) a zápas skončí. Save obnoví.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1600, 900)
	var progression = load("res://scripts/card_game/systems/progression_system.gd").new()
	var original_state: Dictionary = progression.load_state()
	change_scene_to_file("res://scenes/card_game/encounter_select.tscn")
	await create_timer(0.5).timeout
	current_scene._start_run()
	await create_timer(1.0).timeout
	var battle = current_scene
	if battle == null or not battle.has_method("_on_end_turn_pressed"):
		push_error("SMOKE: battle scene did not open")
		_finish(progression, original_state, 1)
		return
	battle._dismiss_tutorial_overlay(false)
	var ai = battle._ai_controller
	var rules = battle._battle_rules
	var turns := 0
	while not battle._battle_state.battle_over and turns < 40:
		var me = battle._battle_state.get_player_state(battle.PLAYER_ID)
		var foe = battle._battle_state.get_player_state(battle.ENEMY_ID)
		# Hráčův tah řídí stejná AI přes funkce controlleru.
		for _i in range(6):
			var choice: Dictionary = ai.choose_play(me, foe, rules)
			if choice.is_empty() or str(choice.get("play_type", "lane")) != "lane":
				break
			battle._play_card_to_lane(me, int(choice["lane_index"]), choice["card"])
			battle._refresh_ui()
			await create_timer(0.15).timeout
		for _i in range(4):
			var attack: Dictionary = ai.choose_attack_action(me, foe, rules)
			if attack.is_empty() or battle._battle_state.battle_over:
				break
			battle._perform_attack(me, foe, attack["attacker"], attack["lane_index"])
			battle._refresh_ui()
			await create_timer(0.15).timeout
		if battle._battle_state.battle_over:
			break
		battle._on_end_turn_pressed()
		var waited := 0.0
		while battle._enemy_turn_running and waited < 20.0:
			await create_timer(0.25).timeout
			waited += 0.25
		if battle._enemy_turn_running:
			push_error("SMOKE: enemy turn stuck")
			_finish(progression, original_state, 1)
			return
		turns += 1
	print("SMOKE: battle_over=%s winner=%s turns=%s player_life=%s enemy_life=%s" % [battle._battle_state.battle_over, battle._battle_state.winner_player_id, turns, battle._battle_state.get_player_state(0).life, battle._battle_state.get_player_state(1).life])
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://smoke_end.png")
	_finish(progression, original_state, 0 if battle._battle_state.battle_over else 1)


func _finish(progression, original_state: Dictionary, code: int) -> void:
	progression.save_state(original_state)
	var run_session = root.get_node_or_null("RunSession")
	if run_session != null:
		run_session.end_run()
	quit(code)
