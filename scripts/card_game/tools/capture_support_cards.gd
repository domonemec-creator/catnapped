extends SceneTree


func _init() -> void:
    call_deferred("_capture")


func _capture() -> void:
    var output_path := "user://card_game_support_cards.png"
    var user_args := OS.get_cmdline_user_args()
    if not user_args.is_empty():
        output_path = user_args[0]

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

    var player_state = battle._battle_state.get_player_state(battle.PLAYER_ID)
    if player_state == null:
        push_error("Missing player state.")
        quit(1)
        return

    player_state.hand.clear()
    player_state.hand.append(battle._create_card_instance(&"catnip_burst", battle.PLAYER_ID))
    player_state.hand.append(battle._create_card_instance(&"spiked_collar", battle.PLAYER_ID))
    player_state.hand.append(battle._create_card_instance(&"dockside_bruiser", battle.PLAYER_ID))
    battle._selected_card = player_state.hand[0]
    battle._refresh_ui()

    await process_frame
    await create_timer(0.4).timeout
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

    print("Saved screenshot to %s" % output_path)
    quit()
