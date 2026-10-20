extends SceneTree

# Ověření tempa tahu soupeře v okně (ne --headless): ukončí tah a vyfotí průběh.
#   Godot --path . --script res://scripts/card_game/tools/capture_enemy_turn.gd -- "<abs cesta bez přípony>"
# Výstup: <cesta>_1.png … _4.png, na konci vypíše, jestli tah doběhl a hráč je znovu na tahu.


func _init() -> void:
	call_deferred("_run")


func _place(state, card, lane_index: int) -> void:
	state.board[lane_index].occupant = card
	card.lane_index = lane_index
	card.can_attack = true
	card.has_attacked = false


func _run() -> void:
	var base_path := "user://enemy_turn"
	var user_args := OS.get_cmdline_user_args()
	if not user_args.is_empty():
		base_path = user_args[0]
	root.size = Vector2i(1600, 900)

	var battle = (load("res://scenes/card_game/battle_scene.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await process_frame
	await process_frame
	battle._dismiss_tutorial_overlay(false)

	var player_state = battle._battle_state.get_player_state(battle.PLAYER_ID)
	var enemy_state = battle._battle_state.get_player_state(battle.ENEMY_ID)
	for slot in player_state.board:
		slot.occupant = null
	for slot in enemy_state.board:
		slot.occupant = null
	player_state.life = 12
	enemy_state.life = 12
	_place(player_state, battle._create_card_instance(&"tavern_mouser", battle.PLAYER_ID), 1)
	_place(enemy_state, battle._create_card_instance(&"dockside_bruiser", battle.ENEMY_ID), 1)
	_place(enemy_state, battle._create_card_instance(&"alley_scrapper", battle.ENEMY_ID), 2)
	battle._refresh_ui()
	await process_frame

	battle._on_end_turn_pressed()
	var shot_times := [0.45, 0.85, 1.6, 2.4]
	var elapsed := 0.0
	for i in range(shot_times.size()):
		await create_timer(shot_times[i] - elapsed).timeout
		elapsed = shot_times[i]
		await RenderingServer.frame_post_draw
		var path := "%s_%s.png" % [base_path, i + 1]
		root.get_texture().get_image().save_png(path)
		print("Saved %s (running=%s)" % [path, battle._enemy_turn_running])

	# Počkat na doběhnutí tahu.
	var waited := 0.0
	while battle._enemy_turn_running and waited < 15.0:
		await create_timer(0.25).timeout
		waited += 0.25
	print("Enemy turn finished=%s active_player=%s player_life=%s" % [not battle._enemy_turn_running, battle._battle_state.active_player_id, player_state.life])
	quit()
