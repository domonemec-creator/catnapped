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
const THREAT_UNLOCK_WIN_COUNT := 1
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
		"gain": "Namyšlený kocour vyměnil Svíčkotlapého zvěda za Skryté drápy.",
		"lose": "Namyšlený kocour bere zpět Svíčkotlapého zvěda a odkládá Skryté drápy.",
	},
	2: {
		"gain": "Namyšlený kocour vyměnil Uličního rváče za Skryté drápy.",
		"lose": "Namyšlený kocour bere zpět Uličního rváče a odkládá Skryté drápy.",
	},
	3: {
		"gain": "Namyšlený kocour vyměnil Uličního rváče za Hod rybou.",
		"lose": "Namyšlený kocour bere zpět Uličního rváče a odkládá Hod rybou.",
	},
	4: {
		"gain": "Namyšlený kocour vyměnil Rybokostěného plíživce za Železnou misku.",
		"lose": "Namyšlený kocour bere zpět Rybokostěného plíživce a odkládá Železnou misku.",
	},
	5: {
		"gain": "Namyšlený kocour vyměnil Hospodského myšolovce za Ostnatý obojek.",
		"lose": "Namyšlený kocour bere zpět Hospodského myšolovce a odkládá Ostnatý obojek.",
	},
	6: {
		"gain": "Namyšlený kocour vyměnil Rybokostěného plíživce za Převrácení stolu.",
		"lose": "Namyšlený kocour bere zpět Rybokostěného plíživce a odkládá Převrácení stolu.",
	},
	7: {
		"gain": "Namyšlený kocour vyměnil Dokového rváče za Kapitána Železnou tlamu.",
		"lose": "Namyšlený kocour bere zpět Dokového rváče a odkládá Kapitána Železnou tlamu.",
	},
	8: {
		"gain": "Namyšlený kocour vyměnil Hospodského myšolovce za Lodní hák.",
		"lose": "Namyšlený kocour bere zpět Hospodského myšolovce a odkládá Lodní hák.",
	},
	9: {
		"gain": "Namyšlený kocour vyměnil Dokového rváče za Vyhazovače.",
		"lose": "Namyšlený kocour bere zpět Dokového rváče a odkládá Vyhazovače.",
	},
	10: {
		"gain": "Namyšlený kocour vyměnil Dokového rváče za Kotelního strážce.",
		"lose": "Namyšlený kocour bere zpět Dokového rváče a odkládá Kotelního strážce.",
	},
}

const RAGCLAW_BRAWLER_UPGRADE_LINES := {
	1: {
		"gain": "Ragclaw rváč vyměnil Rybokostěného plíživce za Skryté drápy.",
		"lose": "Ragclaw rváč bere zpět Rybokostěného plíživce a odkládá Skryté drápy.",
	},
	2: {
		"gain": "Ragclaw rváč vyměnil Uličního rváče za Hod rybou.",
		"lose": "Ragclaw rváč bere zpět Uličního rváče a odkládá Hod rybou.",
	},
	3: {
		"gain": "Ragclaw rváč vyměnil Uličního rváče za Ostnatý obojek.",
		"lose": "Ragclaw rváč bere zpět Uličního rváče a odkládá Ostnatý obojek.",
	},
	4: {
		"gain": "Ragclaw rváč vyměnil Svíčkotlapého zvěda za Kočičí mátu.",
		"lose": "Ragclaw rváč bere zpět Svíčkotlapého zvěda a odkládá Kočičí mátu.",
	},
	5: {
		"gain": "Ragclaw rváč vyměnil Dokového rváče za Přístavního hrdlořeze.",
		"lose": "Ragclaw rváč bere zpět Dokového rváče a odkládá Přístavního hrdlořeze.",
	},
	6: {
		"gain": "Ragclaw rváč vyměnil Uličního rváče za Převrácení stolu.",
		"lose": "Ragclaw rváč bere zpět Uličního rváče a odkládá Převrácení stolu.",
	},
	7: {
		"gain": "Ragclaw rváč vyměnil Svíčkotlapého zvěda za Skryté drápy.",
		"lose": "Ragclaw rváč bere zpět Svíčkotlapého zvěda a odkládá Skryté drápy.",
	},
	8: {
		"gain": "Ragclaw rváč vyměnil Trámového skokana za Síťodrápého nájezdníka.",
		"lose": "Ragclaw rváč bere zpět Trámového skokana a odkládá Síťodrápého nájezdníka.",
	},
	9: {
		"gain": "Ragclaw rváč vyměnil Trámového skokana za Síťodrápého nájezdníka.",
		"lose": "Ragclaw rváč bere zpět Trámového skokana a odkládá Síťodrápého nájezdníka.",
	},
	10: {
		"gain": "Ragclaw rváč vyměnil Kapitána Železnou tlamu za Přístavního hrdlořeze.",
		"lose": "Ragclaw rváč bere zpět Kapitána Železnou tlamu a odkládá Přístavního hrdlořeze.",
	},
}

