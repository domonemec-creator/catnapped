class_name ProgressionSystem
extends RefCounted

const DeckDefinition = preload("res://scripts/card_game/data/deck_definition.gd")

const SAVE_PATH := "user://catnapped_progress.cfg"
# Testovací běhy mají vlastní save, aby nikdy nepřepsaly postup hráče: headless i nástroje
# spuštěné přes --script v okně (2026-10-21 síťový test v okně přepsal skutečný save).
const TEST_SAVE_PATH := "user://catnapped_progress_test.cfg"


static func _save_path() -> String:
	if DisplayServer.get_name() == "headless" or OS.get_cmdline_args().has("--script"):
		return TEST_SAVE_PATH
	return SAVE_PATH
const SECTION_PROGRESS := "progress"
const KEY_THREAT := "tavern_threat"
const KEY_WINS := "player_wins"
const KEY_LOSSES := "player_losses"
const KEY_PLAYER_DECK := "player_deck_card_ids"
const KEY_TUTORIAL_SEEN := "battle_tutorial_seen"
const KEY_TRAINING_CLEARED := "training_cleared"
const KEY_COLLECTION := "collection_card_ids"
# Hra ve dvou (E5, D-025): vlastní balík ze všech karet; prázdný = zatím kopie tréninkového.
const KEY_PVP_DECK := "pvp_deck_card_ids"
const CARDS_DIR := "res://data/cards"
# Obchod (E3): měna „rybí šupiny“ za zápasy, po zápase pár nabídek karet mimo kolekci.
const KEY_SCALES := "fish_scales"
const SHOP_OFFER_COUNT := 3
const SCALES_WIN_BASE := 10
const SCALES_WIN_PER_TIER := 5
const SCALES_LOSS := 3
const SCALES_PVP := 5

# Stavění balíku (D2): kolekce = startovní karty + odemčené tréninkem + vše, co kdy bylo v balíku.
const DECK_MIN_SIZE := 20
const DECK_MAX_SIZE := 30
const MAX_COPIES := 4
const SINGLE_COPY_IDS: Array[StringName] = [&"captain_ironmaw", &"tavern_bouncer", &"cannon_cat"]
# Výhra v tréninku přidá do kolekce karty typické pro poraženého soupeře.
const TRAINING_CARD_UNLOCKS := {
	&"smug_tabby": [&"wharf_cutthroat", &"harbor_kitten", &"iron_bowl", &"catnip_burst", &"warm_milk"],
	&"lantern_striker": [&"lamplighter", &"rafter_pouncer", &"rope_acrobat", &"pry_bar", &"fish_market"],
	&"ragclaw_brawler": [&"pickpocket", &"bait_fisher", &"net_mender", &"hidden_claws", &"hunters_harness"],
	&"fog_seer": [&"ship_lookout", &"galley_cook", &"rat_hunter", &"fish_toss", &"overboard", &"sardine_can"],
	&"harbor_warden": [&"dock_harpooner", &"grey_veteran", &"helmsman", &"war_plate", &"rusty_anchor"],
	&"bilge_king": [&"smuggler", &"graveyard_glutton", &"dock_breaker", &"cannon_cat", &"harbor_courier", &"tavern_bouncer"],
}
# Trénink (D-022): žebříček soupeřů ve stejném pořadí jako run. Každý další má o
# TRAINING_TIER_STEP vyšší hrozbu a odemkne se až po porážce předchozího.
const TRAINING_ORDER: Array[StringName] = [&"smug_tabby", &"lantern_striker", &"ragclaw_brawler", &"fog_seer", &"harbor_warden", &"bilge_king"]
const TRAINING_TIER_STEP := 2
const TRAINING_TIER_LIFE := 2
# Životy navíc rostou jen do 3. stupně; soupeři 5 a 6 jsou silní balíkem (sim: s +8/+10 životy neporazitelní).
const TRAINING_TIER_LIFE_CAP := 3


