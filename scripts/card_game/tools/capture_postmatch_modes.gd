extends SceneTree

# Screenshoty výsledkových obrazovek v okně: prohra a dokončený run. Save se obnoví.
#   -- "<abs cesta bez přípony>"  → <cesta>_loss.png, <cesta>_complete.png

func _init() -> void:
	call_deferred("_run")


func _shot(mode: String, base: String, progression) -> void:
	var run_session = root.get_node("RunSession")
	var empty_deck: Array[StringName] = []
	run_session.start_new_run(&"smug_tabby", 1 if mode == "complete" else 5, empty_deck)
	var battle = (load("res://scenes/card_game/battle_scene.tscn") as PackedScene).instantiate()
	battle.startup_encounter_id = &"smug_tabby"
	root.add_child(battle)
	await process_frame
	await process_frame
	battle._dismiss_tutorial_overlay(false)
	if mode == "loss":
		battle._battle_state.get_player_state(battle.PLAYER_ID).life = 0
	else:
		battle._battle_state.get_player_state(battle.ENEMY_ID).life = 0
	battle._check_battle_end()
	battle._refresh_ui()
	if mode == "complete" and battle.post_match_reward_add_button.visible:
		battle._on_reward_button_pressed(0)
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s_%s.png" % [base, mode])
	print("Saved %s_%s.png" % [base, mode])
	battle.queue_free()
	run_session.end_run()
	await process_frame


func _run() -> void:
	var base := OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "user://postmatch"
	root.size = Vector2i(1600, 900)
	var progression = load("res://scripts/card_game/systems/progression_system.gd").new()
	var original_state: Dictionary = progression.load_state()
	await _shot("loss", base, progression)
	await _shot("complete", base, progression)
	progression.save_state(original_state)
	quit()