const HARBOR_WARDEN_UPGRADE_LINES := {
	1: {
		"gain": "Přístavní strážný meni Svicotlapeho zveda za Skryté drápy.",
		"lose": "Přístavní strážný prichazi o Skryté drápy a vraci se ke Svicotlapemu zvedovi.",
	},
	2: {
		"gain": "Přístavní strážný mění Hospodského myšolovce za Hod rybou.",
		"lose": "Přístavní strážný přichází o Hod rybou a vrací se k Hospodskému myšolovci.",
	},
	3: {
		"gain": "Přístavní strážný povyšuje Uličního rváče na Přístavního hrdlořeze.",
		"lose": "Přístavní strážný vrací Přístavního hrdlořeze zpět na Uličního rváče.",
	},
	4: {
		"gain": "Přístavní strážný povyšuje Dokového rváče na Kotelního strážce.",
		"lose": "Přístavní strážný vrací Kotelního strážce zpět na Dokového rváče.",
	},
	5: {
		"gain": "Přístavní strážný povyšuje Přístavního hrdlořeze na Kapitána Železnou tlamu.",
		"lose": "Přístavní strážný vrací Kapitána Železnou tlamu zpět na Přístavního hrdlořeze.",
	},
	6: {
		"gain": "Přístavní strážný mění Kotelního strážce za Železnou misku.",
		"lose": "Přístavní strážný přichází o Železnou misku a vrací se ke Kotelnímu strážci.",
	},
	7: {
		"gain": "Přístavní strážný meni Hospodskeho mysivce za Převrácení stolu.",
		"lose": "Přístavní strážný prichazi o Převrácení stolu a vraci se k Hospodskemu mysivci.",
	},
	8: {
		"gain": "Přístavní strážný povyšuje Rybokostěného plíživce na Síťodrápého nájezdníka.",
		"lose": "Přístavní strážný vrací Síťodrápého nájezdníka zpět na Rybokostěného plíživce.",
	},
	9: {
		"gain": "Přístavní strážný meni Dokoveho rvace za druhe Skryté drápy.",
		"lose": "Přístavní strážný prichazi o druhe Skryté drápy a vraci se k Dokovemu rvaci.",
	},
	10: {
		"gain": "Přístavní strážný povyšuje Svíčkotlapého zvěda na Kotelního strážce.",
		"lose": "Přístavní strážný vrací Kotelního strážce zpět ke Svíčkotlapému zvědovi.",
	},
}

