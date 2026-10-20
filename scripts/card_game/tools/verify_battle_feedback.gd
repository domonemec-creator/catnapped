extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _reset_battle_state(battle, player_state, enemy_state) -> void:
	for state in [player_state, enemy_state]:
		state.hand.clear()
		state.deck.clear()
		state.discard.clear()
		state.life = 30
		state.tuna_current = 10
		state.tuna_max = 10
		state.saved_tuna_current = 0
		state.table_power_id = StringName()
		state.table_power_used_this_turn = false
		state.immediate_entry_attack_used_this_turn = false
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


func _lane_event_text(lane_view) -> String:
	return lane_view.event_label.text if lane_view.event_panel.visible else ""


func _run() -> void:
	var packed_scene := load("res://scenes/card_game/battle_scene.tscn") as PackedScene
	if packed_scene == null:
		_fail("Could not load battle_scene.tscn.")
		return

	var battle = packed_scene.instantiate()
	root.add_child(battle)

	await process_frame
	await process_frame

	var player_state = battle._battle_state.get_player_state(battle.PLAYER_ID)
	var enemy_state = battle._battle_state.get_player_state(battle.ENEMY_ID)
	if player_state == null or enemy_state == null:
		_fail("Missing battle states.")
		return

	_reset_battle_state(battle, player_state, enemy_state)

	var played_cat = battle._create_card_instance(&"alley_scrapper", battle.PLAYER_ID)
	if played_cat == null:
		_fail("Could not create cat for lane-play feedback test.")
		return
	player_state.hand.append(played_cat)

	battle._play_card_to_lane(player_state, 0, played_cat)
	battle._refresh_ui()

	if player_state.board[0].occupant != played_cat:
		_fail("Lane play did not place the cat onto the board.")
		return
	if battle._player_lanes[0].event_panel.visible:
		_fail("Lane play should not leave a generic VYLOZENO banner behind the placed card.")
		return

	_reset_battle_state(battle, player_state, enemy_state)

	var attacker = battle._create_card_instance(&"alley_scrapper", battle.PLAYER_ID)
	var defender = battle._create_card_instance(&"dockside_bruiser", battle.ENEMY_ID)
	attacker.current_attack = 3
	defender.current_life = 6
	_place_card(player_state, attacker, 1, true, false)
	_place_card(enemy_state, defender, 1, false, false)

	var hit_summary: String = battle._perform_attack(player_state, enemy_state, attacker, 1)
	battle.status_label.text = hit_summary
	battle._refresh_ui()

	if _lane_event_text(battle._player_lanes[1]) != "ÚTOK 3":
		_fail("Attacker lane did not show UTOK 3.")
		return
	if _lane_event_text(battle._enemy_lanes[1]) != "-3 ŽIV":
		_fail("Defender lane did not show -3 ŽIV.")
		return

	_reset_battle_state(battle, player_state, enemy_state)

	var direct_attacker = battle._create_card_instance(&"alley_scrapper", battle.PLAYER_ID)
	direct_attacker.current_attack = 3
	_place_card(player_state, direct_attacker, 0, true, false)

	var direct_summary: String = battle._perform_attack(player_state, enemy_state, direct_attacker, 0)
	battle.status_label.text = direct_summary
	battle._refresh_ui()

	if enemy_state.life != 27:
		_fail("Direct attack did not hit enemy life.")
		return
	if _lane_event_text(battle._enemy_lanes[0]) != "PŘÍMO 3":
		_fail("Direct attack lane did not show PŘÍMO 3.")
		return

	_reset_battle_state(battle, player_state, enemy_state)

	var host = battle._create_card_instance(&"alley_scrapper", battle.PLAYER_ID)
	var item = battle._create_card_instance(&"spiked_collar", battle.PLAYER_ID)
	_place_card(player_state, host, 2, false, false)
	player_state.hand.append(item)

	var item_summary: String = battle._play_targeted_card(player_state, enemy_state, item, host)
	battle.status_label.text = item_summary
	battle._refresh_ui()

	if host.attached_item_instance_id != item.instance_id:
		_fail("Item did not attach to the host.")
		return
	if _lane_event_text(battle._player_lanes[2]).find("ÚTK") < 0:
		_fail("Item target lane did not show an ÚTK feedback banner.")
		return

	print("Battle feedback verification passed.")
	quit()
