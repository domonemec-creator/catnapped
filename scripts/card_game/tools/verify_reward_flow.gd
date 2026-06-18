extends SceneTree

const ProgressionSystem = preload("res://scripts/card_game/systems/progression_system.gd")

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
    if run_session.get_current_step_number() != 1:
        _fail("Run did not start on step 1.")
        return
    if run_session.get_current_encounter_id() != &"smug_tabby":
        _fail("Run did not start from the selected encounter.")
        return

    var starting_deck_size: int = run_session.get_player_deck_card_ids().size()
    if starting_deck_size <= 0:
        _fail("RunSession deck was empty at run start.")
        return

    var enemy_state = battle._battle_state.get_player_state(battle.ENEMY_ID)
    if enemy_state == null:
        _fail("Missing enemy state.")
        return
    enemy_state.life = 0
    battle._check_battle_end()

    if not battle.post_match_reward_buttons.visible:
        _fail("Reward draft did not become visible after victory.")
        return
    if battle.post_match_deck_shift_title.text != "Reward Draft":
        _fail("Reward draft title did not switch.")
        return
    if battle._current_reward_offers.size() != 3:
        _fail("Reward draft did not generate 3 offers.")
        return
    if not battle.post_match_reward_add_button.text.begins_with("Add "):
        _fail("Reward add button did not get a card label.")
        return
    if not battle.post_match_reward_remove_button.text.begins_with("Remove "):
        _fail("Reward remove button did not get a card label.")
        return
    if not battle.post_match_reward_upgrade_button.text.begins_with("Upgrade "):
        _fail("Reward upgrade button did not get a card label.")
        return
    if battle.post_match_choose_encounter_button.visible:
        _fail("Classic post-match buttons should be hidden in reward draft mode.")
        return

    battle._on_reward_button_pressed(0)

    await process_frame
    await process_frame

    var saved_state_after_reward := _progression_system.load_state()
    if _progression_system.get_player_deck_card_ids(saved_state_after_reward).size() != starting_deck_size + 1:
        _fail("Reward add did not persist to the progression save.")
        return

    var next_battle := current_scene
    if next_battle == null or next_battle._encounter == null:
        _fail("Run did not advance to the next battle after reward selection.")
        return
    if not run_session.is_active():
        _fail("RunSession stopped after reward selection.")
        return
    if run_session.get_current_step_number() != 2:
        _fail("Run did not advance to step 2 after reward selection.")
        return
    if run_session.get_current_encounter_id() != &"ragclaw_brawler":
        _fail("Run did not advance to the second encounter.")
        return
    if run_session.get_player_deck_card_ids().size() != starting_deck_size + 1:
        _fail("Reward add did not persist to the run deck.")
        return

    var next_player_state = next_battle._battle_state.get_player_state(next_battle.PLAYER_ID)
    if next_player_state == null:
        _fail("Missing player state in the next battle.")
        return

    var runtime_zone_total: int = next_player_state.deck.size() + next_player_state.hand.size() + next_player_state.discard.size()
    if runtime_zone_total != run_session.get_player_deck_card_ids().size():
        _fail("Persistent run deck and battle runtime deck do not match.")
        return

    _progression_system.reset_state()
    run_session.end_run()
    print("Reward flow verification passed.")
    quit()


func _get_run_session():
    return root.get_node("/root/RunSession")