static func get_training_life_bonus(tier: int) -> int:
	return mini(tier, TRAINING_TIER_LIFE_CAP) * TRAINING_TIER_LIFE
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
	"Nebezpečí",
	"Krutost",
	"Zuřivost",
	"Lov",
	"Brutalita",
	"Noční můra",
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
		"gain": "Přístavní strážný mění Svíčkotlapého zvěda za Skryté drápy.",
		"lose": "Přístavní strážný přichází o Skryté drápy a vrací se ke Svíčkotlapému zvědovi.",
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
		"gain": "Přístavní strážný mění Hospodského myšolovce za Převrácení stolu.",
		"lose": "Přístavní strážný přichází o Převrácení stolu a vrací se k Hospodskému myšolovci.",
	},
	8: {
		"gain": "Přístavní strážný povyšuje Rybokostěného plíživce na Síťodrápého nájezdníka.",
		"lose": "Přístavní strážný vrací Síťodrápého nájezdníka zpět na Rybokostěného plíživce.",
	},
	9: {
		"gain": "Přístavní strážný mění Dokového rváče za druhé Skryté drápy.",
		"lose": "Přístavní strážný přichází o druhé Skryté drápy a vrací se k Dokovému rváči.",
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
	if config.load(_save_path()) != OK:
		return state

	state[KEY_THREAT] = clampi(int(config.get_value(SECTION_PROGRESS, KEY_THREAT, 0)), MIN_THREAT, MAX_THREAT)
	state[KEY_WINS] = maxi(0, int(config.get_value(SECTION_PROGRESS, KEY_WINS, 0)))
	state[KEY_LOSSES] = maxi(0, int(config.get_value(SECTION_PROGRESS, KEY_LOSSES, 0)))
	var loaded_deck: Array = config.get_value(SECTION_PROGRESS, KEY_PLAYER_DECK, _load_starter_deck_card_ids())
	state[KEY_PLAYER_DECK] = _sanitize_deck_card_ids(loaded_deck)
	state[KEY_TUTORIAL_SEEN] = bool(config.get_value(SECTION_PROGRESS, KEY_TUTORIAL_SEEN, false))
	state[KEY_TRAINING_CLEARED] = int(config.get_value(SECTION_PROGRESS, KEY_TRAINING_CLEARED, 0))
	state[KEY_COLLECTION] = _copy_card_id_array(config.get_value(SECTION_PROGRESS, KEY_COLLECTION, []))
	state[KEY_PVP_DECK] = _copy_card_id_array(config.get_value(SECTION_PROGRESS, KEY_PVP_DECK, []))
	state[KEY_SCALES] = maxi(0, int(config.get_value(SECTION_PROGRESS, KEY_SCALES, 0)))
	return state


func save_state(state: Dictionary) -> void:
	var sanitized := _sanitize_state(state)
	var config := ConfigFile.new()
	config.set_value(SECTION_PROGRESS, KEY_THREAT, sanitized[KEY_THREAT])
	config.set_value(SECTION_PROGRESS, KEY_WINS, sanitized[KEY_WINS])
	config.set_value(SECTION_PROGRESS, KEY_LOSSES, sanitized[KEY_LOSSES])
	config.set_value(SECTION_PROGRESS, KEY_PLAYER_DECK, _to_string_array(sanitized[KEY_PLAYER_DECK]))
	config.set_value(SECTION_PROGRESS, KEY_TUTORIAL_SEEN, bool(sanitized[KEY_TUTORIAL_SEEN]))
	config.set_value(SECTION_PROGRESS, KEY_TRAINING_CLEARED, int(sanitized[KEY_TRAINING_CLEARED]))
	# Karty z balíku zůstanou v kolekci, i když je odměna výpravy později odebere.
	var collection: Array[StringName] = _copy_card_id_array(sanitized[KEY_COLLECTION])
	for card_id in sanitized[KEY_PLAYER_DECK]:
		if not collection.has(card_id):
			collection.append(card_id)
	config.set_value(SECTION_PROGRESS, KEY_COLLECTION, _to_string_array(collection))
	config.set_value(SECTION_PROGRESS, KEY_PVP_DECK, _to_string_array(sanitized[KEY_PVP_DECK]))
	config.set_value(SECTION_PROGRESS, KEY_SCALES, int(sanitized[KEY_SCALES]))
	var save_error := config.save(_save_path())
	if save_error != OK:
		push_warning("Could not save progression to %s." % _save_path())


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


# Starter před balancem 2026-10-20 (D-015). Save, který ho drží beze změny, dostane nový starter;
# upravené balíky (po odměnách) zůstávají, jak jsou.
const LEGACY_STARTER_2026_07: Array[String] = ["alley_scrapper", "alley_scrapper", "alley_scrapper", "alley_scrapper", "candlepaw_scout", "candlepaw_scout", "candlepaw_scout", "candlepaw_scout", "captain_ironmaw", "fishbone_skulker", "fishbone_skulker", "netclaw_raider", "netclaw_raider", "rafter_pouncer", "tavern_mouser", "tavern_mouser", "tavern_mouser", "tavern_mouser", "wharf_cutthroat", "wharf_cutthroat"]


func get_player_deck_card_ids(state: Dictionary) -> Array[StringName]:
	var sanitized := _sanitize_state(state)
	var ids := _copy_card_id_array(sanitized.get(KEY_PLAYER_DECK, []))
	var sorted_ids: Array[String] = []
	for id in ids:
		sorted_ids.append(String(id))
	sorted_ids.sort()
	if sorted_ids == LEGACY_STARTER_2026_07:
		var starter := load(STARTER_DECK_PATH)
		if starter != null:
			var fresh: Array[StringName] = []
			for entry in starter.cards:
				for _i in range(entry.count):
					fresh.append(entry.card_id)
			if not fresh.is_empty():
				return fresh
	return ids


func set_player_deck_card_ids(state: Dictionary, card_ids: Array[StringName]) -> Dictionary:
	var next_state := _sanitize_state(state)
	next_state[KEY_PLAYER_DECK] = _sanitize_deck_card_ids(card_ids)
	return next_state


func get_training_cleared(state: Dictionary) -> int:
	return clampi(int(state.get(KEY_TRAINING_CLEARED, 0)), 0, TRAINING_ORDER.size())


func is_training_unlocked(state: Dictionary, encounter_id: StringName) -> bool:
	var index := TRAINING_ORDER.find(encounter_id)
	return index < 0 or index <= get_training_cleared(state)


func get_training_threat_bonus(encounter_id: StringName) -> int:
	return maxi(0, TRAINING_ORDER.find(encounter_id)) * TRAINING_TIER_STEP


# Zapíše výhru v tréninku; vrátí id nově odemčeného soupeře (nebo prázdné).
func mark_training_win(state: Dictionary, encounter_id: StringName) -> StringName:
	var index := TRAINING_ORDER.find(encounter_id)
	var cleared := get_training_cleared(state)
	if index < 0 or index > cleared or index + 1 <= cleared:
		return StringName()
	state[KEY_TRAINING_CLEARED] = index + 1
	return TRAINING_ORDER[index + 1] if index + 1 < TRAINING_ORDER.size() else StringName()


# Balík pro trénink, nebo (pvp) pro hru ve dvou.
func get_deck_card_ids(state: Dictionary, pvp: bool = false) -> Array[StringName]:
	if pvp:
		var pvp_ids := _copy_card_id_array(_sanitize_state(state).get(KEY_PVP_DECK, []))
		if not pvp_ids.is_empty():
			return pvp_ids
	return get_player_deck_card_ids(state)


func set_deck_card_ids(state: Dictionary, card_ids: Array[StringName], pvp: bool = false) -> Dictionary:
	if not pvp:
		return set_player_deck_card_ids(state, card_ids)
	var next_state := _sanitize_state(state)
	next_state[KEY_PVP_DECK] = _copy_card_id_array(card_ids)
	return next_state


# Všechny sběratelné karty (hra ve dvou): vše v data/cards kromě žetonů.
func get_all_collectible_card_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for file_name in ResourceLoader.list_directory(CARDS_DIR):
		if not file_name.ends_with(".tres"):
			continue
		var card_id := StringName(file_name.get_basename())
		if String(card_id).ends_with("_token"):
			continue
		ids.append(card_id)
	return ids


# Unikátní id karet, které hráč smí dát do balíku.
func get_collection_card_ids(state: Dictionary, pvp: bool = false) -> Array[StringName]:
	if pvp:
		return get_all_collectible_card_ids()
	var ids: Array[StringName] = []
	var sources: Array = [_load_starter_deck_card_ids(), _copy_card_id_array(state.get(KEY_COLLECTION, [])), get_player_deck_card_ids(state)]
	var cleared := get_training_cleared(state)
	for index in cleared:
		sources.append(get_training_unlock_card_ids(TRAINING_ORDER[index]))
	for source in sources:
		for card_id in source:
			if not ids.has(card_id):
				ids.append(card_id)
	return ids


func get_scales(state: Dictionary) -> int:
	return maxi(0, int(state.get(KEY_SCALES, 0)))


# Připíše šupiny za zápas (tier = stupeň soupeře v tréninku); vrací kolik přibylo.
func add_match_scales(state: Dictionary, won: bool, tier: int = 0, pvp: bool = false) -> int:
	var gained := SCALES_PVP if pvp else (SCALES_WIN_BASE + SCALES_WIN_PER_TIER * maxi(0, tier) if won else SCALES_LOSS)
	state[KEY_SCALES] = get_scales(state) + gained
	return gained


func get_card_price(card_id: StringName) -> int:
	var card := load("%s/%s.tres" % [CARDS_DIR, card_id]) as CardDefinition
	return 5 + 5 * (card.cost if card != null else 0)


# Nabídka obchodu: karty, které hráč v tréninkové kolekci ještě nemá (stejný seed = stejná nabídka).
func roll_shop_offers(state: Dictionary, rng_seed: int) -> Array[StringName]:
	var owned := get_collection_card_ids(state)
	var candidates: Array[StringName] = []
	for card_id in get_all_collectible_card_ids():
		if not owned.has(card_id):
			candidates.append(card_id)
	candidates.sort()
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var offers: Array[StringName] = []
	while not candidates.is_empty() and offers.size() < SHOP_OFFER_COUNT:
		offers.append(candidates.pop_at(rng.randi_range(0, candidates.size() - 1)))
	return offers


# Prázdný řetězec = koupeno (karta je v kolekci, šupiny odečtené); jinak důvod pro hráče.
func buy_card(state: Dictionary, card_id: StringName) -> String:
	if get_collection_card_ids(state).has(card_id):
		return "Kartu už máš."
	if not get_all_collectible_card_ids().has(card_id):
		return "Tahle karta se neprodává."
	var price := get_card_price(card_id)
	if get_scales(state) < price:
		return "Chybí šupiny (%s/%s)." % [get_scales(state), price]
	state[KEY_SCALES] = get_scales(state) - price
	var collection := _copy_card_id_array(state.get(KEY_COLLECTION, []))
	collection.append(card_id)
	state[KEY_COLLECTION] = collection
	return ""


func get_training_unlock_card_ids(encounter_id: StringName) -> Array[StringName]:
	var ids: Array[StringName] = []
	for card_id in TRAINING_CARD_UNLOCKS.get(encounter_id, []):
		ids.append(card_id)
	return ids


func get_card_copy_limit(card_id: StringName) -> int:
	return 1 if SINGLE_COPY_IDS.has(card_id) else MAX_COPIES


# Prázdný řetězec = karta jde přidat; jinak důvod pro hráče.
func get_add_block_reason(state: Dictionary, card_id: StringName, pvp: bool = false) -> String:
	var deck := get_deck_card_ids(state, pvp)
	if not get_collection_card_ids(state, pvp).has(card_id):
		return "Kartu ještě nemáš v kolekci."
	if deck.size() >= DECK_MAX_SIZE:
		return "Balík je plný (%s karet)." % DECK_MAX_SIZE
	if deck.count(card_id) >= get_card_copy_limit(card_id):
		return "Víc kopií nejde (max %s)." % get_card_copy_limit(card_id)
	return ""


func add_card_to_deck(state: Dictionary, card_id: StringName, pvp: bool = false) -> Dictionary:
	if not get_add_block_reason(state, card_id, pvp).is_empty():
		return state
	var deck := get_deck_card_ids(state, pvp)
	deck.append(card_id)
	return set_deck_card_ids(state, deck, pvp)


func can_remove_from_deck(state: Dictionary, card_id: StringName, pvp: bool = false) -> bool:
	var deck := get_deck_card_ids(state, pvp)
	return deck.has(card_id) and deck.size() > DECK_MIN_SIZE


func remove_card_from_deck(state: Dictionary, card_id: StringName, pvp: bool = false) -> Dictionary:
	if not can_remove_from_deck(state, card_id, pvp):
		return state
	var deck := get_deck_card_ids(state, pvp)
	deck.erase(card_id)
	return set_deck_card_ids(state, deck, pvp)


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
		KEY_TRAINING_CLEARED: 0,
		KEY_COLLECTION: [],
		KEY_PVP_DECK: [],
		KEY_SCALES: 0,
	}


