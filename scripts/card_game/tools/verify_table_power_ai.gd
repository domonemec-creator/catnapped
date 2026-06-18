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
        state.tuna_current = 10
        state.tuna_max = 10
        state.table_power_used_this_turn = false
        for slot in state.board:
            slot.occupant = null

    battle._battle_state.battle_over = false
    battle._battle_state.winner_player_id = -1
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

    var player_state = battle._battle_state.get_player_state(battle.PLAYER_ID)
    var enemy_state = battle._battle_state.get_player_state(battle.ENEMY_ID)
    if player_state == null or enemy_state == null:
        _fail("Missing battle states.")
        return

    _reset_battle_state(battle, player_state, enemy_state)
    enemy_state.table_power_id = &"treat_toss"
    var player_cat = battle._create_card_instance(&"alley_scrapper", battle.PLAYER_ID)
    _place_card(player_state, player_cat, 1)

    battle._run_enemy_stub_turn()

    if enemy_state.board[1].occupant == null or enemy_state.board[1].occupant.definition.id != &"stray_token":
        _fail("Enemy Treat Toss did not summon into the pressured lane.")
        return
    if not enemy_state.table_power_used_this_turn:
        _fail("Enemy Treat Toss was not marked as used.")
        return

    _reset_battle_state(battle, player_state, enemy_state)
    enemy_state.table_power_id = &"smug_glare"
    enemy_state.life = 6
    player_state.hand.append(battle._create_card_instance(&"alley_scrapper", battle.PLAYER_ID))

    battle._run_enemy_stub_turn()

    if enemy_state.life != 7:
        _fail("Enemy Smug Glare did not heal life.")
        return
    if not enemy_state.table_power_used_this_turn:
        _fail("Enemy Smug Glare was not marked as used.")
        return

    _reset_battle_state(battle, player_state, enemy_state)
    enemy_state.table_power_id = &"smug_glare"

    battle._run_enemy_stub_turn()

    if enemy_state.table_power_used_this_turn:
        _fail("Enemy Smug Glare should not fire with no hand info and no healing value.")
        return

    print("Table power AI verification passed.")
    quit()
