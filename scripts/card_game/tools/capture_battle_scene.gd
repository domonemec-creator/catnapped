extends SceneTree


func _init() -> void:
    call_deferred("_capture")


func _capture() -> void:
    var output_path := "user://card_game_battle_screenshot.png"
    var user_args := OS.get_cmdline_user_args()
    if not user_args.is_empty():
        output_path = user_args[0]

    root.size = Vector2i(1600, 900)

    var packed_scene := load("res://scenes/card_game/battle_scene.tscn") as PackedScene
    if packed_scene == null:
        push_error("Could not load battle_scene.tscn")
        quit(1)
        return

    var battle_scene := packed_scene.instantiate()
    root.add_child(battle_scene)

    await process_frame
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