func _sanitize_state(state: Dictionary) -> Dictionary:
	var next_state := _make_default_state()
	next_state[KEY_WINS] = maxi(0, int(state.get(KEY_WINS, 0)))
	next_state[KEY_LOSSES] = maxi(0, int(state.get(KEY_LOSSES, 0)))
	var raw_threat := clampi(int(state.get(KEY_THREAT, 0)), MIN_THREAT, MAX_THREAT)
	next_state[KEY_THREAT] = 0 if next_state[KEY_WINS] < THREAT_UNLOCK_WIN_COUNT else raw_threat
	next_state[KEY_PLAYER_DECK] = _sanitize_deck_card_ids(state.get(KEY_PLAYER_DECK, next_state[KEY_PLAYER_DECK]))
	next_state[KEY_TUTORIAL_SEEN] = bool(state.get(KEY_TUTORIAL_SEEN, false))
	next_state[KEY_TRAINING_CLEARED] = get_training_cleared(state)
	next_state[KEY_COLLECTION] = _copy_card_id_array(state.get(KEY_COLLECTION, []))
	next_state[KEY_PVP_DECK] = _copy_card_id_array(state.get(KEY_PVP_DECK, []))
	next_state[KEY_SCALES] = maxi(0, int(state.get(KEY_SCALES, 0)))
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
	# Simple-core control: threat adds heavier blockers and value cats,
	# not off-board tricks or item spikes.
	if threat_level >= 1:
		_replace_first(deck_cards, &"fishbone_skulker", &"dockside_bruiser")
	if threat_level >= 2:
		_replace_first(deck_cards, &"alley_scrapper", &"boilerback_guardian")
	if threat_level >= 3:
		_replace_first(deck_cards, &"fishbone_skulker", &"captain_ironmaw")
	if threat_level >= 4:
		_replace_first(deck_cards, &"alley_scrapper", &"tavern_mouser")
	if threat_level >= 5:
		_replace_first(deck_cards, &"fishbone_skulker", &"boilerback_guardian")
	if threat_level >= 6:
		_replace_first(deck_cards, &"alley_scrapper", &"captain_ironmaw")
	if threat_level >= 7:
		_replace_first(deck_cards, &"dockside_bruiser", &"boilerback_guardian")
	if threat_level >= 8:
		_replace_first(deck_cards, &"tavern_mouser", &"dockside_bruiser")
	if threat_level >= 9:
		_replace_first(deck_cards, &"dockside_bruiser", &"captain_ironmaw")
	if threat_level >= 10:
		_replace_first(deck_cards, &"tavern_mouser", &"boilerback_guardian")


