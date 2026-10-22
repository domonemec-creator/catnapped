extends SceneTree

# Ověřuje Tuna kartu Sardinková konzerva (E2): +2 Tuny v tomto tahu, AI ji hraje jen
# když tím odemkne dražší kartu z ruky.


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _reset(battle, state, tuna: int) -> void:
	state.hand.clear()
	state.discard.clear()
	state.deck.clear()
	state.life = 20
	state.tuna_current = tuna
	state.tuna_max = tuna
	state.saved_tuna_current = 0
	for slot in state.board:
		slot.occupant = null
	battle._battle_state.battle_over = false


func _run() -> void:
	var battle = (load("res://scenes/card_game/battle_scene.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await process_frame
	await process_frame
	var player_state = battle._battle_state.get_player_state(battle.PLAYER_ID)
	var enemy_state = battle._battle_state.get_player_state(battle.ENEMY_ID)

	# Hráč: 1 Tuna + konzerva = 3 Tuny.
	_reset(battle, player_state, 1)
	_reset(battle, enemy_state, 1)
	battle._battle_state.active_player_id = battle.PLAYER_ID
	var can = battle._create_card_instance(&"sardine_can", battle.PLAYER_ID)
	if can == null:
		_fail("Sardinková konzerva chybí v knihovně.")
		return
	player_state.hand.append(can)
	if not battle._try_play_untargeted(player_state, can):
		_fail("Konzerva nejde zahrát bez cíle.")
		return
	if player_state.tuna_current != 3 or not player_state.discard.has(can) or player_state.hand.has(can):
		_fail("Konzerva má dát +2 Tuny a jít do odhozu (Tuna %s)." % player_state.tuna_current)
		return

	# AI: 3 Tuny, v ruce konzerva a kočka za 5 → zahraje obojí.
	_reset(battle, player_state, 3)
	_reset(battle, enemy_state, 3)
	battle._battle_state.active_player_id = battle.ENEMY_ID
	var enemy_can = battle._create_card_instance(&"sardine_can", battle.ENEMY_ID)
	var veteran = battle._create_card_instance(&"grey_veteran", battle.ENEMY_ID)
	enemy_state.hand.append(enemy_can)
	enemy_state.hand.append(veteran)
	battle._run_enemy_stub_turn()
	if not enemy_state.discard.has(enemy_can) or veteran.lane_index < 0:
		_fail("AI nevyužila konzervu na dražší kočku.")
		return

	# AI: nic dražšího v ruce → konzervu si nechá.
	_reset(battle, player_state, 3)
	_reset(battle, enemy_state, 3)
	battle._battle_state.active_player_id = battle.ENEMY_ID
	var kept_can = battle._create_card_instance(&"sardine_can", battle.ENEMY_ID)
	var scout = battle._create_card_instance(&"candlepaw_scout", battle.ENEMY_ID)
	enemy_state.hand.append(kept_can)
	enemy_state.hand.append(scout)
	battle._run_enemy_stub_turn()
	if not enemy_state.hand.has(kept_can):
		_fail("AI zahrála konzervu zbytečně.")
		return

	print("Sardine can verification passed.")
	quit()