const LANTERN_STRIKER_UPGRADE_LINES := {
	1: {
		"gain": "Lucernový útočník vyměnil Hospodského myšolovce za Kočičí mátu.",
		"lose": "Lucernový útočník bere zpět Hospodského myšolovce a odkládá Kočičí mátu.",
	},
	2: {
		"gain": "Lucernový útočník vyměnil Uličního rváče za Skryté drápy.",
		"lose": "Lucernový útočník bere zpět Uličního rváče a odkládá Skryté drápy.",
	},
	3: {
		"gain": "Lucernový útočník vyměnil Uličního rváče za Hod rybou.",
		"lose": "Lucernový útočník bere zpět Uličního rváče a odkládá Hod rybou.",
	},
	4: {
		"gain": "Lucernový útočník vyměnil Svíčkotlapého zvěda za Trámového skokana.",
		"lose": "Lucernový útočník bere zpět Svíčkotlapého zvěda a odkládá Trámového skokana.",
	},
	5: {
		"gain": "Lucernový útočník vyměnil Dokového rváče za Přístavního hrdlořeze.",
		"lose": "Lucernový útočník bere zpět Dokového rváče a odkládá Přístavního hrdlořeze.",
	},
	6: {
		"gain": "Lucernový útočník vyměnil Svíčkotlapého zvěda za Síťodrápého nájezdníka.",
		"lose": "Lucernový útočník bere zpět Svíčkotlapého zvěda a odkládá Síťodrápého nájezdníka.",
	},
	7: {
		"gain": "Lucernový útočník vyměnil Kočičí mátu za Převrácení stolu.",
		"lose": "Lucernový útočník bere zpět Kočičí mátu a odkládá Převrácení stolu.",
	},
	8: {
		"gain": "Lucernový útočník vyměnil Dokového rváče za Kapitána Železnou tlamu.",
		"lose": "Lucernový útočník bere zpět Dokového rváče a odkládá Kapitána Železnou tlamu.",
	},
	9: {
		"gain": "Lucernový útočník vyměnil Hod rybou za Lovecký postroj.",
		"lose": "Lucernový útočník bere zpět Hod rybou a odkládá Lovecký postroj.",
	},
	10: {
		"gain": "Lucernový útočník vyměnil Trámového skokana za Kotelního strážce.",
		"lose": "Lucernový útočník bere zpět Trámového skokana a odkládá Kotelního strážce.",
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
	var wins := get_win_count(next_state)

	if winner_player_id == enemy_id:
		if wins >= THREAT_UNLOCK_WIN_COUNT:
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
	next_state[KEY_WINS] = maxi(0, int(state.get(KEY_WINS, 0)))
	next_state[KEY_LOSSES] = maxi(0, int(state.get(KEY_LOSSES, 0)))
	var raw_threat := clampi(int(state.get(KEY_THREAT, 0)), MIN_THREAT, MAX_THREAT)
	next_state[KEY_THREAT] = 0 if next_state[KEY_WINS] < THREAT_UNLOCK_WIN_COUNT else raw_threat
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
	# Control: trades early bodies for removal + sustain + finishers.
	if threat_level >= 1:
		_replace_first(deck_cards, &"candlepaw_scout", &"hidden_claws")
	if threat_level >= 2:
		_replace_first(deck_cards, &"alley_scrapper", &"hidden_claws")
	if threat_level >= 3:
		_replace_first(deck_cards, &"alley_scrapper", &"fish_toss")
	if threat_level >= 4:
		_replace_first(deck_cards, &"fishbone_skulker", &"iron_bowl")
	if threat_level >= 5:
		_replace_first(deck_cards, &"tavern_mouser", &"spiked_collar")
	if threat_level >= 6:
		_replace_first(deck_cards, &"fishbone_skulker", &"table_flip")
	if threat_level >= 7:
		_replace_first(deck_cards, &"dockside_bruiser", &"captain_ironmaw")
	if threat_level >= 8:
		_replace_first(deck_cards, &"tavern_mouser", &"gaff_hook")
	if threat_level >= 9:
		_replace_first(deck_cards, &"dockside_bruiser", &"tavern_bouncer")
	if threat_level >= 10:
		_replace_first(deck_cards, &"tavern_mouser", &"boilerback_guardian")


func _apply_ragclaw_brawler_profile(deck_cards: Array[StringName], threat_level: int) -> void:
	# Rush: doubles down on reach, burst and Pounce pressure.
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
		_replace_first(deck_cards, &"rafter_pouncer", &"netclaw_raider")
	if threat_level >= 10:
		_replace_first(deck_cards, &"captain_ironmaw", &"wharf_cutthroat")


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
	# Tempo: curves out with Pounce, buffs and reach, capping with mid/top threats.
	if threat_level >= 1:
		_replace_first(deck_cards, &"tavern_mouser", &"catnip_burst")
	if threat_level >= 2:
		_replace_first(deck_cards, &"alley_scrapper", &"hidden_claws")
	if threat_level >= 3:
		_replace_first(deck_cards, &"alley_scrapper", &"fish_toss")
	if threat_level >= 4:
		_replace_first(deck_cards, &"candlepaw_scout", &"rafter_pouncer")
	if threat_level >= 5:
		_replace_first(deck_cards, &"dockside_bruiser", &"wharf_cutthroat")
	if threat_level >= 6:
		_replace_first(deck_cards, &"candlepaw_scout", &"netclaw_raider")
	if threat_level >= 7:
		_replace_first(deck_cards, &"catnip_burst", &"table_flip")
	if threat_level >= 8:
		_replace_first(deck_cards, &"dockside_bruiser", &"captain_ironmaw")
	if threat_level >= 9:
		_replace_first(deck_cards, &"fish_toss", &"hunters_harness")
	if threat_level >= 10:
		_replace_first(deck_cards, &"rafter_pouncer", &"boilerback_guardian")


func _get_upgrade_line(upgrade_lines: Dictionary, level: int, gaining: bool) -> String:
	var line_set: Dictionary = upgrade_lines.get(level, {})
	if line_set.is_empty():
		return ""
	return str(line_set.get("gain" if gaining else "lose", ""))
