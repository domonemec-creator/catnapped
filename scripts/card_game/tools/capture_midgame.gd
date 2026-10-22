extends SceneTree

# Screenshot rozehrané hry: skrytý tutorial, karty na obou stranách stolu a v ruce.
# Spouštět S oknem (ne --headless):
#   Godot --path . --script res://scripts/card_game/tools/capture_midgame.gd -- "<abs cesta>.png"


func _init() -> void:
	call_deferred("_capture")


func _place_card(state, card, lane_index: int, can_attack: bool, has_attacked: bool) -> void:
	state.board[lane_index].occupant = card
	card.lane_index = lane_index
	card.can_attack = can_attack
	card.has_attacked = has_attacked


func _capture() -> void:
	var output_path := "user://card_game_midgame.png"
	var user_args := OS.get_cmdline_user_args()
	if not user_args.is_empty():
		output_path = user_args[0]
	root.size = Vector2i(1600, 900)

	var battle = (load("res://scenes/card_game/battle_scene.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await process_frame
	await process_frame

	# Tutorial schovat bez zápisu do save.
	battle._dismiss_tutorial_overlay(false)

	var player_state = battle._battle_state.get_player_state(battle.PLAYER_ID)
	var enemy_state = battle._battle_state.get_player_state(battle.ENEMY_ID)
	for state in [player_state, enemy_state]:
		state.hand.clear()
		state.saved_tuna_current = 0
		for slot in state.board:
			slot.occupant = null
	player_state.life = 7
	enemy_state.life = 5
	player_state.tuna_max = 4
	player_state.tuna_current = 3

	_place_card(player_state, battle._create_card_instance(&"alley_scrapper", battle.PLAYER_ID), 0, true, false)
	var fresh_cat = battle._create_card_instance(&"boilerback_guardian", battle.PLAYER_ID)
	fresh_cat.entered_this_turn = true
	_place_card(player_state, fresh_cat, 2, false, false)
	_place_card(enemy_state, battle._create_card_instance(&"dockside_bruiser", battle.ENEMY_ID), 0, false, true)
	_place_card(enemy_state, battle._create_card_instance(&"rafter_pouncer", battle.ENEMY_ID), 1, false, true)

	# Volitelně 2. argument: karty do ruky oddělené čárkou (kontrola nového artu).
	var hand_ids: Array = [&"candlepaw_scout", &"dock_harpooner", &"netclaw_raider", &"grey_veteran", &"pickpocket"]
	var hand_args := OS.get_cmdline_user_args()
	if hand_args.size() > 1:
		hand_ids = Array(hand_args[1].split(",", false)).map(func(id): return StringName(id))
	for card_id in hand_ids:
		player_state.hand.append(battle._create_card_instance(card_id, battle.PLAYER_ID))

	battle._battle_state.active_player_id = battle.PLAYER_ID
	battle._clear_selection_state()
	battle._refresh_ui()

	if not await _save(output_path):
		return

	# Druhý snímek: vybraná karta z ruky (pravý panel + highlight lajn).
	battle._select_hand_card_by_instance_id(player_state.hand[2].instance_id, false)
	battle._refresh_ui()
	if not await _save(output_path.get_basename() + "_selected.png"):
		return

	# Třetí snímek: nic nevybráno, myš nad soupeřovou kočkou (náhled v pravém panelu).
	battle._clear_selection_state()
	battle._on_card_hovered(enemy_state.board[0].occupant)
	battle._refresh_ui()
	if not await _save(output_path.get_basename() + "_hover.png"):
		return
	quit()


func _save(path: String) -> bool:
	await process_frame
	await process_frame
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.save_png(path) != OK:
		push_error("Could not save screenshot to %s" % path)
		quit(1)
		return false
	print("Saved screenshot to %s" % path)
	return true
