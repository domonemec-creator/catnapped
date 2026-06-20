class_name ProgressionSystem
extends RefCounted

const DeckDefinition = preload("res://scripts/card_game/data/deck_definition.gd")

const SAVE_PATH := "user://catnapped_progress.cfg"
const SECTION_PROGRESS := "progress"
const KEY_THREAT := "tavern_threat"
const KEY_WINS := "player_wins"
const KEY_LOSSES := "player_losses"
const KEY_PLAYER_DECK := "player_deck_card_ids"
const KEY_TUTORIAL_SEEN := "battle_tutorial_seen"
const MIN_THREAT := 0
const MAX_THREAT := 10
const STARTER_DECK_PATH := "res://data/decks/starter_player.tres"

const THREAT_LABELS := [
	"Klid",
	"Pozor",
	"Nepokoj",
	"Ostrost",
	"Nabito",
	"Nebezpeci",
	"Krutost",
	"Zurivost",
	"Lov",
	"Brutalita",
	"Nocni mura",
]

const SMUG_TABBY_UPGRADE_LINES := {
	1: {
		"gain": "Namysleny kocour meni Hospodskeho mysivce za Skryte drapy.",
		"lose": "Namysleny kocour prichazi o Skryte drapy a vraci se k Hospodskemu mysivci.",
	},
	2: {
		"gain": "Namysleny kocour meni Rybokostneho plizila za Hod rybou.",
		"lose": "Namysleny kocour prichazi o Hod rybou a vraci se k Rybokostnemu plizilovi.",
	},
	3: {
		"gain": "Namysleny kocour meni Rybokostneho plizila za Ostnaty obojek.",
		"lose": "Namysleny kocour prichazi o Ostnaty obojek a vraci se k Rybokostnemu plizilovi.",
	},
	4: {
		"gain": "Namysleny kocour meni Hospodskeho mysivce za Zeleznou misku.",
		"lose": "Namysleny kocour prichazi o Zeleznou misku a vraci se k Hospodskemu mysivci.",
	},
	5: {
		"gain": "Namysleny kocour povysuje Ulicniho rvace na Pristavniho hrdloreza.",
		"lose": "Namysleny kocour vraci Pristavniho hrdloreza zpet na Ulicniho rvace.",
	},
	6: {
		"gain": "Namysleny kocour meni Hospodskeho mysivce za Prevrat stolu.",
		"lose": "Namysleny kocour prichazi o Prevrat stolu a vraci se k Hospodskemu mysivci.",
	},
	7: {
		"gain": "Namysleny kocour povysuje Dokoveho rvace na Kapitana Zeleznou tlamu.",
		"lose": "Namysleny kocour vraci Kapitana Zeleznou tlamu zpet na Dokoveho rvace.",
	},
	8: {
		"gain": "Namysleny kocour povysuje Ulicniho rvace na Sitodrapeho najezdnika.",
		"lose": "Namysleny kocour vraci Sitodrapeho najezdnika zpet na Ulicniho rvace.",
	},
	9: {
		"gain": "Namysleny kocour meni Dokoveho rvace za druhe Skryte drapy.",
		"lose": "Namysleny kocour prichazi o druhe Skryte drapy a vraci se k Dokovemu rvaci.",
	},
	10: {
		"gain": "Namysleny kocour povysuje Dokoveho rvace na Kotelniho strazce.",
		"lose": "Namysleny kocour vraci Kotelniho strazce zpet na Dokoveho rvace.",
	},
}