func _apply_ragclaw_brawler_profile(deck_cards: Array[StringName], threat_level: int) -> void:
	# Simple-core rush: more Quick Paws/Pounce density, no hand-burst tricks.
	if threat_level >= 1:
		_replace_first(deck_cards, &"alley_scrapper", &"candlepaw_scout")
	if threat_level >= 2:
		_replace_first(deck_cards, &"alley_scrapper", &"wharf_cutthroat")
	if threat_level >= 3:
		_replace_first(deck_cards, &"candlepaw_scout", &"netclaw_raider")
	if threat_level >= 4:
		_replace_first(deck_cards, &"alley_scrapper", &"rafter_pouncer")
	if threat_level >= 5:
		_replace_first(deck_cards, &"candlepaw_scout", &"wharf_cutthroat")
	if threat_level >= 6:
		_replace_first(deck_cards, &"alley_scrapper", &"netclaw_raider")
	if threat_level >= 7:
		_replace_first(deck_cards, &"candlepaw_scout", &"rafter_pouncer")
	if threat_level >= 8:
		_replace_first(deck_cards, &"candlepaw_scout", &"wharf_cutthroat")
	if threat_level >= 9:
		_replace_first(deck_cards, &"candlepaw_scout", &"netclaw_raider")
	if threat_level >= 10:
		_replace_first(deck_cards, &"wharf_cutthroat", &"rafter_pouncer")


