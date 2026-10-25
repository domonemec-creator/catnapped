extends Node

const DeckDefinition = preload("res://scripts/card_game/data/deck_definition.gd")

const DEFAULT_RUN_ROSTER: Array[StringName] = [&"smug_tabby", &"lantern_striker", &"ragclaw_brawler", &"fog_seer", &"harbor_warden", &"bilge_king"]
const DEFAULT_RUN_LENGTH := 5
const STARTER_DECK_PATH := "res://data/decks/starter_player.tres"
const REWARD_ADD_POOL: Array[StringName] = [
    &"alley_scrapper",
    &"ship_lookout",
    &"smuggler",
    &"candlepaw_scout",
    &"fishbone_skulker",
    &"tavern_mouser",
    &"wharf_cutthroat",
    &"netclaw_raider",
    &"rafter_pouncer",
    &"dockside_bruiser",
    &"captain_ironmaw",
    &"boilerback_guardian",
    # Nové karty 2026-10-20 (D-016)
    &"lamplighter",
    &"dock_harpooner",
    &"pickpocket",
    &"stray_mother",
    &"galley_cook",
    &"harbor_drummer",
    &"grey_veteran",
    &"carrion_prowler",
    &"graveyard_glutton",
    # D3 2026-10-21
    &"harbor_kitten",
    &"bait_fisher",
    &"rat_hunter",
    &"rope_acrobat",
    &"helmsman",
    &"dock_breaker",
    &"harbor_courier",
    &"net_mender",
]
const REWARD_UPGRADE_MAP := {
    &"candlepaw_scout": &"wharf_cutthroat",
    &"alley_scrapper": &"netclaw_raider",
    &"tavern_mouser": &"boilerback_guardian",
    &"fishbone_skulker": &"dockside_bruiser",
    &"wharf_cutthroat": &"rafter_pouncer",
    &"netclaw_raider": &"captain_ironmaw",
    &"rafter_pouncer": &"captain_ironmaw",
    &"dockside_bruiser": &"boilerback_guardian",
    &"captain_ironmaw": &"boilerback_guardian",
}

var _active: bool = false
var _route: Array[StringName] = []
var _current_index: int = -1
var _player_deck_card_ids: Array[StringName] = []
var _current_reward_offers: Array[Dictionary] = []


func start_new_run(start_encounter_id: StringName, route_length: int = DEFAULT_RUN_LENGTH, starting_deck_card_ids: Array[StringName] = []) -> void:
    var roster := _build_run_roster()
    if roster.is_empty():
        push_warning("RunSession could not build a run route.")
        end_run()
        return

    var sanitized_length := maxi(1, route_length)
    var start_index := roster.find(start_encounter_id)
    if start_index < 0:
        start_index = 0

    _route.clear()
    for step in range(sanitized_length):
        _route.append(roster[(start_index + step) % roster.size()])

    _current_index = 0
    _active = true
    if starting_deck_card_ids.is_empty():
        _player_deck_card_ids = _load_starter_deck_card_ids()
    else:
        _player_deck_card_ids = _sanitize_card_ids(starting_deck_card_ids)
    _current_reward_offers.clear()


func end_run() -> void:
    _active = false
    _current_index = -1
    _route.clear()
    _player_deck_card_ids.clear()
    _current_reward_offers.clear()


func is_active() -> bool:
    return _active


func get_route() -> Array[StringName]:
    return _route.duplicate()


func get_route_length() -> int:
    return _route.size()


func get_current_step_number() -> int:
    if not _active or _current_index < 0 or _route.is_empty():
        return 0
    return _current_index + 1


func get_current_encounter_id() -> StringName:
    if not _active or _current_index < 0 or _current_index >= _route.size():
        return StringName()
    return _route[_current_index]


func has_next_encounter() -> bool:
    return _active and _current_index >= 0 and _current_index + 1 < _route.size()


func advance_to_next_encounter() -> StringName:
    if not has_next_encounter():
        return StringName()

    _current_index += 1
    return _route[_current_index]


func get_run_progress_text() -> String:
    if not _active or _route.is_empty():
        return ""
    return "Výprava %s/%s" % [get_current_step_number(), _route.size()]


func get_run_roster_summary() -> String:
    if _route.is_empty():
        return ""

    var roster_names: Array[String] = []
    for encounter_id in _route:
        roster_names.append(_encounter_display_name(encounter_id))
    return " -> ".join(roster_names)


func get_player_deck_card_ids() -> Array[StringName]:
    return _player_deck_card_ids.duplicate()


func set_player_deck_card_ids(card_ids: Array[StringName]) -> void:
    _player_deck_card_ids.clear()
    for card_id in card_ids:
        if card_id == StringName():
            continue
        _player_deck_card_ids.append(card_id)


