extends SceneTree


func _init() -> void:
    call_deferred("_capture")


func _capture() -> void:
    var output_path := "user://postmatch_overlay.png"
    var outcome := "defeat"
    var user_args := OS.get_cmdline_user_args()
    if user_args.size() >= 1:
        output_path = user_args[0]
    if user_args.size() >= 2:
        outcome = user_args[1].to_lower()

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

    battle._progression_state = battle._progression_system.reset_state()
    battle.enemy_name_label.text = battle._build_enemy_header_name("The Smug Tabby")
    battle.status_label.text = battle._build_opening_status()

    var player_state = battle._battle_state.get_player_state(battle.PLAYER_ID)
    var enemy_state = battle._battle_state.get_player_state(battle.ENEMY_ID)
    if player_state == null or enemy_state == null:
        push_error("Could not resolve battle states.")
        quit(1)
        return

    match outcome:
        "victory":
            enemy_state.life = 0
        _:
            player_state.life = 0

    battle._check_battle_end()

    await process_frame
    await process_frame
    await create_timer(0.3).timeout
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

    battle._progression_system.reset_state()
    print("Saved screenshot to %s" % output_path)
    quit()
