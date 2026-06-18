class_name ProgressionSystem
extends RefCounted

const DeckDefinition = preload("res://scripts/card_game/data/deck_definition.gd")

const SAVE_PATH := "user://catnapped_progress.cfg"
const SECTION_PROGRESS := "progress"
const KEY_THREAT := "tavern_threat"
const KEY_WINS := "player_wins"
const KEY_LOSSES := "player_losses"
const MIN_THREAT := 0
const MAX_THREAT := 10

const THREAT_LABELS := [
    "Calm",
    "Watchful",
    "Restless",
    "Sharper",
    "Loaded",
    "Dangerous",
    "Ruthless",
    "Vicious",
    "Predatory",
    "Brutal",
    "Nightmare",
]

const SMUG_TABBY_UPGRADE_LINES := {
    1: {
        "gain": "Smug Tabby cuts Tavern Mouser and adds Hidden Claws.",
        "lose": "Smug Tabby loses Hidden Claws and falls back to Tavern Mouser.",
    },
    2: {
        "gain": "Smug Tabby cuts Fishbone Skulker and adds Fish Toss.",
        "lose": "Smug Tabby loses Fish Toss and falls back to Fishbone Skulker.",
    },
    3: {
        "gain": "Smug Tabby cuts Fishbone Skulker and adds Spiked Collar.",
        "lose": "Smug Tabby loses Spiked Collar and falls back to Fishbone Skulker.",
    },
    4: {
        "gain": "Smug Tabby cuts Tavern Mouser and adds Iron Bowl.",
        "lose": "Smug Tabby loses Iron Bowl and falls back to Tavern Mouser.",
    },
    5: {
        "gain": "Smug Tabby upgrades Alley Scrapper into Wharf Cutthroat.",
        "lose": "Smug Tabby drops Wharf Cutthroat back to Alley Scrapper.",
    },
    6: {
        "gain": "Smug Tabby cuts Tavern Mouser and adds Table Flip.",
        "lose": "Smug Tabby loses Table Flip and falls back to Tavern Mouser.",
    },
    7: {
        "gain": "Smug Tabby upgrades Dockside Bruiser into Captain Ironmaw.",
        "lose": "Smug Tabby drops Captain Ironmaw back to Dockside Bruiser.",
    },
    8: {
        "gain": "Smug Tabby upgrades Alley Scrapper into Netclaw Raider.",
        "lose": "Smug Tabby drops Netclaw Raider back to Alley Scrapper.",
    },
    9: {
        "gain": "Smug Tabby cuts Dockside Bruiser and adds a second Hidden Claws.",
        "lose": "Smug Tabby loses the extra Hidden Claws and falls back to Dockside Bruiser.",
    },
    10: {
        "gain": "Smug Tabby upgrades Dockside Bruiser into Boilerback Guardian.",
        "lose": "Smug Tabby drops Boilerback Guardian back to Dockside Bruiser.",
    },
}

const RAGCLAW_BRAWLER_UPGRADE_LINES := {
    1: {
        "gain": "Ragclaw cuts Fishbone Skulker and adds Hidden Claws.",
        "lose": "Ragclaw loses Hidden Claws and falls back to Fishbone Skulker.",
    },
    2: {
        "gain": "Ragclaw cuts Alley Scrapper and adds Fish Toss.",
        "lose": "Ragclaw loses Fish Toss and falls back to Alley Scrapper.",
    },
    3: {
        "gain": "Ragclaw cuts Alley Scrapper and adds Spiked Collar.",
        "lose": "Ragclaw loses Spiked Collar and falls back to Alley Scrapper.",
    },
    4: {
        "gain": "Ragclaw cuts Candlepaw Scout and adds Catnip Burst.",
        "lose": "Ragclaw loses Catnip Burst and falls back to Candlepaw Scout.",
    },
    5: {
        "gain": "Ragclaw upgrades Dockside Bruiser into Wharf Cutthroat.",
        "lose": "Ragclaw drops Wharf Cutthroat back to Dockside Bruiser.",
    },
    6: {
        "gain": "Ragclaw cuts Alley Scrapper and adds Table Flip.",
        "lose": "Ragclaw loses Table Flip and falls back to Alley Scrapper.",
    },
    7: {
        "gain": "Ragclaw cuts Candlepaw Scout and adds a second Hidden Claws.",
        "lose": "Ragclaw loses the extra Hidden Claws and falls back to Candlepaw Scout.",
    },
    8: {
        "gain": "Ragclaw upgrades Rafter Pouncer into Netclaw Raider.",
        "lose": "Ragclaw drops Netclaw Raider back to Rafter Pouncer.",
    },
    9: {
        "gain": "Ragclaw upgrades Rafter Pouncer into Wharf Cutthroat.",
        "lose": "Ragclaw drops Wharf Cutthroat back to Rafter Pouncer.",
    },
    10: {
        "gain": "Ragclaw upgrades Captain Ironmaw into Netclaw Raider.",
        "lose": "Ragclaw drops Netclaw Raider back to Captain Ironmaw.",
    },
}