const RAGCLAW_BRAWLER_UPGRADE_LINES := {
	1: {
		"gain": "Ragclaw rvac meni Rybokostneho plizila za Skryte drapy.",
		"lose": "Ragclaw rvac prichazi o Skryte drapy a vraci se k Rybokostnemu plizilovi.",
	},
	2: {
		"gain": "Ragclaw rvac meni Ulicniho rvace za Hod rybou.",
		"lose": "Ragclaw rvac prichazi o Hod rybou a vraci se k Ulicnimu rvaci.",
	},
	3: {
		"gain": "Ragclaw rvac meni Ulicniho rvace za Ostnaty obojek.",
		"lose": "Ragclaw rvac prichazi o Ostnaty obojek a vraci se k Ulicnimu rvaci.",
	},
	4: {
		"gain": "Ragclaw rvac meni Svicotlapeho zveda za Kocici matu.",
		"lose": "Ragclaw rvac prichazi o Kocici matu a vraci se ke Svicotlapemu zvedovi.",
	},
	5: {
		"gain": "Ragclaw rvac povysuje Dokoveho rvace na Pristavniho hrdloreza.",
		"lose": "Ragclaw rvac vraci Pristavniho hrdloreza zpet na Dokoveho rvace.",
	},
	6: {
		"gain": "Ragclaw rvac meni Ulicniho rvace za Prevrat stolu.",
		"lose": "Ragclaw rvac prichazi o Prevrat stolu a vraci se k Ulicnimu rvaci.",
	},
	7: {
		"gain": "Ragclaw rvac meni Svicotlapeho zveda za druhe Skryte drapy.",
		"lose": "Ragclaw rvac prichazi o druhe Skryte drapy a vraci se ke Svicotlapemu zvedovi.",
	},
	8: {
		"gain": "Ragclaw rvac povysuje Tramoveho skokana na Sitodrapeho najezdnika.",
		"lose": "Ragclaw rvac vraci Sitodrapeho najezdnika zpet na Tramoveho skokana.",
	},
	9: {
		"gain": "Ragclaw rvac povysuje Tramoveho skokana na Pristavniho hrdloreza.",
		"lose": "Ragclaw rvac vraci Pristavniho hrdloreza zpet na Tramoveho skokana.",
	},
	10: {
		"gain": "Ragclaw rvac povysuje Kapitana Zeleznou tlamu na Sitodrapeho najezdnika.",
		"lose": "Ragclaw rvac vraci Sitodrapeho najezdnika zpet na Kapitana Zeleznou tlamu.",
	},
}

const HARBOR_WARDEN_UPGRADE_LINES := {
	1: {
		"gain": "Pristavni strazny meni Svicotlapeho zveda za Skryte drapy.",
		"lose": "Pristavni strazny prichazi o Skryte drapy a vraci se ke Svicotlapemu zvedovi.",
	},
	2: {
		"gain": "Pristavni strazny meni Hospodskeho mysivce za Hod rybou.",
		"lose": "Pristavni strazny prichazi o Hod rybou a vraci se k Hospodskemu mysivci.",
	},
	3: {
		"gain": "Pristavni strazny povysuje Ulicniho rvace na Pristavniho hrdloreza.",
		"lose": "Pristavni strazny vraci Pristavniho hrdloreza zpet na Ulicniho rvace.",
	},
	4: {
		"gain": "Pristavni strazny povysuje Dokoveho rvace na Kotelniho strazce.",
		"lose": "Pristavni strazny vraci Kotelniho strazce zpet na Dokoveho rvace.",
	},
	5: {
		"gain": "Pristavni strazny povysuje Pristavniho hrdloreza na Kapitana Zeleznou tlamu.",
		"lose": "Pristavni strazny vraci Kapitana Zeleznou tlamu zpet na Pristavniho hrdloreza.",
	},
	6: {
		"gain": "Pristavni strazny meni Kotelniho strazce za Zeleznou misku.",
		"lose": "Pristavni strazny prichazi o Zeleznou misku a vraci se ke Kotelnimu strazci.",
	},
	7: {
		"gain": "Pristavni strazny meni Hospodskeho mysivce za Prevrat stolu.",
		"lose": "Pristavni strazny prichazi o Prevrat stolu a vraci se k Hospodskemu mysivci.",
	},
	8: {
		"gain": "Pristavni strazny povysuje Rybokostneho plizila na Sitodrapeho najezdnika.",
		"lose": "Pristavni strazny vraci Sitodrapeho najezdnika zpet na Rybokostneho plizila.",
	},
	9: {
		"gain": "Pristavni strazny meni Dokoveho rvace za druhe Skryte drapy.",
		"lose": "Pristavni strazny prichazi o druhe Skryte drapy a vraci se k Dokovemu rvaci.",
	},
	10: {
		"gain": "Pristavni strazny povysuje Svicotlapeho zveda na Kotelniho strazce.",
		"lose": "Pristavni strazny vraci Kotelniho strazce zpet ke Svicotlapemu zvedovi.",
	},
}

