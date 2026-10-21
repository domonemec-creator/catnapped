extends SceneTree

const DeckDefinition = preload("res://scripts/card_game/data/deck_definition.gd")

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

    var newcomer_state := _progression_system.load_state()
    newcomer_state["tavern_threat"] = 3
    newcomer_state["player_wins"] = 0
    newcomer_state["player_losses"] = 3
    _progression_system.save_state(newcomer_state)
    var newcomer_sanitized := _progression_system.load_state()
    if _progression_system.get_threat_level(newcomer_sanitized) != 0:
        _fail("Threat should stay at 0 for a player with no wins, even if an old save stored a higher value.")
        return

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
    if _count_card_ids(smug_threat_zero_cards, &"boilerback_guardian") != 1:
        _fail("Smug threat 0 deck should start with 1 Boilerback Guardian (učitelský balík, 2026-10-20).")
        return
    if _count_card_ids(smug_threat_ten_cards, &"boilerback_guardian") != 5:
        _fail("Smug threat 10 deck should lean into 5 Boilerback Guardians.")
        return
    if _count_card_ids(smug_threat_ten_cards, &"captain_ironmaw") != 4:
        _fail("Smug threat 10 deck should contain 4 Captain Ironmaws.")
        return
    if _count_card_ids(smug_threat_ten_cards, &"fish_toss") != 0:
        _fail("Simple-core Smug deck should not contain Fish Toss.")
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
    if _count_card_ids(ragclaw_threat_zero_cards, &"wharf_cutthroat") != 4:
        _fail("Ragclaw threat 0 deck should start with 4 Wharf Cutthroats.")
        return
    if _count_card_ids(ragclaw_threat_ten_cards, &"netclaw_raider") != 6:
        _fail("Ragclaw threat 10 deck should contain 6 Netclaw Raiders (podpisová karta zůstává).")
        return
    if _count_card_ids(ragclaw_threat_ten_cards, &"rafter_pouncer") != 7:
        _fail("Ragclaw threat 10 deck should contain 7 Rafter Pouncers.")
        return
    if _count_card_ids(ragclaw_threat_ten_cards, &"hidden_claws") != 0:
        _fail("Simple-core Ragclaw deck should not contain Hidden Claws.")
        return
    if _progression_system.get_threat_transition_messages(&"npc_ragclaw_brawler", 0, 1).is_empty():
        _fail("Ragclaw should emit threat transition messaging.")
        return

    var harbor_warden_deck := load("res://data/decks/npc_harbor_warden.tres") as DeckDefinition
    if harbor_warden_deck == null:
        _fail("Could not load npc_harbor_warden.tres.")
        return

    var harbor_threat_zero_cards := _progression_system.build_enemy_deck_card_ids(harbor_warden_deck, 0)
    var harbor_threat_ten_cards := _progression_system.build_enemy_deck_card_ids(harbor_warden_deck, 10)
    if harbor_threat_zero_cards.size() != 20 or harbor_threat_ten_cards.size() != 20:
        _fail("Harbor Warden threat deck size changed away from 20.")
        return
    if _count_card_ids(harbor_threat_ten_cards, &"boilerback_guardian") != 6:
        _fail("Harbor threat 10 deck should contain 6 Boilerback Guardians.")
        return
    if _count_card_ids(harbor_threat_ten_cards, &"captain_ironmaw") != 3:
        _fail("Harbor threat 10 deck should contain 3 Captain Ironmaws.")
        return
    if _count_card_ids(harbor_threat_ten_cards, &"hidden_claws") != 0:
        _fail("Simple-core Harbor deck should not contain Hidden Claws.")
        return
    if _progression_system.get_threat_transition_messages(&"npc_harbor_warden", 0, 1).is_empty():
        _fail("Harbor Warden should emit threat transition messaging.")
        return

    var lantern_striker_deck := load("res://data/decks/npc_lantern_striker.tres") as DeckDefinition
    if lantern_striker_deck == null:
        _fail("Could not load npc_lantern_striker.tres.")
        return

    var lantern_threat_zero_cards := _progression_system.build_enemy_deck_card_ids(lantern_striker_deck, 0)
    var lantern_threat_ten_cards := _progression_system.build_enemy_deck_card_ids(lantern_striker_deck, 10)
    if lantern_threat_zero_cards.size() != 20 or lantern_threat_ten_cards.size() != 20:
        _fail("Lantern Striker threat deck size changed away from 20.")
        return
    if _count_card_ids(lantern_threat_ten_cards, &"netclaw_raider") != 6:
        _fail("Lantern threat 10 deck should contain 6 Netclaw Raiders (podpisová karta zůstává).")
        return
    if _count_card_ids(lantern_threat_ten_cards, &"rafter_pouncer") != 7:
        _fail("Lantern threat 10 deck should contain 7 Rafter Pouncers.")
        return
    if _count_card_ids(lantern_threat_ten_cards, &"table_flip") != 0:
        _fail("Simple-core Lantern deck should not contain Table Flip.")
        return
    if _progression_system.get_threat_transition_messages(&"npc_lantern_striker", 0, 1).is_empty():
        _fail("Lantern Striker should emit threat transition messaging.")
        return

    var packed_scene := load("res://scenes/card_game/battle_scene.tscn") as PackedScene
    if packed_scene == null:
        _fail("Could not load battle_scene.tscn.")
        return

    var battle = packed_scene.instantiate()
    root.add_child(battle)
    await process_frame
    await process_frame

    if not battle.enemy_name_label.tooltip_text.contains("Hrozba 0"):
        _fail("Battle scene did not show threat 0 at startup.")
        return

    battle._battle_state.get_player_state(battle.PLAYER_ID).life = 0
    battle._check_battle_end()

    var saved_after_loss := _progression_system.load_state()
    if _progression_system.get_threat_level(saved_after_loss) != 0:
        _fail("Threat should not increase after a defeat before the first player win.")
        return

    battle.queue_free()
    await process_frame

    var rematch = packed_scene.instantiate()
    root.add_child(rematch)
    await process_frame
    await process_frame

    if not rematch.enemy_name_label.tooltip_text.contains("Hrozba 0"):
        _fail("Battle scene should reload with threat 0 before the first player win.")
        return

    rematch._battle_state.get_player_state(rematch.ENEMY_ID).life = 0
    rematch._check_battle_end()

    var saved_after_win := _progression_system.load_state()
    if _progression_system.get_threat_level(saved_after_win) != 0:
        _fail("Threat did not decrease after player victory.")
        return

    var post_win_loss := _progression_system.apply_battle_result(saved_after_win, rematch.ENEMY_ID, rematch.PLAYER_ID, rematch.ENEMY_ID)
    if _progression_system.get_threat_level(post_win_loss) != 1:
        _fail("Threat should start increasing again after the player already has at least one win.")
        return

    _progression_system.reset_state()
    print("Threat progression verification passed.")
    quit()