func _apply_harbor_warden_profile(deck_cards: Array[StringName], threat_level: int) -> void:
	if threat_level >= 1:
		_replace_first(deck_cards, &"fishbone_skulker", &"dockside_bruiser")
	if threat_level >= 2:
		_replace_first(deck_cards, &"alley_scrapper", &"tavern_mouser")
	if threat_level >= 3:
		_replace_first(deck_cards, &"wharf_cutthroat", &"boilerback_guardian")
	if threat_level >= 4:
		_replace_first(deck_cards, &"fishbone_skulker", &"captain_ironmaw")
	if threat_level >= 5:
		_replace_first(deck_cards, &"alley_scrapper", &"boilerback_guardian")
	if threat_level >= 6:
		_replace_first(deck_cards, &"wharf_cutthroat", &"dockside_bruiser")
	if threat_level >= 7:
		_replace_first(deck_cards, &"tavern_mouser", &"captain_ironmaw")
	if threat_level >= 8:
		_replace_first(deck_cards, &"tavern_mouser", &"boilerback_guardian")
	if threat_level >= 9:
		_replace_first(deck_cards, &"dockside_bruiser", &"captain_ironmaw")
	if threat_level >= 10:
		_replace_first(deck_cards, &"tavern_mouser", &"boilerback_guardian")


