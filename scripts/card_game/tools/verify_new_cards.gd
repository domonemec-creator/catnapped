extends SceneTree

# Ověřuje efekty nových karet (D-016): zranění kočce naproti, posílení sousedů,
# vyvolání po smrti a líznutí při přímém zásahu.

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	_failed = true
	push_error(message)
	quit(1)


func _reset(battle, player_state, enemy_state) -> void:
	for state in [player_state, enemy_state]:
		state.hand.clear()
		state.discard.clear()
		state.life = 20
		state.max_life = 20
		state.tuna_current = 10
		state.tuna_max = 10
		state.saved_tuna_current = 0
		state.immediate_entry_attack_used_this_turn = false
		for slot in state.board:
			slot.occupant = null
	battle._battle_state.battle_over = false
	battle._battle_state.active_player_id = battle.PLAYER_ID


func _place(state, card, lane: int) -> void:
	state.board[lane].occupant = card
	card.lane_index = lane
	card.can_attack = true
	card.has_attacked = false


func _run() -> void:
	var battle = (load("res://scenes/card_game/battle_scene.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await process_frame
	await process_frame
	var player_state = battle._battle_state.get_player_state(battle.PLAYER_ID)
	var enemy_state = battle._battle_state.get_player_state(battle.ENEMY_ID)

	for card_id in [&"lamplighter", &"dock_harpooner", &"pickpocket", &"stray_mother", &"galley_cook", &"harbor_drummer", &"grey_veteran", &"carrion_prowler", &"graveyard_glutton", &"ship_lookout", &"smuggler"]:
		if battle._create_card_instance(card_id, battle.PLAYER_ID) == null:
			_fail("Card %s is missing from the library." % card_id)
			return

	# Harpunář: 2 zranění kočce naproti, zabije 2-životovou kočku.
	_reset(battle, player_state, enemy_state)
	var victim = battle._create_card_instance(&"alley_scrapper", battle.ENEMY_ID)
	_place(enemy_state, victim, 1)
	var harpooner = battle._create_card_instance(&"dock_harpooner", battle.PLAYER_ID)
	player_state.hand.append(harpooner)
	battle._play_card_to_lane(player_state, 1, harpooner)
	if enemy_state.board[1].occupant != null:
		_fail("Dock Harpooner battlecry should kill the 2-life cat opposite.")
		return

	# Lampářka: 1 zranění, kočka naproti přežije se sníženými životy.
	_reset(battle, player_state, enemy_state)
	var sturdy = battle._create_card_instance(&"tavern_mouser", battle.ENEMY_ID)
	_place(enemy_state, sturdy, 0)
	var lamp = battle._create_card_instance(&"lamplighter", battle.PLAYER_ID)
	player_state.hand.append(lamp)
	battle._play_card_to_lane(player_state, 0, lamp)
	if sturdy.current_life != sturdy.definition.life - 1:
		_fail("Lamplighter should deal 1 damage to the opposite cat (expected %s life, got %s)." % [sturdy.definition.life - 1, sturdy.current_life])
		return

	# Bubeník a kuchař: sousedé +1 útok / +1 život, vzdálená lajna nic.
	_reset(battle, player_state, enemy_state)
	var left = battle._create_card_instance(&"alley_scrapper", battle.PLAYER_ID)
	var right = battle._create_card_instance(&"alley_scrapper", battle.PLAYER_ID)
	_place(player_state, left, 0)
	_place(player_state, right, 2)
	var drummer = battle._create_card_instance(&"harbor_drummer", battle.PLAYER_ID)
	player_state.hand.append(drummer)
	battle._play_card_to_lane(player_state, 1, drummer)
	if left.current_attack != 4 or right.current_attack != 4:
		_fail("Harbor Drummer should give adjacent cats +1 attack.")
		return
	if drummer.current_attack != 3:
		_fail("Harbor Drummer must not buff itself.")
		return
	_reset(battle, player_state, enemy_state)
	var buddy = battle._create_card_instance(&"tavern_mouser", battle.PLAYER_ID)
	var far_cat = battle._create_card_instance(&"tavern_mouser", battle.PLAYER_ID)
	_place(player_state, buddy, 1)
	_place(player_state, far_cat, 2)
	var cook = battle._create_card_instance(&"galley_cook", battle.PLAYER_ID)
	player_state.hand.append(cook)
	battle._play_card_to_lane(player_state, 0, cook)
	if buddy.current_life != buddy.definition.life + 1 or far_cat.current_life != far_cat.definition.life:
		_fail("Galley Cook should give only the adjacent cat +1 life.")
		return

	# Toulavá máma: po smrti vyvolá Tuláka do své lajny.
	_reset(battle, player_state, enemy_state)
	var mother = battle._create_card_instance(&"stray_mother", battle.PLAYER_ID)
	_place(player_state, mother, 2)
	var killer = battle._create_card_instance(&"rafter_pouncer", battle.ENEMY_ID)
	_place(enemy_state, killer, 2)
	killer.current_attack = 5
	battle._perform_attack(enemy_state, player_state, killer, 2)
	var token = player_state.board[2].occupant
	if token == null or token.definition.id != &"stray_token":
		_fail("Stray Mother should leave a Stray token in her lane after dying.")
		return

	# Kapsář: přímý zásah = líznutí karty.
	_reset(battle, player_state, enemy_state)
	var pick = battle._create_card_instance(&"pickpocket", battle.PLAYER_ID)
	_place(player_state, pick, 0)
	var hand_before: int = player_state.hand.size()
	var deck_before: int = player_state.deck.size()
	battle._perform_attack(player_state, enemy_state, pick, 0)
	if deck_before > 0 and player_state.hand.size() != hand_before + 1:
		_fail("Pickpocket should draw a card on direct damage.")
		return
	if enemy_state.life != 19:
		_fail("Pickpocket direct hit should deal 1 damage.")
		return

	# Hlad (D-017): prázdný balík bere 1, pak 2 životy.
	_reset(battle, player_state, enemy_state)
	player_state.deck.clear()
	player_state.hunger_count = 0
	player_state.has_started_turn = true
	battle._start_turn(player_state)
	if player_state.life != 19:
		_fail("First hunger should cost 1 life (expected 19, got %s)." % player_state.life)
		return
	battle._start_turn(player_state)
	if player_state.life != 17:
		_fail("Second hunger should cost 2 life (expected 17, got %s)." % player_state.life)
		return

	if not _failed:
		print("New cards verification passed.")
		quit()
