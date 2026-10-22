extends SceneTree

# Ověřuje stavění balíku (D2): kolekce, limity kopií a velikosti, odemykání tréninkem, UI tlačítka.


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _run() -> void:
	var progression := ProgressionSystem.new()
	var state := progression.reset_state()
	var deck := progression.get_player_deck_card_ids(state)
	var collection := progression.get_collection_card_ids(state)
	for card_id in deck:
		if not collection.has(card_id):
			_fail("Karta ze startovního balíku chybí v kolekci: %s" % card_id)
			return
	if collection.has(&"smuggler"):
		_fail("Pašerák nemá být v kolekci před výhrou nad Stokovým králem.")
		return
	if progression.add_card_to_deck(state, &"wharf_cutthroat") != state:
		_fail("Karta mimo kolekci nejde přidat.")
		return

	# Minimum velikosti: startovní balík má přesně minimum, odebrat nejde.
	if deck.size() != ProgressionSystem.DECK_MIN_SIZE or progression.can_remove_from_deck(state, deck[0]):
		_fail("Balík na minimu nesmí jít zmenšit.")
		return

	# Výhra v tréninku odemkne karty soupeře.
	progression.mark_training_win(state, ProgressionSystem.TRAINING_ORDER[0])
	if not progression.get_collection_card_ids(state).has(&"wharf_cutthroat"):
		_fail("Výhra nad prvním soupeřem měla odemknout Přístavního hrdlořeze.")
		return
	state = progression.add_card_to_deck(state, &"wharf_cutthroat")
	if progression.get_player_deck_card_ids(state).count(&"wharf_cutthroat") != 1:
		_fail("Přidání odemčené karty selhalo.")
		return

	# Limit kopií.
	for _i in 6:
		state = progression.add_card_to_deck(state, &"wharf_cutthroat")
	if progression.get_player_deck_card_ids(state).count(&"wharf_cutthroat") != ProgressionSystem.MAX_COPIES:
		_fail("Limit %s kopií nedržel." % ProgressionSystem.MAX_COPIES)
		return
	if progression.get_add_block_reason(state, &"captain_ironmaw").is_empty():
		_fail("Kapitán smí být v balíku jen jednou.")
		return

	# Odebraná karta zůstává v kolekci i po uložení.
	state = progression.remove_card_from_deck(state, &"wharf_cutthroat")
	progression.save_state(state)
	var loaded := progression.load_state()
	if progression.get_player_deck_card_ids(loaded).size() != ProgressionSystem.DECK_MIN_SIZE + 3:
		_fail("Upravený balík se neuložil.")
		return
	if not progression.get_collection_card_ids(loaded).has(&"wharf_cutthroat"):
		_fail("Kolekce po uložení ztratila kartu.")
		return

	# UI: tlačítko + v kolekci přidá kartu a uloží.
	var screen = (load("res://scenes/card_game/progression_screen.tscn") as PackedScene).instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var before := progression.get_player_deck_card_ids(progression.load_state()).size()
	var pressed := false
	for row in screen._collection_list.get_children():
		var button := row.get_child(row.get_child_count() - 1) as Button
		if button != null and not button.disabled:
			button.pressed.emit()
			pressed = true
			break
	if not pressed:
		_fail("V kolekci není žádné aktivní tlačítko +.")
		return
	if progression.get_player_deck_card_ids(progression.load_state()).size() != before + 1:
		_fail("Tlačítko + v kolekci neuložilo kartu do balíku.")
		return

	# Hra ve dvou (E5): vlastní balík ze všech karet, tréninkový se nemění.
	var all_ids := progression.get_all_collectible_card_ids()
	if not all_ids.has(&"cannon_cat") or not all_ids.has(&"sardine_can") or all_ids.has(&"stray_token"):
		_fail("Všechny karty pro hru ve dvou nesedí (chybí karta, nebo je tam žeton).")
		return
	var training_before := progression.get_player_deck_card_ids(progression.load_state())
	screen._toggle_pvp_mode()
	await process_frame  # staré řádky mizí přes queue_free
	if screen._collection_list.get_child_count() != all_ids.size():
		_fail("Kolekce ve hře ve dvou neukazuje všechny karty (%s/%s)." % [screen._collection_list.get_child_count(), all_ids.size()])
		return
	# D-029: výchozí balík ve dvou je hratelný (přesně 30, nejvýš 3 kopie).
	var default_pvp := progression.get_deck_card_ids(progression.load_state(), true)
	if default_pvp.size() != ProgressionSystem.PVP_DECK_SIZE or not progression.get_deck_problem(default_pvp, true).is_empty():
		_fail("Výchozí balík pro hru ve dvou není platný (%s karet)." % default_pvp.size())
		return
	if not progression.get_add_block_reason(progression.load_state(), &"cannon_cat", true).begins_with("Balík je plný"):
		_fail("Plný balík ve dvou (30) šel zvětšit.")
		return
	screen._change_deck(default_pvp[0], false)
	var short_deck := progression.get_deck_card_ids(progression.load_state(), true)
	if short_deck.size() != ProgressionSystem.PVP_DECK_SIZE - 1 or progression.get_deck_problem(short_deck, true).is_empty():
		_fail("Balík ve dvou s 29 kartami musí být neplatný.")
		return
	screen._change_deck(&"cannon_cat", true)
	var after_state := progression.load_state()
	if not progression.get_deck_card_ids(after_state, true).has(&"cannon_cat"):
		_fail("Karta se nepřidala do balíku pro hru ve dvou.")
		return
	if progression.get_player_deck_card_ids(after_state) != training_before:
		_fail("Úprava balíku pro hru ve dvou změnila tréninkový balík.")
		return
	if progression.get_collection_card_ids(after_state).has(&"cannon_cat") and not training_before.has(&"cannon_cat"):
		_fail("Karta z balíku pro hru ve dvou prosákla do tréninkové kolekce.")
		return

	# Limit 3 kopií ve dvou a Doplnit zpátky na 30.
	var copy_state := progression.load_state()
	for i in 4:
		copy_state = progression.add_card_to_deck(copy_state, &"lamplighter", true)
	var copy_deck := progression.get_deck_card_ids(copy_state, true)
	if copy_deck.count(&"lamplighter") > ProgressionSystem.PVP_MAX_COPIES:
		_fail("Ve hře ve dvou prošla 4. kopie.")
		return
	progression.save_state(copy_state)
	screen._refresh_ui()
	screen._fill_deck()
	var filled := progression.get_deck_card_ids(progression.load_state(), true)
	if filled.size() != ProgressionSystem.PVP_DECK_SIZE or not progression.get_deck_problem(filled, true).is_empty():
		_fail("Doplnit nevyrobilo platný balík (%s karet: %s)." % [filled.size(), progression.get_deck_problem(filled, true)])
		return

	screen.queue_free()
	progression.reset_state()
	print("Deck building verification passed.")
	quit()
