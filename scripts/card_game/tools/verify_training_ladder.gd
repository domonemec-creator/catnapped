extends SceneTree

# Ověřuje žebříček tréninku (D-022): odemykání po výhře a sílu soupeře podle stupně.


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _run() -> void:
	var progression := ProgressionSystem.new()
	var state := progression.reset_state()
	var order := ProgressionSystem.TRAINING_ORDER
	if not progression.is_training_unlocked(state, order[0]) or progression.is_training_unlocked(state, order[1]):
		_fail("Na začátku má být odemčený jen první soupeř.")
		return
	if progression.mark_training_win(state, order[1]) != StringName():
		_fail("Výhra nad zamčeným soupeřem nemá nic odemknout.")
		return
	if progression.mark_training_win(state, order[0]) != order[1] or not progression.is_training_unlocked(state, order[1]):
		_fail("Výhra nad prvním soupeřem má odemknout druhého.")
		return
	progression.save_state(state)
	if progression.get_training_cleared(progression.load_state()) != 1:
		_fail("Postup tréninku se neuložil.")
		return

	# Poslední soupeř žebříčku: víc životů a karta navíc.
	var last_id: StringName = order[order.size() - 1]
	var encounter := load("res://data/encounters/%s.tres" % String(last_id)) as EncounterDefinition
	var battle = (load("res://scenes/card_game/battle_scene.tscn") as PackedScene).instantiate()
	battle.startup_encounter_id = last_id
	root.add_child(battle)
	await process_frame
	await process_frame
	var tier := order.size() - 1
	var enemy_state = battle._battle_state.get_player_state(battle.ENEMY_ID)
	if enemy_state.life != encounter.starting_life + tier * battle.TIER_LIFE_BONUS:
		_fail("Soupeř %s. stupně má mít %s životů, má %s." % [tier + 1, encounter.starting_life + tier * battle.TIER_LIFE_BONUS, enemy_state.life])
		return
	if enemy_state.hand.size() != CardGameConstants.starting_hand + 1:
		_fail("Soupeř vyššího stupně má začínat s kartou navíc.")
		return
	progression.reset_state()
	print("Training ladder verification passed.")
	quit()
