extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _run() -> void:
	root.size = Vector2i(1600, 900)

	var packed_scene := load("res://scenes/card_game/battle_scene.tscn") as PackedScene
	if packed_scene == null:
		_fail("Could not load battle_scene.tscn.")
		return

	var battle = packed_scene.instantiate()
	root.add_child(battle)

	await process_frame
	await process_frame

	if battle.hand_row.get_child_count() <= 0:
		_fail("Hand row did not create any visible card views.")
		return

	var hand_panel = battle.get_node("Margin/Layout/TopRow/BoardColumn/HandPanel") as Control
	if hand_panel == null:
		_fail("Could not locate HandPanel.")
		return

	var hand_panel_rect := hand_panel.get_global_rect()
	var hand_panel_bottom := hand_panel_rect.position.y + hand_panel_rect.size.y
	if hand_panel_bottom > root.size.y - 8:
		_fail("Hand panel is pushed below the viewport.")
		return

	var first_card = battle.hand_row.get_child(0) as Control
	if first_card == null:
		_fail("Hand row did not expose the first card control.")
		return

	var first_card_rect := first_card.get_global_rect()
	var first_card_bottom := first_card_rect.position.y + first_card_rect.size.y
	if first_card_bottom > root.size.y - 8:
		_fail("First hand card is pushed below the viewport.")
		return

	var player_state = battle._battle_state.get_player_state(battle.PLAYER_ID)
	var enemy_state = battle._battle_state.get_player_state(battle.ENEMY_ID)
	if player_state == null or enemy_state == null:
		_fail("Missing battle states.")
		return

	for slot in player_state.board:
		slot.occupant = null
	for slot in enemy_state.board:
		slot.occupant = null
	player_state.life = 3
	battle._clear_selection_state()
	battle._reset_lane_feedback()

	var threat_a = battle._create_card_instance(&"alley_scrapper", battle.ENEMY_ID)
	var threat_b = battle._create_card_instance(&"dockside_bruiser", battle.ENEMY_ID)
	if threat_a == null or threat_b == null:
		_fail("Could not create enemy threat cards for layout verification.")
		return

	enemy_state.board[0].occupant = threat_a
	threat_a.lane_index = 0
	threat_a.can_attack = false
	threat_a.has_attacked = false
	enemy_state.board[2].occupant = threat_b
	threat_b.lane_index = 2
	threat_b.can_attack = false
	threat_b.has_attacked = false

	battle._refresh_ui()

	await process_frame
	await process_frame

	var info_panel = battle.get_node("Margin/Layout/TopRow/SelectedPanel/Content/BottomZone/InfoPanel") as Control
	var table_power_button = battle.table_power_button as Control
	var end_turn_button = battle.end_turn_button as Control
	if info_panel == null or table_power_button == null or end_turn_button == null:
		_fail("Could not locate selected-panel controls for layout verification.")
		return

	var info_panel_rect := info_panel.get_global_rect()
	var table_power_button_rect := table_power_button.get_global_rect()
	var end_turn_button_rect := end_turn_button.get_global_rect()
	var info_panel_bottom := info_panel_rect.position.y + info_panel_rect.size.y
	# Bez Síly stolu je její tlačítko skryté; hlídá se první viditelné tlačítko.
	var first_button_top := table_power_button_rect.position.y if table_power_button.visible else end_turn_button_rect.position.y
	if info_panel_bottom > first_button_top - 4:
		_fail("Selected info panel overlaps the action buttons when the lethal warning is shown.")
		return
	if table_power_button_rect.position.y + table_power_button_rect.size.y > end_turn_button_rect.position.y - 4:
		_fail("Action buttons overlap each other in the selected panel.")
		return

	print("Battle layout verification passed.")
	quit()
