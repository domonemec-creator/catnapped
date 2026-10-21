extends SceneTree

# Ověřuje snímek stavu pro síťovou hru (D4): serializace a čtení s prohozenými stranami.
# Celý síťový zápas (dva procesy) testuje net_smoke.gd.

const NetBattle = preload("res://scripts/card_game/systems/net_battle.gd")


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _run() -> void:
	var battle = (load("res://scenes/card_game/battle_scene.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await process_frame
	await process_frame
	var state = battle._battle_state
	var me = state.get_player_state(battle.PLAYER_ID)
	var enemy = state.get_player_state(battle.ENEMY_ID)
	# Vylož kočku, ať je na stole co přenášet.
	var cat = null
	for card in me.hand:
		if card.definition.card_type == 0 and card.definition.cost <= me.tuna_current:
			cat = card
			break
	if cat == null:
		_fail("Ve startovní ruce není levná kočka.")
		return
	battle._play_card_to_lane(me, 1, cat)

	var data := NetBattle.serialize_state(state)
	var copy = NetBattle.deserialize_state(data, battle._card_library)
	var my_copy = copy.get_player_state(battle.ENEMY_ID)  # host je u klienta soupeř
	var enemy_copy = copy.get_player_state(battle.PLAYER_ID)
	if my_copy == null or enemy_copy == null:
		_fail("Snímek nemá oba hráče.")
		return
	if copy.active_player_id != battle.ENEMY_ID:
		_fail("Tah hosta má být u klienta tahem soupeře.")
		return
	if my_copy.life != me.life or my_copy.hand.size() != me.hand.size() or my_copy.deck.size() != me.deck.size():
		_fail("Snímek nepřenesl životy / ruku / balík.")
		return
	if enemy_copy.hand.size() != enemy.hand.size():
		_fail("Snímek nepřenesl ruku soupeře.")
		return
	var lane_card = my_copy.board[1].occupant
	if lane_card == null or lane_card.instance_id != cat.instance_id or lane_card.owner_id != battle.ENEMY_ID or lane_card.current_life != cat.current_life:
		_fail("Kočka na stole se nepřenesla správně (id, vlastník, životy).")
		return
	if NetBattle.serialize_state(NetBattle.deserialize_state(NetBattle.serialize_state(copy), battle._card_library)).hash() != data.hash():
		_fail("Dvojí otočení snímku nevrací původní stav.")
		return
	print("Net snapshot verification passed.")
	quit()