const LANTERN_STRIKER_UPGRADE_LINES := {
	1: {
		"gain": "Lucernovy utocnik meni Rybokostneho plizila za Skryte drapy.",
		"lose": "Lucernovy utocnik prichazi o Skryte drapy a vraci se k Rybokostnemu plizilovi.",
	},
	2: {
		"gain": "Lucernovy utocnik meni Hospodskeho mysivce za Kocici matu.",
		"lose": "Lucernovy utocnik prichazi o Kocici matu a vraci se k Hospodskemu mysivci.",
	},
	3: {
		"gain": "Lucernovy utocnik povysuje Ulicniho rvace na Hod rybou.",
		"lose": "Lucernovy utocnik vraci Hod rybou zpet na Ulicniho rvace.",
	},
	4: {
		"gain": "Lucernovy utocnik povysuje Svicotlapeho zveda na Tramoveho skokana.",
		"lose": "Lucernovy utocnik vraci Tramoveho skokana zpet ke Svicotlapemu zvedovi.",
	},
	5: {
		"gain": "Lucernovy utocnik povysuje Dokoveho rvace na Pristavniho hrdloreza.",
		"lose": "Lucernovy utocnik vraci Pristavniho hrdloreza zpet na Dokoveho rvace.",
	},
	6: {
		"gain": "Lucernovy utocnik povysuje Tramoveho skokana na Sitodrapeho najezdnika.",
		"lose": "Lucernovy utocnik vraci Sitodrapeho najezdnika zpet na Tramoveho skokana.",
	},
	7: {
		"gain": "Lucernovy utocnik meni Kocici matu za Prevrat stolu.",
		"lose": "Lucernovy utocnik prichazi o Prevrat stolu a vraci se ke Kocici mate.",
	},
	8: {
		"gain": "Lucernovy utocnik povysuje Pristavniho hrdloreza na Kapitana Zeleznou tlamu.",
		"lose": "Lucernovy utocnik vraci Kapitana Zeleznou tlamu zpet na Pristavniho hrdloreza.",
	},
	9: {
		"gain": "Lucernovy utocnik meni Rybokostneho plizila za Ostnaty obojek.",
		"lose": "Lucernovy utocnik prichazi o Ostnaty obojek a vraci se k Rybokostnemu plizilovi.",
	},
	10: {
		"gain": "Lucernovy utocnik povysuje Ulicniho rvace na Kotelniho strazce.",
		"lose": "Lucernovy utocnik vraci Kotelniho strazce zpet na Ulicniho rvace.",
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
	var loaded_deck: Array = config.get_value(SECTION_PROGRESS, KEY_PLAYER_DECK, _load_starter_deck_card_ids())
	state[KEY_PLAYER_DECK] = _sanitize_deck_card_ids(loaded_deck)
	state[KEY_TUTORIAL_SEEN] = bool(config.get_value(SECTION_PROGRESS, KEY_TUTORIAL_SEEN, false))
	return state


func save_state(state: Dictionary) -> void:
	var sanitized := _sanitize_state(state)
	var config := ConfigFile.new()
	config.set_value(SECTION_PROGRESS, KEY_THREAT, sanitized[KEY_THREAT])
	config.set_value(SECTION_PROGRESS, KEY_WINS, sanitized[KEY_WINS])
	config.set_value(SECTION_PROGRESS, KEY_LOSSES, sanitized[KEY_LOSSES])
	config.set_value(SECTION_PROGRESS, KEY_PLAYER_DECK, _to_string_array(sanitized[KEY_PLAYER_DECK]))
	config.set_value(SECTION_PROGRESS, KEY_TUTORIAL_SEEN, bool(sanitized[KEY_TUTORIAL_SEEN]))
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


func get_player_deck_card_ids(state: Dictionary) -> Array[StringName]:
	var sanitized := _sanitize_state(state)
	return _copy_card_id_array(sanitized.get(KEY_PLAYER_DECK, []))


func set_player_deck_card_ids(state: Dictionary, card_ids: Array[StringName]) -> Dictionary:
	var next_state := _sanitize_state(state)
	next_state[KEY_PLAYER_DECK] = _sanitize_deck_card_ids(card_ids)
	return next_state


func has_seen_battle_tutorial(state: Dictionary) -> bool:
	return bool(_sanitize_state(state).get(KEY_TUTORIAL_SEEN, false))


func mark_battle_tutorial_seen(state: Dictionary) -> Dictionary:
	var next_state := _sanitize_state(state)
	next_state[KEY_TUTORIAL_SEEN] = true
	return next_state


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
		&"npc_harbor_warden":
			_apply_harbor_warden_profile(deck_cards, clampi(threat_level, MIN_THREAT, MAX_THREAT))
		&"npc_lantern_striker":
			_apply_lantern_striker_profile(deck_cards, clampi(threat_level, MIN_THREAT, MAX_THREAT))

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
		KEY_PLAYER_DECK: _load_starter_deck_card_ids(),
		KEY_TUTORIAL_SEEN: false,
	}


func _sanitize_state(state: Dictionary) -> Dictionary:
	var next_state := _make_default_state()
	next_state[KEY_THREAT] = clampi(int(state.get(KEY_THREAT, 0)), MIN_THREAT, MAX_THREAT)
	next_state[KEY_WINS] = maxi(0, int(state.get(KEY_WINS, 0)))
	next_state[KEY_LOSSES] = maxi(0, int(state.get(KEY_LOSSES, 0)))
	next_state[KEY_PLAYER_DECK] = _sanitize_deck_card_ids(state.get(KEY_PLAYER_DECK, next_state[KEY_PLAYER_DECK]))
	next_state[KEY_TUTORIAL_SEEN] = bool(state.get(KEY_TUTORIAL_SEEN, false))
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


func _load_starter_deck_card_ids() -> Array[StringName]:
	var deck_definition := load(STARTER_DECK_PATH) as DeckDefinition
	if deck_definition == null:
		push_warning("Could not load starter deck from %s." % STARTER_DECK_PATH)
		return []
	return _flatten_deck_entries(deck_definition)


func _sanitize_deck_card_ids(card_ids: Variant) -> Array[StringName]:
	var sanitized: Array[StringName] = []
	if card_ids is Array or card_ids is PackedStringArray:
		for card_id_variant in card_ids:
			var card_id := StringName(card_id_variant)
			if card_id == StringName():
				continue
			sanitized.append(card_id)
	if sanitized.is_empty():
		return _load_starter_deck_card_ids()
	return sanitized


func _copy_card_id_array(card_ids: Variant) -> Array[StringName]:
	var copied: Array[StringName] = []
	if card_ids is Array or card_ids is PackedStringArray:
		for card_id_variant in card_ids:
			var card_id := StringName(card_id_variant)
			if card_id == StringName():
				continue
			copied.append(card_id)
	return copied


func _to_string_array(card_ids: Variant) -> Array[String]:
	var string_ids: Array[String] = []
	if card_ids is Array or card_ids is PackedStringArray:
		for card_id_variant in card_ids:
			var card_id := StringName(card_id_variant)
			if card_id == StringName():
				continue
			string_ids.append(String(card_id))
	return string_ids


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
		&"npc_harbor_warden":
			return HARBOR_WARDEN_UPGRADE_LINES
		&"npc_lantern_striker":
			return LANTERN_STRIKER_UPGRADE_LINES
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


func _apply_harbor_warden_profile(deck_cards: Array[StringName], threat_level: int) -> void:
	if threat_level >= 1:
		_replace_first(deck_cards, &"candlepaw_scout", &"hidden_claws")
	if threat_level >= 2:
		_replace_first(deck_cards, &"tavern_mouser", &"fish_toss")
	if threat_level >= 3:
		_replace_first(deck_cards, &"alley_scrapper", &"wharf_cutthroat")
	if threat_level >= 4:
		_replace_first(deck_cards, &"dockside_bruiser", &"boilerback_guardian")
	if threat_level >= 5:
		_replace_first(deck_cards, &"wharf_cutthroat", &"captain_ironmaw")
	if threat_level >= 6:
		_replace_first(deck_cards, &"boilerback_guardian", &"iron_bowl")
	if threat_level >= 7:
		_replace_first(deck_cards, &"tavern_mouser", &"table_flip")
	if threat_level >= 8:
		_replace_first(deck_cards, &"fishbone_skulker", &"netclaw_raider")
	if threat_level >= 9:
		_replace_first(deck_cards, &"dockside_bruiser", &"hidden_claws")
	if threat_level >= 10:
		_replace_first(deck_cards, &"candlepaw_scout", &"boilerback_guardian")


func _apply_lantern_striker_profile(deck_cards: Array[StringName], threat_level: int) -> void:
	if threat_level >= 1:
		_replace_first(deck_cards, &"fishbone_skulker", &"hidden_claws")
	if threat_level >= 2:
		_replace_first(deck_cards, &"tavern_mouser", &"catnip_burst")
	if threat_level >= 3:
		_replace_first(deck_cards, &"alley_scrapper", &"fish_toss")
	if threat_level >= 4:
		_replace_first(deck_cards, &"candlepaw_scout", &"rafter_pouncer")
	if threat_level >= 5:
		_replace_first(deck_cards, &"dockside_bruiser", &"wharf_cutthroat")
	if threat_level >= 6:
		_replace_first(deck_cards, &"rafter_pouncer", &"netclaw_raider")
	if threat_level >= 7:
		_replace_first(deck_cards, &"catnip_burst", &"table_flip")
	if threat_level >= 8:
		_replace_first(deck_cards, &"wharf_cutthroat", &"captain_ironmaw")
	if threat_level >= 9:
		_replace_first(deck_cards, &"fishbone_skulker", &"spiked_collar")
	if threat_level >= 10:
		_replace_first(deck_cards, &"alley_scrapper", &"boilerback_guardian")


func _get_upgrade_line(upgrade_lines: Dictionary, level: int, gaining: bool) -> String:
	var line_set: Dictionary = upgrade_lines.get(level, {})
	if line_set.is_empty():
		return ""
	return str(line_set.get("gain" if gaining else "lose", ""))
