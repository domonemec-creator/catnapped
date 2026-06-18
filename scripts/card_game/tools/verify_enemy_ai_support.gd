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
        state.life = 30
        state.tuna_current = 10
        state.tuna_max = 10
        state.table_power_id = StringName()
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

    var player_scrapper = battle._create_card_instance(&"alley_scrapper", battle.PLAYER_ID)
    var enemy_hidden_claws = battle._create_card_instance(&"hidden_claws", battle.ENEMY_ID)
    _place_card(player_state, player_scrapper, 1)
    enemy_state.hand.append(enemy_hidden_claws)

    battle._run_enemy_stub_turn()

    if player_state.board[1].occupant != null:
        _fail("Enemy Hidden Claws did not clear the target lane.")
        return
    if not enemy_state.discard.has(enemy_hidden_claws):
        _fail("Enemy Hidden Claws was not discarded.")
        return
    if not player_state.discard.has(player_scrapper):
        _fail("Killed player cat was not moved to discard.")
        return

    _reset_battle_state(battle, player_state, enemy_state)

    var enemy_attacker = battle._create_card_instance(&"alley_scrapper", battle.ENEMY_ID)
    var enemy_fish_toss = battle._create_card_instance(&"fish_toss", battle.ENEMY_ID)
    _place_card(enemy_state, enemy_attacker, 0, false, true)
    enemy_state.hand.append(enemy_fish_toss)

    battle._run_enemy_stub_turn()

    if not enemy_state.discard.has(enemy_fish_toss):
        _fail("Enemy Fish Toss was not discarded.")
        return
    if player_state.life != 27:
        _fail("Enemy Fish Toss did not lead to the expected follow-up attack.")
        return
    if not enemy_attacker.has_attacked:
        _fail("Enemy attacker did not spend its refreshed attack.")
        return

    _reset_battle_state(battle, player_state, enemy_state)

    var enemy_item_target = battle._create_card_instance(&"alley_scrapper", battle.ENEMY_ID)
    var enemy_spiked_collar = battle._create_card_instance(&"spiked_collar", battle.ENEMY_ID)
    _place_card(enemy_state, enemy_item_target, 2, false, false)
    enemy_state.hand.append(enemy_spiked_collar)

    battle._run_enemy_stub_turn()

    if enemy_item_target.current_attack != enemy_item_target.definition.attack + 1:
        _fail("Enemy Spiked Collar did not buff attack.")
        return
    if enemy_item_target.attached_item_instance_id != enemy_spiked_collar.instance_id:
        _fail("Enemy Spiked Collar did not attach to the target.")
        return
    if enemy_item_target.attached_item != enemy_spiked_collar:
        _fail("Enemy Spiked Collar is not the persistent attached item.")
        return
    if enemy_state.discard.has(enemy_spiked_collar):
        _fail("Equipped Spiked Collar should stay on the cat, not go to discard.")
        return

    print("Enemy AI support verification passed.")
    quit()
