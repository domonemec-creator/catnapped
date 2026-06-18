extends SceneTree

func _init() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    push_error(message)
    quit(1)


func _run() -> void:
    var packed_scene := load("res://scenes/card_game/encounter_select.tscn") as PackedScene
    if packed_scene == null:
        _fail("Could not load encounter_select.tscn.")
        return

    var menu := packed_scene.instantiate()
    root.add_child(menu)

    await process_frame
    await process_frame

    if menu._encounters.size() != 4:
        _fail("Encounter select did not load the full encounter roster.")
        return
    if menu._selected_encounter == null or menu._selected_encounter.id != &"smug_tabby":
        _fail("Encounter select did not default to Smug Tabby.")
        return

    menu._select_encounter(&"ragclaw_brawler")
    if menu._selected_encounter == null or menu._selected_encounter.id != &"ragclaw_brawler":
        _fail("Encounter select did not switch to Ragclaw.")
        return

    menu._select_encounter(&"harbor_warden")
    if menu._selected_encounter == null or menu._selected_encounter.id != &"harbor_warden":
        _fail("Encounter select did not switch to Harbor Warden.")
        return

    menu._start_battle()
    await process_frame
    await process_frame

    var battle := current_scene
    if battle == null or not (battle is BattleController):
        _fail("Battle scene did not replace the selector.")
        return
    if battle.startup_encounter_id != &"harbor_warden":
        _fail("Battle scene did not receive the selected encounter id.")
        return
    if battle._encounter == null or battle._encounter.id != &"harbor_warden":
        _fail("Battle scene did not load the selected encounter.")
        return

    battle.queue_free()
    print("Encounter select verification passed.")
    quit()
