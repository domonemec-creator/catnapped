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

	screen.queue_free()
	progression.reset_state()
	print("Deck building verification passed.")
	quit()
