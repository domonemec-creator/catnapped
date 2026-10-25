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
		state.life = 10
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


func _run() -> void:
	var packed_scene := load("res://scenes/card_game/battle_scene.tscn") as PackedScene
	if packed_scene == null:
		_fail("Could not load battle_scene.tscn.")
		return

	var battle = packed_scene.instantiate()
	root.add_child(battle)

	await process_frame
	await process_frame

	battle._dismiss_tutorial_overlay(false)

	var player_state = battle._battle_state.get_player_state(battle.PLAYER_ID)
	var enemy_state = battle._battle_state.get_player_state(battle.ENEMY_ID)
	if player_state == null or enemy_state == null:
		_fail("Missing battle states.")
		return

	_reset_battle_state(battle, player_state, enemy_state)

	var attacker = battle._create_card_instance(&"alley_scrapper", battle.PLAYER_ID)
	var defender = battle._create_card_instance(&"dockside_bruiser", battle.ENEMY_ID)
	if attacker == null or defender == null:
		_fail("Could not create preview cards.")
		return
	attacker.current_attack = 3
	defender.current_life = 4
	_place_card(player_state, attacker, 1, true, false)
	_place_card(enemy_state, defender, 1, false, false)

	battle._handle_player_lane_pressed(1)
	battle._refresh_ui()

	if battle.selected_card_hint.text.find("zbyde 1") < 0:
		_fail("Attack preview did not show the remaining HP result.")
		return
	# Cíl útoku ukazuje výsledek i odvetu přímo na kartě (D-014, Mark nechápal -4 od odvety).
	if not battle._enemy_lanes[1].event_panel.visible or battle._enemy_lanes[1].event_label.text.find("ODVETA") < 0:
		_fail("Occupied attack target should show the result and retaliation on the card.")
		return

	_reset_battle_state(battle, player_state, enemy_state)

	var cat_to_play = battle._create_card_instance(&"alley_scrapper", battle.PLAYER_ID)
	if cat_to_play == null:
		_fail("Could not create hand cat preview card.")
		return
	player_state.hand.append(cat_to_play)

	if not battle._select_hand_card_by_instance_id(cat_to_play.instance_id, false):
		_fail("Could not select the cat card from hand.")
		return

	if battle.selected_card_hint.text.find("Klikni na volnou lajnu.") < 0:
		_fail("Cat play preview did not keep the placement hint.")
		return
	if battle._player_lanes[0].event_panel.visible:
		_fail("Cat play preview should not show a redundant lane banner on an empty slot.")
		return

	_reset_battle_state(battle, player_state, enemy_state)

	var host = battle._create_card_instance(&"alley_scrapper", battle.PLAYER_ID)
	var item = battle._create_card_instance(&"spiked_collar", battle.PLAYER_ID)
	if host == null or item == null:
		_fail("Could not create targeted preview cards.")
		return
	host.current_attack = 3
	_place_card(player_state, host, 0, false, false)
	player_state.hand.append(item)

	if not battle._select_hand_card_by_instance_id(item.instance_id, false):
		_fail("Could not select the item card from hand.")
		return

	if battle.selected_card_hint.text.find("Ty 1: +1 ÚTK -> 4") < 0:
		_fail("Targeted preview did not show the attack buff result.")
		return
	if battle._player_lanes[0].event_panel.visible:
		_fail("Occupied friendly target should keep the preview in the right panel, not paint another banner over the card.")
		return

	_reset_battle_state(battle, player_state, enemy_state)

	player_state.life = 3
	var lethal_attacker = battle._create_card_instance(&"alley_scrapper", battle.ENEMY_ID)
	if lethal_attacker == null:
		_fail("Could not create lethal warning attacker.")
		return
	lethal_attacker.current_attack = 3
	_place_card(enemy_state, lethal_attacker, 0, false, false)

	battle._clear_selection_state()
	battle._refresh_ui()

	if battle.selected_card_hint.text.find("HROZBA") < 0:
		_fail("Idle panel did not show the lethal warning.")
		return
	if battle._enemy_lanes[0].event_panel.visible:
		_fail("Occupied enemy threat lane should not paint another preview banner over the card.")
		return
	if battle._enemy_lanes[0].is_empty_target_highlighted():
		_fail("Occupied enemy threat lane should not keep the empty-slot ring behind the card.")
		return
	if not battle._player_lanes[0].is_empty_target_highlighted():
		_fail("Lethal threat did not mark the open player lane with the ring highlight.")
		return

	_reset_battle_state(battle, player_state, enemy_state)

	player_state.deck.append(battle._create_card_instance(&"alley_scrapper", battle.PLAYER_ID))
	player_state.deck.append(battle._create_card_instance(&"tavern_mouser", battle.PLAYER_ID))
	player_state.discard.append(battle._create_card_instance(&"spiked_collar", battle.PLAYER_ID))
	battle._selected_info_zone = battle.INFO_ZONE_DECK
	battle._refresh_ui()

	if battle.selected_card_title.text.find("Bal") != 0:
		_fail("Deck inspection did not switch the selected panel title.")
		return
	if battle.selected_card_detail.text.count("1x ") < 2:
		_fail("Deck inspection did not list the remaining deck cards.")
		return

	battle._selected_info_zone = battle.INFO_ZONE_DISCARD
	battle._refresh_ui()

	if battle.selected_card_detail.text.count("1x ") < 1:
		_fail("Discard inspection did not list discarded cards.")
		return

	print("Battle preview verification passed.")
	quit()
