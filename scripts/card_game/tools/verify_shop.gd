extends SceneTree

# Ověřuje logiku obchodu (E3): šupiny za zápasy, nabídky mimo kolekci, nákup, uložení.
# Headless = testovací save (ProgressionSystem._save_path), skutečný save se nedotkne.


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _run() -> void:
	var progression := ProgressionSystem.new()
	progression.reset_state()
	var state := progression.load_state()
	if progression.get_scales(state) != 0:
		_fail("Nový save má mít 0 šupin.")
		return
	if progression.add_match_scales(state, true, 2) != 20 or progression.add_match_scales(state, false) != 3 or progression.add_match_scales(state, true, 0, true) != 5:
		_fail("Šupiny za výhru / prohru / hru ve dvou nesedí.")
		return
	if progression.get_scales(state) != 28:
		_fail("Součet šupin nesedí (%s)." % progression.get_scales(state))
		return

	var offers := progression.roll_shop_offers(state, 7)
	if offers.size() != ProgressionSystem.SHOP_OFFER_COUNT or offers != progression.roll_shop_offers(state, 7):
		_fail("Nabídka má mít 3 karty a se stejným seedem být stejná.")
		return
	var owned := progression.get_collection_card_ids(state)
	for card_id in offers:
		if owned.has(card_id) or String(card_id).ends_with("_token"):
			_fail("Nabídka obsahuje kartu z kolekce nebo žeton: %s." % card_id)
			return

	if progression.buy_card(state, owned[0]) != "Kartu už máš.":
		_fail("Koupit kartu z kolekce nejde.")
		return
	var cheap := &"sardine_can"  # cena 0 → 5 šupin
	if owned.has(cheap):
		_fail("Konzerva nemá být ve startovní kolekci.")
		return
	if progression.get_card_price(cheap) != 5 or progression.get_card_price(&"cannon_cat") != 35:
		_fail("Ceny karet nesedí.")
		return
	if progression.buy_card(state, &"cannon_cat") == "":
		_fail("Dělo za 35 šupin šlo koupit s 28.")
		return
	if progression.buy_card(state, cheap) != "" or progression.get_scales(state) != 23:
		_fail("Nákup konzervy neodečetl šupiny.")
		return
	progression.save_state(state)
	var loaded := progression.load_state()
	if progression.get_scales(loaded) != 23 or not progression.get_collection_card_ids(loaded).has(cheap):
		_fail("Šupiny nebo koupená karta se neuložily.")
		return
	if progression.roll_shop_offers(loaded, 7).has(cheap):
		_fail("Koupená karta je pořád v nabídce.")
		return

	# Výhra v souboji proti AI připíše šupiny a ukáže je ve výsledku.
	progression.reset_state()
	var battle = (load("res://scenes/card_game/battle_scene.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await process_frame
	await process_frame
	battle._battle_state.get_player_state(battle.ENEMY_ID).life = 0
	battle._check_battle_end()
	var after := progression.get_scales(progression.load_state())
	if after < ProgressionSystem.SCALES_WIN_BASE:
		_fail("Výhra nepřipsala šupiny (%s)." % after)
		return
	battle.queue_free()
	await process_frame

	progression.reset_state()
	print("Shop verification passed.")
	quit()
