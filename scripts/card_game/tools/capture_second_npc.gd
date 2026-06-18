extends SceneTree

# Loads the second NPC encounter (Ragclaw the Brawler), advances a few turns so
# the enemy AI actually plays its deck, then screenshots. Proves the data-driven
# encounter/deck/table-power pipeline is not overfit to The Smug Tabby.
# Run with a real window (NOT --headless):
#   Godot --path <proj> --script res://scripts/card_game/tools/capture_second_npc.gd -- <out.png>

func _init() -> void:
    call_deferred("_capture")


func _capture() -> void:
    var output_path := "user://second_npc.png"
    var turns := 3
    var user_args := OS.get_cmdline_user_args()
    if user_args.size() >= 1:
        output_path = user_args[0]
    if user_args.size() >= 2:
        turns = int(user_args[1])

    root.size = Vector2i(1600, 900)

    var packed_scene := load("res://scenes/card_game/battle_scene.tscn") as PackedScene
    if packed_scene == null:
        push_error("Could not load battle_scene.tscn")
        quit(1)
        return

    var battle_scene := packed_scene.instantiate()
    battle_scene.startup_encounter_id = &"ragclaw_brawler"
    root.add_child(battle_scene)

    await process_frame
    await process_frame

    var encounter = battle_scene._encounter
    if encounter == null:
        push_error("FAIL: encounter did not load")
        quit(1)
        return
    print("Loaded encounter: %s (deck %s, power %s, life %s)" % [
        encounter.npc_name, encounter.deck_id, encounter.table_power_id, encounter.starting_life])

    # Advance turns so the enemy AI plays its deck.
    for i in range(turns):
        battle_scene._on_end_turn_pressed()
        await process_frame
        await process_frame

    var enemy_state = battle_scene._battle_state.get_player_state(1)
    var enemy_cats := 0
    for lane in enemy_state.board:
        if lane != null and lane.occupant != null:
            enemy_cats += 1
    print("After %s turn(s) — enemy cats on board: %s, enemy Life: %s, player Life: %s" % [
        turns, enemy_cats, enemy_state.life, battle_scene._battle_state.get_player_state(0).life])

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
