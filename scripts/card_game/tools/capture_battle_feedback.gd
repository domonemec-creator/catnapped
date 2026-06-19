extends SceneTree


func _init() -> void:
	call_deferred("_capture")


func _reset_battle_state(battle, player_state, enemy_state) -> void:
	for state in [player_state, enemy_state]:
		state.hand.clear()
		state.deck.clear()
		state.discard.clear()
		state.life = 30
		state.tuna_current = 10
		state.tuna_max = 10
		state.table_power_id = StringName()
		state.table_power_used_this_turn = false
		for slot in state.board:
			slot.occupant = null

	battle._battle_state.battle_over = false
	battle._battle_state.winner_player_id = -1
	battle._battle_state.active_player_id = battle.PLAYER_ID
	battle._clear_selection_state()
	battle._reset_lane_feedback()


func _place_card(state, card, lane_index: int, can_attack: bool = false, has_attacked: bool = false) -> void:
	state.board[lane_index].occupant = card
	card.lane_index = lane_index
	card.can_attack = can_attack
	card.has_attacked = has_attacked


func _capture() -> void:
	var output_path := "user://card_game_battle_feedback.png"
	var user_args := OS.get_cmdline_user_args()
	if not user_args.is_empty():
		output_path = user_args[0]

	root.size = Vector2i(1600, 900)

	var packed_scene := load("res://scenes/card_game/battle_scene.tscn") as PackedScene
	if packed_scene == null:
		push_error("Could not load battle_scene.tscn")
		quit(1)
		return

	var battle = packed_scene.instantiate()
	root.add_child(battle)

	await process_frame
	await process_frame

	var player_state = battle._battle_state.get_player_state(battle.PLAYER_ID)
	var enemy_state = battle._battle_state.get_player_state(battle.ENEMY_ID)
	if player_state == null or enemy_state == null:
		push_error("Missing battle states.")
		quit(1)
		return

	_reset_battle_state(battle, player_state, enemy_state)

	var player_attacker = battle._create_card_instance(&"alley_scrapper", battle.PLAYER_ID)
	var enemy_defender = battle._create_card_instance(&"dockside_bruiser", battle.ENEMY_ID)
	player_attacker.current_attack = 3
	enemy_defender.current_life = 6
	_place_card(player_state, player_attacker, 1, true, false)
	_place_card(enemy_state, enemy_defender, 1, false, false)

	var summary: String = battle._perform_attack(player_state, enemy_state, player_attacker, 1)
	battle.status_label.text = summary
	battle._refresh_ui()

	await process_frame
	await process_frame
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		push_error("Could not capture viewport image")
		quit(1)
		return

	var error := image.save_png(output_path)
	if error != OK:
		push_error("Could not save screenshot to %s" % output_path)
		quit(1)
		return

	print("Saved screenshot to %s" % output_path)
	quit()