func build_reward_offers(card_library: Dictionary) -> Array[Dictionary]:
    _current_reward_offers = _build_reward_offers(card_library)
    return _duplicate_reward_offers(_current_reward_offers)


func get_current_reward_offers() -> Array[Dictionary]:
    return _duplicate_reward_offers(_current_reward_offers)


func clear_reward_offers() -> void:
    _current_reward_offers.clear()


func apply_reward_offer(offer: Dictionary) -> bool:
    match str(offer.get("kind", "")):
        "add":
            return _add_card_to_player_deck(StringName(offer.get("card_id", StringName())))
        "remove":
            return _remove_card_from_player_deck(StringName(offer.get("card_id", StringName())))
        "upgrade":
            return _replace_card_in_player_deck(
                StringName(offer.get("from_card_id", StringName())),
                StringName(offer.get("to_card_id", StringName()))
            )

    return false


func _build_run_roster() -> Array[StringName]:
    var roster: Array[StringName] = []
    for encounter_id in DEFAULT_RUN_ROSTER:
        if encounter_id == StringName():
            continue
        roster.append(encounter_id)
    return roster


func _encounter_display_name(encounter_id: StringName) -> String:
    match encounter_id:
        &"smug_tabby":
            return "Namyšlený kocour"
        &"ragclaw_brawler":
            return "Ragclaw rváč"
        &"harbor_warden":
            return "Přístavní strážný"
        &"lantern_striker":
            return "Lucernový útočník"
        &"fog_seer":
            return "Mlžná věštkyně"
        &"bilge_king":
            return "Stokový král"
    return String(encounter_id)


func _load_starter_deck_card_ids() -> Array[StringName]:
    var deck_definition := load(STARTER_DECK_PATH) as DeckDefinition
    if deck_definition == null:
        push_warning("RunSession could not load %s." % STARTER_DECK_PATH)
        return []

    return _flatten_deck_entries(deck_definition)


func _sanitize_card_ids(card_ids: Array[StringName]) -> Array[StringName]:
    var sanitized: Array[StringName] = []
    for card_id in card_ids:
        if card_id == StringName():
            continue
        sanitized.append(card_id)
    if sanitized.is_empty():
        return _load_starter_deck_card_ids()
    return sanitized


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


func _build_reward_offers(card_library: Dictionary) -> Array[Dictionary]:
    var offers: Array[Dictionary] = []
    var add_card_id := _pick_add_reward_card_id(card_library)
    var remove_card_id := _pick_remove_reward_card_id(card_library)
    var upgrade_offer := _pick_upgrade_reward(card_library)

    if add_card_id != StringName():
        offers.append({
            "kind": "add",
            "card_id": add_card_id,
            "label": "Přidat: %s" % _get_card_display_name(card_library, add_card_id),
        })

    if remove_card_id != StringName():
        offers.append({
            "kind": "remove",
            "card_id": remove_card_id,
            "label": "Odebrat: %s" % _get_card_display_name(card_library, remove_card_id),
        })

    if not upgrade_offer.is_empty():
        offers.append({
            "kind": "upgrade",
            "from_card_id": upgrade_offer.get("from_card_id", StringName()),
            "to_card_id": upgrade_offer.get("to_card_id", StringName()),
            "label": "Vylepšit: %s → %s" % [
                _get_card_display_name(card_library, StringName(upgrade_offer.get("from_card_id", StringName()))),
                _get_card_display_name(card_library, StringName(upgrade_offer.get("to_card_id", StringName()))),
            ],
        })
    elif add_card_id != StringName():
        var fallback_add_card_id := _pick_add_reward_card_id(card_library, [add_card_id])
        if fallback_add_card_id != StringName():
            offers.append({
                "kind": "add",
                "card_id": fallback_add_card_id,
                "label": "Přidat: %s" % _get_card_display_name(card_library, fallback_add_card_id),
            })

    while offers.size() < 3:
        var fallback_offer_card_id := _pick_add_reward_card_id(card_library, _collect_reward_offer_card_ids(offers))
        if fallback_offer_card_id == StringName():
            break
        offers.append({
            "kind": "add",
            "card_id": fallback_offer_card_id,
            "label": "Přidat: %s" % _get_card_display_name(card_library, fallback_offer_card_id),
        })

    if _player_deck_card_ids.size() >= ProgressionSystem.DECK_MAX_SIZE:
        offers = _swap_add_offers_at_cap(offers, card_library, remove_card_id)
    return offers


# Plný balík (D-030): „Přidat“ se mění na výměnu za nejslabší kartu, aby balík nerostl donekonečna.
func _swap_add_offers_at_cap(offers: Array[Dictionary], card_library: Dictionary, weakest_card_id: StringName) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for offer in offers:
        if str(offer.get("kind", "")) != "add":
            result.append(offer)
            continue
        if weakest_card_id == StringName():
            continue
        var card_id := StringName(offer.get("card_id", StringName()))
        result.append({
            "kind": "upgrade",
            "from_card_id": weakest_card_id,
            "to_card_id": card_id,
            "label": "Vyměnit: %s → %s" % [_get_card_display_name(card_library, weakest_card_id), _get_card_display_name(card_library, card_id)],
        })
    return result


