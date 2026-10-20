extends SceneTree

# Screenshot obrazovky odměny po výhře v runu (S oknem). Save hráče se obnoví.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var out := "user://reward.png"
	if not OS.get_cmdline_user_args().is_empty():
		out = OS.get_cmdline_user_args()[0]
	root.size = Vector2i(1600, 900)
	var progression = load("res://scripts/card_game/systems/progression_system.gd").new()
	var original_state: Dictionary = progression.load_state()
	var run_session = root.get_node("RunSession")
	var empty_deck: Array[StringName] = []
	run_session.start_new_run(&"smug_tabby", 5, empty_deck)
	var battle = (load("res://scenes/card_game/battle_scene.tscn") as PackedScene).instantiate()
	battle.startup_encounter_id = &"smug_tabby"
	root.add_child(battle)
	await process_frame
	await process_frame
	battle._dismiss_tutorial_overlay(false)
	battle._battle_state.get_player_state(battle.ENEMY_ID).life = 0
	battle._check_battle_end()
	battle._refresh_ui()
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out)
	print("Saved %s" % out)
	progression.save_state(original_state)
	run_session.end_run()
	quit()
