extends SceneTree


var _progression_system := ProgressionSystem.new()


func _init() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    _progression_system.reset_state()
    push_error(message)
    quit(1)


func _run() -> void:
    _progression_system.reset_state()

    var packed_scene := load("res://scenes/card_game/progression_screen.tscn") as PackedScene
    if packed_scene == null:
        _fail("Could not load progression_screen.tscn.")
        return

    var screen := packed_scene.instantiate()
    if screen == null:
        _fail("Could not instantiate progression screen.")
        return
    root.add_child(screen)

    await process_frame
    await process_frame

    if screen._deck_total_label == null or not screen._deck_total_label.text.contains("20"):
        _fail("Progression screen did not show the starter deck size.")
        return
    if screen._threat_label == null or not screen._threat_label.text.contains("Threat: 0"):
        _fail("Progression screen did not show threat 0.")
        return

    var mutated_state: Dictionary = _progression_system.load_state()
    var mutated_deck := _progression_system.get_player_deck_card_ids(mutated_state)
    mutated_deck.append(&"table_flip")
    mutated_state = _progression_system.set_player_deck_card_ids(mutated_state, mutated_deck)
    mutated_state["tavern_threat"] = 3
    mutated_state["player_wins"] = 4
    _progression_system.save_state(mutated_state)

    screen._load_state()
    screen._refresh_ui()

    if not screen._threat_label.text.contains("Threat: 3"):
        _fail("Progression screen did not refresh the modified threat.")
        return
    if not screen._deck_total_label.text.contains("21"):
        _fail("Progression screen did not refresh the modified deck size.")
        return

    screen._reset_progress()
    var reset_state := _progression_system.load_state()
    if _progression_system.get_threat_level(reset_state) != 0:
        _fail("Reset progress did not clear threat.")
        return
    if _progression_system.get_win_count(reset_state) != 0:
        _fail("Reset progress did not clear wins.")
        return
    if _progression_system.get_loss_count(reset_state) != 0:
        _fail("Reset progress did not clear losses.")
        return
    if _progression_system.get_player_deck_card_ids(reset_state).size() != 20:
        _fail("Reset progress did not restore the starter deck.")
        return

    _progression_system.reset_state()
    print("Progression screen verification passed.")
    quit()