func _apply_lantern_striker_profile(deck_cards: Array[StringName], threat_level: int) -> void:
	# Simple-core tempo: more mobility and immediate pressure, no hidden hand blows.
	if threat_level >= 1:
		_replace_first(deck_cards, &"fishbone_skulker", &"candlepaw_scout")
	if threat_level >= 2:
		_replace_first(deck_cards, &"alley_scrapper", &"wharf_cutthroat")
	if threat_level >= 3:
		_replace_first(deck_cards, &"fishbone_skulker", &"netclaw_raider")
	if threat_level >= 4:
		_replace_first(deck_cards, &"candlepaw_scout", &"rafter_pouncer")
	if threat_level >= 5:
		_replace_first(deck_cards, &"alley_scrapper", &"netclaw_raider")
	if threat_level >= 6:
		_replace_first(deck_cards, &"fishbone_skulker", &"wharf_cutthroat")
	if threat_level >= 7:
		_replace_first(deck_cards, &"candlepaw_scout", &"rafter_pouncer")
	if threat_level >= 8:
		_replace_first(deck_cards, &"alley_scrapper", &"netclaw_raider")
	if threat_level >= 9:
		_replace_first(deck_cards, &"candlepaw_scout", &"wharf_cutthroat")
	if threat_level >= 10:
		_replace_first(deck_cards, &"candlepaw_scout", &"rafter_pouncer")


func _get_upgrade_line(upgrade_lines: Dictionary, level: int, gaining: bool) -> String:
	var line_set: Dictionary = upgrade_lines.get(level, {})
	if line_set.is_empty():
		return ""
	return str(line_set.get("gain" if gaining else "lose", ""))