func load_state() -> Dictionary:
    var config := ConfigFile.new()
    var state := _make_default_state()
    if config.load(SAVE_PATH) != OK:
        return state

    state[KEY_THREAT] = clampi(int(config.get_value(SECTION_PROGRESS, KEY_THREAT, 0)), MIN_THREAT, MAX_THREAT)
    state[KEY_WINS] = maxi(0, int(config.get_value(SECTION_PROGRESS, KEY_WINS, 0)))
    state[KEY_LOSSES] = maxi(0, int(config.get_value(SECTION_PROGRESS, KEY_LOSSES, 0)))
    return state


func save_state(state: Dictionary) -> void:
    var sanitized := _sanitize_state(state)
    var config := ConfigFile.new()
    config.set_value(SECTION_PROGRESS, KEY_THREAT, sanitized[KEY_THREAT])
    config.set_value(SECTION_PROGRESS, KEY_WINS, sanitized[KEY_WINS])
    config.set_value(SECTION_PROGRESS, KEY_LOSSES, sanitized[KEY_LOSSES])
    var save_error := config.save(SAVE_PATH)
    if save_error != OK:
        push_warning("Could not save progression to %s." % SAVE_PATH)


func reset_state() -> Dictionary:
    var state := _make_default_state()
    save_state(state)
    return state


func get_threat_level(state: Dictionary) -> int:
    return clampi(int(state.get(KEY_THREAT, 0)), MIN_THREAT, MAX_THREAT)


func get_threat_label(threat_level: int) -> String:
    return THREAT_LABELS[clampi(threat_level, MIN_THREAT, MAX_THREAT)]


func get_win_count(state: Dictionary) -> int:
    return maxi(0, int(state.get(KEY_WINS, 0)))


func get_loss_count(state: Dictionary) -> int:
    return maxi(0, int(state.get(KEY_LOSSES, 0)))


func apply_battle_result(state: Dictionary, winner_player_id: int, player_id: int, enemy_id: int) -> Dictionary:
    var next_state := _sanitize_state(state)
    var threat := get_threat_level(next_state)

    if winner_player_id == enemy_id:
        next_state[KEY_THREAT] = mini(MAX_THREAT, threat + 1)
        next_state[KEY_LOSSES] = int(next_state[KEY_LOSSES]) + 1
    elif winner_player_id == player_id:
        next_state[KEY_THREAT] = maxi(MIN_THREAT, threat - 1)
        next_state[KEY_WINS] = int(next_state[KEY_WINS]) + 1

    return next_state


func build_enemy_deck_card_ids(deck_definition: DeckDefinition, threat_level: int) -> Array[StringName]:
    var deck_cards := _flatten_deck_entries(deck_definition)
    if deck_definition == null:
        return deck_cards

    match deck_definition.id:
        &"npc_smug_tabby":
            _apply_smug_tabby_profile(deck_cards, clampi(threat_level, MIN_THREAT, MAX_THREAT))
        &"npc_ragclaw_brawler":
            _apply_ragclaw_brawler_profile(deck_cards, clampi(threat_level, MIN_THREAT, MAX_THREAT))

    return deck_cards


func get_threat_transition_messages(deck_id: StringName, from_threat: int, to_threat: int) -> Array[String]:
    var messages: Array[String] = []
    var clamped_from := clampi(from_threat, MIN_THREAT, MAX_THREAT)
    var clamped_to := clampi(to_threat, MIN_THREAT, MAX_THREAT)
    if clamped_from == clamped_to:
        return messages

    var upgrade_lines := _get_upgrade_lines_for_deck(deck_id)
    if upgrade_lines.is_empty():
        return messages

    if clamped_to > clamped_from:
        for level in range(clamped_from + 1, clamped_to + 1):
            var line := _get_upgrade_line(upgrade_lines, level, true)
            if not line.is_empty():
                messages.append(line)
    else:
        for level in range(clamped_from, clamped_to, -1):
            var line := _get_upgrade_line(upgrade_lines, level, false)
            if not line.is_empty():
                messages.append(line)

    return messages


