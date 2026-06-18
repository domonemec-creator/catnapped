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

    menu._select_encounter(&"ragclaw_brawler")
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
    if run_session.get_current_step_number() != 1:
        _fail("Run did not start on step 1.")
        return
    if run_session.get_current_encounter_id() != &"ragclaw_brawler":
        _fail("Run did not start from the selected encounter.")
        return
    if battle._encounter.id != &"ragclaw_brawler":
        _fail("Battle scene did not load Ragclaw as the first run encounter.")
        return

    var progression = battle._progression_system
    var enemy_state = battle._battle_state.get_player_state(battle.ENEMY_ID)
    if enemy_state == null:
        _fail("Missing enemy state.")
        return
    enemy_state.life = 0
    battle._check_battle_end()

    if battle.post_match_choose_encounter_button.text != "Next Encounter":
        _fail("Run overlay did not switch to Next Encounter.")
        return
    if not battle.post_match_record_label.text.contains("Run 1/5"):
        _fail("Run overlay did not show run progress.")
        return

    battle._on_choose_encounter_button_pressed()

    await process_frame
    await process_frame

    var next_battle := current_scene
    if next_battle == null or next_battle._encounter == null:
        _fail("Run did not advance to the next battle.")
        return
    if not run_session.is_active():
        _fail("RunSession stopped after advancing to the next battle.")
        return
    if run_session.get_current_step_number() != 2:
        _fail("Run did not advance to step 2.")
        return
    if run_session.get_current_encounter_id() != &"harbor_warden":
        _fail("Second run battle did not switch to Harbor Warden.")
        return
    if next_battle._encounter.id != &"harbor_warden":
        _fail("Battle scene did not load the second run encounter.")
        return

    progression.reset_state()
    run_session.end_run()
    print("Run flow verification passed.")
    quit()


func _get_run_session():
    return root.get_node("/root/RunSession")
