extends SceneTree

# Captures the encounter select screen in its default state.
# Run with a real window (NOT --headless):
#   Godot --path <proj> --script res://scripts/card_game/tools/capture_encounter_select.gd -- <out.png>


func _init() -> void:
    call_deferred("_capture")


func _capture() -> void:
    var output_path := "user://encounter_select.png"
    var user_args := OS.get_cmdline_user_args()
    if user_args.size() >= 1:
        output_path = user_args[0]

    root.size = Vector2i(1600, 900)

    var packed_scene := load("res://scenes/card_game/encounter_select.tscn") as PackedScene
    if packed_scene == null:
        push_error("Could not load encounter_select.tscn")
        quit(1)
        return

    var menu := packed_scene.instantiate()
    root.add_child(menu)

    await process_frame
    await process_frame

    if menu._encounters.is_empty():
        push_error("Encounter select did not load any encounters")
        quit(1)
        return

    await create_timer(0.4).timeout
    await RenderingServer.frame_post_draw

    var image := root.get_texture().get_image()
    if image == null:
        push_error("Could not capture viewport image")
        quit(1)
        return
    image.save_png(output_path)
    print("Saved screenshot to %s" % output_path)
    quit()
