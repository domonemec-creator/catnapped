extends SceneTree


func _init() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    push_error(message)
    quit(1)


func _run() -> void:
    var packed_scene := load("res://scenes/card_game/battle_scene.tscn") as PackedScene
    if packed_scene == null:
        _fail("Could not load battle_scene.tscn.")
        return

    var battle = packed_scene.instantiate()
    root.add_child(battle)

    await process_frame
    await process_frame

    var player_state = battle._battle_state.get_player_state(battle.PLAYER_ID)
    var enemy_state = battle._battle_state.get_player_state(battle.ENEMY_ID)
    if player_state == null or enemy_state == null:
        _fail("Missing battle states.")
        return

    player_state.hand.clear()
    player_state.deck.clear()
    player_state.discard.clear()
    enemy_state.hand.clear()
    enemy_state.deck.clear()
    enemy_state.discard.clear()
    player_state.tuna_current = 10
    player_state.tuna_max = 10
    enemy_state.tuna_current = 10
    enemy_state.tuna_max = 10

    for slot in player_state.board:
        slot.occupant = null
    for slot in enemy_state.board:
        slot.occupant = null

    var alley = battle._create_card_instance(&"alley_scrapper", battle.PLAYER_ID)
    player_state.hand.append(alley)
    battle._selected_card = alley
    battle._handle_player_lane_pressed(0)
    if player_state.board[0].occupant != alley:
        _fail("Cat play failed.")
        return

    var catnip = battle._create_card_instance(&"catnip_burst", battle.PLAYER_ID)
    player_state.hand.append(catnip)
    battle._selected_card = catnip
    battle._handle_player_lane_pressed(0)
    if alley.current_attack != alley.definition.attack + 2:
        _fail("Temporary attack buff failed.")
        return
    if alley.temporary_attack_bonus != 2:
        _fail("Temporary attack tracking failed.")
        return
    if not player_state.discard.has(catnip):
        _fail("Trick card was not discarded.")
        return

    battle._clear_end_of_turn_modifiers(player_state)
    if alley.current_attack != alley.definition.attack:
        _fail("End-turn cleanup failed.")
        return

    player_state.tuna_current = 10
    var collar = battle._create_card_instance(&"spiked_collar", battle.PLAYER_ID)
    player_state.hand.append(collar)
    battle._selected_card = collar
    battle._handle_player_lane_pressed(0)
    if alley.current_attack != alley.definition.attack + 1:
        _fail("Item attack bonus failed.")
        return
    if alley.attached_item_instance_id < 0:
        _fail("Item attachment tracking failed.")
        return

    var enemy_alley = battle._create_card_instance(&"alley_scrapper", battle.ENEMY_ID)
    enemy_state.board[1].occupant = enemy_alley
    enemy_alley.lane_index = 1

    player_state.tuna_current = 10
    var hidden = battle._create_card_instance(&"hidden_claws", battle.PLAYER_ID)
    player_state.hand.append(hidden)
    battle._selected_card = hidden
    battle._handle_enemy_lane_pressed(1)
    if enemy_state.board[1].occupant != null:
        _fail("Enemy damage trick did not remove the target.")
        return
    if enemy_state.discard.is_empty():
        _fail("Killed enemy card was not discarded.")
        return

    var scout = battle._create_card_instance(&"candlepaw_scout", battle.ENEMY_ID)
    enemy_state.board[2].occupant = scout
    scout.lane_index = 2

    player_state.tuna_current = 10
    var table_flip = battle._create_card_instance(&"table_flip", battle.PLAYER_ID)
    player_state.hand.append(table_flip)
    battle._selected_card = table_flip
    battle._handle_enemy_lane_pressed(2)
    if enemy_state.board[2].occupant != null:
        _fail("Return-to-hand trick did not clear the board lane.")
        return
    if not enemy_state.hand.has(scout):
        _fail("Returned enemy card was not added to hand.")
        return
    if scout.current_attack != scout.definition.attack or scout.current_life != scout.definition.life:
        _fail("Returned card was not reset to base stats.")
        return

    print("Trick/Item verification passed.")
    quit()