func _make_default_state() -> Dictionary:
    return {
        KEY_THREAT: 0,
        KEY_WINS: 0,
        KEY_LOSSES: 0,
    }


func _sanitize_state(state: Dictionary) -> Dictionary:
    var next_state := _make_default_state()
    next_state[KEY_THREAT] = clampi(int(state.get(KEY_THREAT, 0)), MIN_THREAT, MAX_THREAT)
    next_state[KEY_WINS] = maxi(0, int(state.get(KEY_WINS, 0)))
    next_state[KEY_LOSSES] = maxi(0, int(state.get(KEY_LOSSES, 0)))
    return next_state


func _flatten_deck_entries(deck_definition: DeckDefinition) -> Array[StringName]:
    var deck_cards: Array[StringName] = []
    if deck_definition == null:
        return deck_cards

    for entry in deck_definition.cards:
        if entry == null or entry.card_id == StringName() or entry.count <= 0:
            continue
        for _count in range(entry.count):
            deck_cards.append(entry.card_id)

    return deck_cards


func _replace_first(deck_cards: Array[StringName], remove_card_id: StringName, add_card_id: StringName) -> void:
    var remove_index := deck_cards.find(remove_card_id)
    if remove_index < 0:
        return
    deck_cards[remove_index] = add_card_id


func _get_upgrade_lines_for_deck(deck_id: StringName) -> Dictionary:
    match deck_id:
        &"npc_smug_tabby":
            return SMUG_TABBY_UPGRADE_LINES
        &"npc_ragclaw_brawler":
            return RAGCLAW_BRAWLER_UPGRADE_LINES
    return {}


func _apply_smug_tabby_profile(deck_cards: Array[StringName], threat_level: int) -> void:
    if threat_level >= 1:
        _replace_first(deck_cards, &"tavern_mouser", &"hidden_claws")
    if threat_level >= 2:
        _replace_first(deck_cards, &"fishbone_skulker", &"fish_toss")
    if threat_level >= 3:
        _replace_first(deck_cards, &"fishbone_skulker", &"spiked_collar")
    if threat_level >= 4:
        _replace_first(deck_cards, &"tavern_mouser", &"iron_bowl")
    if threat_level >= 5:
        _replace_first(deck_cards, &"alley_scrapper", &"wharf_cutthroat")
    if threat_level >= 6:
        _replace_first(deck_cards, &"tavern_mouser", &"table_flip")
    if threat_level >= 7:
        _replace_first(deck_cards, &"dockside_bruiser", &"captain_ironmaw")
    if threat_level >= 8:
        _replace_first(deck_cards, &"alley_scrapper", &"netclaw_raider")
    if threat_level >= 9:
        _replace_first(deck_cards, &"dockside_bruiser", &"hidden_claws")
    if threat_level >= 10:
        _replace_first(deck_cards, &"dockside_bruiser", &"boilerback_guardian")


func _apply_ragclaw_brawler_profile(deck_cards: Array[StringName], threat_level: int) -> void:
    if threat_level >= 1:
        _replace_first(deck_cards, &"fishbone_skulker", &"hidden_claws")
    if threat_level >= 2:
        _replace_first(deck_cards, &"alley_scrapper", &"fish_toss")
    if threat_level >= 3:
        _replace_first(deck_cards, &"alley_scrapper", &"spiked_collar")
    if threat_level >= 4:
        _replace_first(deck_cards, &"candlepaw_scout", &"catnip_burst")
    if threat_level >= 5:
        _replace_first(deck_cards, &"dockside_bruiser", &"wharf_cutthroat")
    if threat_level >= 6:
        _replace_first(deck_cards, &"alley_scrapper", &"table_flip")
    if threat_level >= 7:
        _replace_first(deck_cards, &"candlepaw_scout", &"hidden_claws")
    if threat_level >= 8:
        _replace_first(deck_cards, &"rafter_pouncer", &"netclaw_raider")
    if threat_level >= 9:
        _replace_first(deck_cards, &"rafter_pouncer", &"wharf_cutthroat")
    if threat_level >= 10:
        _replace_first(deck_cards, &"captain_ironmaw", &"netclaw_raider")


func _get_upgrade_line(upgrade_lines: Dictionary, level: int, gaining: bool) -> String:
    var line_set: Dictionary = upgrade_lines.get(level, {})
    if line_set.is_empty():
        return ""
    return str(line_set.get("gain" if gaining else "lose", ""))