func _pick_add_reward_card_id(card_library: Dictionary, excluded_card_ids: Array[StringName] = []) -> StringName:
    var fallback_card_id := StringName()
    for card_id in REWARD_ADD_POOL:
        if not card_library.has(card_id):
            continue
        if fallback_card_id == StringName():
            fallback_card_id = card_id
        if excluded_card_ids.has(card_id):
            continue
        if not _player_deck_card_ids.has(card_id):
            return card_id
    return fallback_card_id


func _pick_remove_reward_card_id(card_library: Dictionary) -> StringName:
    var card_counts: Dictionary = {}
    for card_id in _player_deck_card_ids:
        card_counts[card_id] = int(card_counts.get(card_id, 0)) + 1

    var best_card_id := StringName()
    var best_count := -1
    var best_score := 2147483647
    for card_id in card_counts.keys():
        var typed_card_id := StringName(card_id)
        var card_definition: CardDefinition = card_library.get(typed_card_id) as CardDefinition
        var count := int(card_counts.get(card_id, 0))
        var score := _card_removal_score(card_definition)
        if count > best_count or (count == best_count and score < best_score):
            best_card_id = typed_card_id
            best_count = count
            best_score = score

    return best_card_id


func _pick_upgrade_reward(card_library: Dictionary) -> Dictionary:
    var best_from_card_id := StringName()
    var best_to_card_id := StringName()
    var best_score := 2147483647

    for card_id in _player_deck_card_ids:
        var target_card_id: StringName = REWARD_UPGRADE_MAP.get(card_id, StringName())
        if target_card_id == StringName():
            continue
        if not card_library.has(target_card_id):
            continue

        var card_definition: CardDefinition = card_library.get(card_id) as CardDefinition
        var score := _card_upgrade_score(card_definition)
        if score < best_score:
            best_from_card_id = card_id
            best_to_card_id = target_card_id
            best_score = score

    if best_from_card_id == StringName() or best_to_card_id == StringName():
        return {}

    return {
        "from_card_id": best_from_card_id,
        "to_card_id": best_to_card_id,
    }


func _add_card_to_player_deck(card_id: StringName) -> bool:
    if card_id == StringName():
        return false
    _player_deck_card_ids.append(card_id)
    return true


func _remove_card_from_player_deck(card_id: StringName) -> bool:
    var remove_index := _player_deck_card_ids.find(card_id)
    if remove_index < 0:
        return false
    _player_deck_card_ids.remove_at(remove_index)
    return true


func _replace_card_in_player_deck(from_card_id: StringName, to_card_id: StringName) -> bool:
    if from_card_id == StringName() or to_card_id == StringName():
        return false
    var replace_index := _player_deck_card_ids.find(from_card_id)
    if replace_index < 0:
        return false
    _player_deck_card_ids[replace_index] = to_card_id
    return true


func _get_card_display_name(card_library: Dictionary, card_id: StringName) -> String:
    var card_definition: CardDefinition = card_library.get(card_id) as CardDefinition
    if card_definition == null or card_definition.display_name.is_empty():
        return String(card_id)
    return card_definition.display_name


func _card_removal_score(card_definition: CardDefinition) -> int:
    if card_definition == null:
        return 2147483647
    return card_definition.cost * 100 + card_definition.attack * 10 + card_definition.life


func _card_upgrade_score(card_definition: CardDefinition) -> int:
    if card_definition == null:
        return 2147483647
    return card_definition.cost * 100 + card_definition.attack * 10 + card_definition.life


func _duplicate_reward_offers(offers: Array[Dictionary]) -> Array[Dictionary]:
    var duplicated: Array[Dictionary] = []
    for offer in offers:
        duplicated.append(offer.duplicate(true))
    return duplicated


func _collect_reward_offer_card_ids(offers: Array[Dictionary]) -> Array[StringName]:
    var card_ids: Array[StringName] = []
    for offer in offers:
        var kind := str(offer.get("kind", ""))
        match kind:
            "add", "remove":
                var card_id := StringName(offer.get("card_id", StringName()))
                if card_id != StringName() and not card_ids.has(card_id):
                    card_ids.append(card_id)
            "upgrade":
                var from_card_id := StringName(offer.get("from_card_id", StringName()))
                var to_card_id := StringName(offer.get("to_card_id", StringName()))
                if from_card_id != StringName() and not card_ids.has(from_card_id):
                    card_ids.append(from_card_id)
                if to_card_id != StringName() and not card_ids.has(to_card_id):
                    card_ids.append(to_card_id)
    return card_ids
