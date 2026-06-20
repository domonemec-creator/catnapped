extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	_get_run_session().end_run()
	push_error(message)
	quit(1)


func _run() -> void:
	var run_session = _get_run_session()
	run_session.end_run()

	var packed_scene := load("res://scenes/card_game/encounter_select.tscn") as PackedScene
	if packed_scene == null:
		_fail("Could not load encounter_select.tscn.")
		return

	var menu := packed_scene.instantiate()
	root.add_child(menu)

	await process_frame
	await process_frame

	menu._select_encounter(&"smug_tabby")
	menu._start_run()

	await process_frame
	await process_frame

	var battle := current_scene
	if battle == null or battle._encounter == null:
		_fail("Run did not load a battle scene.")
		return
	if not run_session.is_active():
		_fail("RunSession was not marked active.")
		return

	var player_state = battle._battle_state.get_player_state(battle.PLAYER_ID)
	if player_state == null:
		_fail("Missing player state.")
		return
	player_state.life = 0
	battle._check_battle_end()

	if battle.post_match_choose_encounter_button.text != "Konec výpravy":
		_fail("Run loss did not switch the overlay to Konec výpravy.")
		return
	if battle.post_match_rematch_button.visible:
		_fail("Run loss should not offer rematch.")
		return

	battle._on_choose_encounter_button_pressed()

	await process_frame
	await process_frame

	if run_session.is_active():
		_fail("RunSession stayed active after a lost run.")
		return
	if current_scene == null or not (current_scene is EncounterSelectMenu):
		_fail("Lost run did not return to encounter select.")
		return

	print("Run failure verification passed.")
	quit()


func _get_run_session():
	return root.get_node("/root/RunSession")
