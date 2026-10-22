extends SceneTree


func _init() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    push_error(message)
    quit(1)


func _reset_battle_state(battle, player_state, enemy_state) -> void:
    for state in [player_state, enemy_state]:
        state.hand.clear()
        state.deck.clear()
        state.discard.clear()
        state.life = 10
        state.tuna_current = 0
        state.tuna_max = 10
        state.saved_tuna_current = 0
        state.table_power_id = StringName()
        state.table_power_used_this_turn = false
        state.immediate_entry_attack_used_this_turn = false
        for slot in state.board:
            slot.occupant = null

    battle._battle_state.battle_over = false
    battle._battle_state.winner_player_id = -1
    battle._battle_state.active_player_id = battle.PLAYER_ID
    battle._clear_selection_state()


func _place_card(state, card, lane_index: int, can_attack: bool = false, has_attacked: bool = false) -> void:
    state.board[lane_index].occupant = card
    card.lane_index = lane_index
    card.can_attack = can_attack
    card.has_attacked = has_attacked


func _run() -> void:
    var packed_scene := load("res://scenes/card_game/battle_scene.tscn") as PackedScene
    if packed_scene == null:
        _fail("Could not load battle_scene.tscn.")
        return

    var battle = packed_scene.instantiate()
    root.add_child(battle)

    await process_frame
    await process_frame

    battle._dismiss_tutorial_overlay(false)

    var player_state = battle._battle_state.get_player_state(battle.PLAYER_ID)
    var enemy_state = battle._battle_state.get_player_state(battle.ENEMY_ID)
    if player_state == null or enemy_state == null:
        _fail("Missing battle states.")
        return

    _reset_battle_state(battle, player_state, enemy_state)

    player_state.tuna_current = 2
    player_state.saved_tuna_current = 1
    battle._bank_unused_tuna(player_state)
    if player_state.tuna_current != 0:
        _fail("Unused Tuna should be cleared after banking.")
        return
    if player_state.saved_tuna_current != 2:
        _fail("Saved Tuna should cap at 2.")
        return

    _reset_battle_state(battle, player_state, enemy_state)

    var player_target = battle._create_card_instance(&"alley_scrapper", battle.PLAYER_ID)
    var enemy_target = battle._create_card_instance(&"rafter_pouncer", battle.ENEMY_ID)
    if player_target == null or enemy_target == null:
        _fail("Could not create test targets.")
        return
    _place_card(player_state, player_target, 0, false, false)
    _place_card(enemy_state, enemy_target, 0, false, false)

    player_state.tuna_current = 0
    player_state.saved_tuna_current = 1
    var hidden_claws = battle._create_card_instance(&"hidden_claws", battle.PLAYER_ID)
    player_state.hand.append(hidden_claws)
    battle._selected_card = hidden_claws
    battle._handle_enemy_lane_pressed(0)
    if enemy_state.board[0].occupant != null:
        _fail("Saved Tuna should allow a Trick to be cast with no normal Tuna.")
        return
    if player_state.saved_tuna_current != 0:
        _fail("Saved Tuna was not spent on the Trick.")
        return

    _reset_battle_state(battle, player_state, enemy_state)

    var item_host = battle._create_card_instance(&"alley_scrapper", battle.PLAYER_ID)
    if item_host == null:
        _fail("Could not create item host.")
        return
    _place_card(player_state, item_host, 1, false, false)
    player_state.tuna_current = 0
    player_state.saved_tuna_current = 2
    var collar = battle._create_card_instance(&"spiked_collar", battle.PLAYER_ID)
    player_state.hand.append(collar)
    if battle._can_play_card_from_hand(collar, player_state, enemy_state):
        _fail("Saved Tuna must not pay for Items.")
        return

    _reset_battle_state(battle, player_state, enemy_state)

    var enemy_hidden = battle._create_card_instance(&"hidden_claws", battle.ENEMY_ID)
    var player_cat = battle._create_card_instance(&"rafter_pouncer", battle.PLAYER_ID)
    if enemy_hidden == null or player_cat == null:
        _fail("Could not create AI Saved Tuna test cards.")
        return
    _place_card(player_state, player_cat, 2, false, false)
    enemy_state.hand.append(enemy_hidden)
    enemy_state.tuna_current = 0
    enemy_state.saved_tuna_current = 1
    battle._run_enemy_stub_turn()
    if player_state.board[2].occupant != null:
        _fail("Enemy AI did not spend Saved Tuna on a playable Trick.")
        return
    if enemy_state.saved_tuna_current != 0:
        _fail("Enemy AI did not consume Saved Tuna.")
        return

    print("Saved Tuna verification passed.")
    quit()
