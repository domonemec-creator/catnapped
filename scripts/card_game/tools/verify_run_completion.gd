extends SceneTree


var _progression_system := ProgressionSystem.new()


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	_get_run_session().end_run()
	_progression_system.reset_state()
	push_error(message)
	quit(1)


func _run() -> void:
	var run_session = _get_run_session()
	run_session.end_run()
	_progression_system.reset_state()
	run_session.start_new_run(&"smug_tabby", 1)

	if not run_session.is_active():
		_fail("RunSession was not marked active for the final battle test.")
		return
	if run_session.get_route_length() != 1:
		_fail("Final battle test did not start a one-step run.")
		return

	var packed_scene := load("res://scenes/card_game/battle_scene.tscn") as PackedScene
	if packed_scene == null:
		_fail("Could not load battle_scene.tscn.")
		return

	var battle = packed_scene.instantiate()
	root.add_child(battle)

	await process_frame
	await process_frame

	if battle._encounter == null or battle._encounter.id != &"smug_tabby":
		_fail("Final battle test did not load the expected encounter.")
		return

	var starting_deck_size: int = run_session.get_player_deck_card_ids().size()
	var enemy_state = battle._battle_state.get_player_state(battle.ENEMY_ID)
	if enemy_state == null:
		_fail("Missing enemy state.")
		return

	enemy_state.life = 0
	battle._check_battle_end()

	if not battle.post_match_reward_buttons.visible:
		_fail("Final victory should still offer the last reward draft.")
		return
	if battle._current_reward_offers.size() != 3:
		_fail("Final victory reward draft did not generate 3 offers.")
		return

	battle._on_reward_button_pressed(0)

	await process_frame
	await process_frame

	if not run_session.is_active():
		_fail("RunSession ended before the completion overlay was acknowledged.")
		return
	if battle.post_match_result_title.text != "Výprava dokončena":
		_fail("Final reward did not switch the overlay to Výprava dokončena.")
		return
	if battle.post_match_choose_encounter_button.text != "Zpět na výběr":
		_fail("Completion overlay did not expose the expected exit button.")
		return
	if battle.post_match_reward_buttons.visible:
		_fail("Completion overlay should hide reward buttons.")
		return
	if battle.post_match_rematch_button.visible:
		_fail("Completion overlay should not offer rematch.")
		return
	if not battle.post_match_record_label.text.contains("HOTOVO"):
		_fail("Completion overlay did not mark the run as finished.")
		return

	var saved_state_after_reward := _progression_system.load_state()
	if _progression_system.get_player_deck_card_ids(saved_state_after_reward).size() != starting_deck_size + 1:
		_fail("Final reward did not persist into the saved player deck.")
		return

	battle._on_choose_encounter_button_pressed()

	await process_frame
	await process_frame

	if run_session.is_active():
		_fail("RunSession stayed active after leaving the completion overlay.")
		return
	if current_scene == null or not (current_scene is EncounterSelectMenu):
		_fail("Completion overlay did not return to encounter select.")
		return

	_progression_system.reset_state()
	run_session.end_run()
	print("Run completion verification passed.")
	quit()


func _get_run_session():
	return root.get_node("/root/RunSession")
