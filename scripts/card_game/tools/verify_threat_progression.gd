extends SceneTree

const DeckDefinition = preload("res://scripts/card_game/data/deck_definition.gd")
const ProgressionSystem = preload("res://scripts/card_game/systems/progression_system.gd")

var _progression_system := ProgressionSystem.new()


func _init() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    _progression_system.reset_state()
    push_error(message)
    quit(1)


func _count_card_ids(card_ids: Array[StringName], target_card_id: StringName) -> int:
    var count := 0
    for card_id in card_ids:
        if card_id == target_card_id:
            count += 1
    return count


func _run() -> void:
    _progression_system.reset_state()

    var smug_tabby_deck := load("res://data/decks/npc_smug_tabby.tres") as DeckDefinition
    if smug_tabby_deck == null:
        _fail("Could not load npc_smug_tabby.tres.")
        return

    var smug_threat_zero_cards := _progression_system.build_enemy_deck_card_ids(smug_tabby_deck, 0)
    var smug_threat_ten_cards := _progression_system.build_enemy_deck_card_ids(smug_tabby_deck, 10)
    if smug_threat_zero_cards.size() != 20:
        _fail("Threat 0 deck size is not 20.")
        return
    if smug_threat_ten_cards.size() != 20:
        _fail("Threat 10 deck size is not 20.")
        return
    if _count_card_ids(smug_threat_zero_cards, &"hidden_claws") != 0:
        _fail("Threat 0 deck should not start with Hidden Claws.")
        return
    if _count_card_ids(smug_threat_ten_cards, &"hidden_claws") != 2:
        _fail("Threat 10 deck should contain 2 Hidden Claws.")
        return
    if _count_card_ids(smug_threat_ten_cards, &"fish_toss") != 1:
        _fail("Threat 10 deck should contain Fish Toss.")
        return
    if _count_card_ids(smug_threat_ten_cards, &"spiked_collar") != 1:
        _fail("Threat 10 deck should contain Spiked Collar.")
        return

    var ragclaw_deck := load("res://data/decks/npc_ragclaw_brawler.tres") as DeckDefinition
    if ragclaw_deck == null:
        _fail("Could not load npc_ragclaw_brawler.tres.")
        return

    var ragclaw_threat_zero_cards := _progression_system.build_enemy_deck_card_ids(ragclaw_deck, 0)
    var ragclaw_threat_ten_cards := _progression_system.build_enemy_deck_card_ids(ragclaw_deck, 10)
    if ragclaw_threat_zero_cards.size() != 20 or ragclaw_threat_ten_cards.size() != 20:
        _fail("Ragclaw threat deck size changed away from 20.")
        return
    if _count_card_ids(ragclaw_threat_zero_cards, &"hidden_claws") != 1:
        _fail("Ragclaw threat 0 deck should start with 1 Hidden Claws.")
        return
    if _count_card_ids(ragclaw_threat_ten_cards, &"hidden_claws") != 3:
        _fail("Ragclaw threat 10 deck should contain 3 Hidden Claws.")
        return
    if _count_card_ids(ragclaw_threat_ten_cards, &"fish_toss") != 2:
        _fail("Ragclaw threat 10 deck should contain 2 Fish Toss.")
        return
    if _count_card_ids(ragclaw_threat_ten_cards, &"table_flip") != 1:
        _fail("Ragclaw threat 10 deck should contain Table Flip.")
        return
    if _count_card_ids(ragclaw_threat_ten_cards, &"netclaw_raider") != 5:
        _fail("Ragclaw threat 10 deck should contain 5 Netclaw Raiders.")
        return
    if _progression_system.get_threat_transition_messages(&"npc_ragclaw_brawler", 0, 1).is_empty():
        _fail("Ragclaw should emit threat transition messaging.")
        return

    var packed_scene := load("res://scenes/card_game/battle_scene.tscn") as PackedScene
    if packed_scene == null:
        _fail("Could not load battle_scene.tscn.")
        return

    var battle = packed_scene.instantiate()
    root.add_child(battle)
    await process_frame
    await process_frame

    if not battle.enemy_name_label.text.contains("[T0]"):
        _fail("Battle scene did not show threat 0 at startup.")
        return

    battle._battle_state.get_player_state(battle.PLAYER_ID).life = 0
    battle._check_battle_end()

    var saved_after_loss := _progression_system.load_state()
    if _progression_system.get_threat_level(saved_after_loss) != 1:
        _fail("Threat did not increase after player defeat.")
        return

    battle.queue_free()
    await process_frame

    var rematch = packed_scene.instantiate()
    root.add_child(rematch)
    await process_frame
    await process_frame

    if not rematch.enemy_name_label.text.contains("[T1]"):
        _fail("Battle scene did not reload with threat 1.")
        return

    rematch._battle_state.get_player_state(rematch.ENEMY_ID).life = 0
    rematch._check_battle_end()

    var saved_after_win := _progression_system.load_state()
    if _progression_system.get_threat_level(saved_after_win) != 0:
        _fail("Threat did not decrease after player victory.")
        return

    _progression_system.reset_state()
    print("Threat progression verification passed.")
    quit()
