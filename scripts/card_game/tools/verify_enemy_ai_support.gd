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
        state.saved_tuna_current = 0
        state.table_power_id = StringName()
        state.table_power_used_this_turn = false
        state.immediate_entry_attack_used_this_turn = false
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


func _find_card_lane(state, card) -> int:
    if state == null or card == null:
        return -1
    for lane_index in range(state.board.size()):
        var slot = state.board[lane_index]
        if slot != null and slot.occupant == card:
            return lane_index
    return -1


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

    var enemy_tavern_mouser = battle._create_card_instance(&"tavern_mouser", battle.ENEMY_ID)
    enemy_state.hand.append(enemy_tavern_mouser)

    battle._run_enemy_stub_turn()

    var enemy_tavern_mouser_lane := _find_card_lane(enemy_state, enemy_tavern_mouser)
    if enemy_tavern_mouser_lane < 0:
        _fail("Enemy Tavern Mouser was not played to the board.")
        return
    if player_state.life != 30:
        _fail("Enemy non-Quick Paws cat attacked on the same turn it was played.")
        return
    if enemy_tavern_mouser.has_attacked:
        _fail("Enemy Tavern Mouser should not spend an attack on the same turn it enters play.")
        return
    if enemy_tavern_mouser.can_attack:
        _fail("Enemy Tavern Mouser should remain unready after being played.")
        return

    _reset_battle_state(battle, player_state, enemy_state)

    var enemy_wharf_cutthroat_a = battle._create_card_instance(&"wharf_cutthroat", battle.ENEMY_ID)
    var enemy_wharf_cutthroat_b = battle._create_card_instance(&"wharf_cutthroat", battle.ENEMY_ID)
    enemy_state.hand.append(enemy_wharf_cutthroat_a)
    enemy_state.hand.append(enemy_wharf_cutthroat_b)

    battle._run_enemy_stub_turn()

    var enemy_wharf_cutthroat_lane_a := _find_card_lane(enemy_state, enemy_wharf_cutthroat_a)
    var enemy_wharf_cutthroat_lane_b := _find_card_lane(enemy_state, enemy_wharf_cutthroat_b)
    if enemy_wharf_cutthroat_lane_a < 0 or enemy_wharf_cutthroat_lane_b < 0:
        _fail("Enemy Quick Paws cats were not both played to the board.")
        return
    if player_state.life != 27:
        _fail("Only one newly played Quick Paws cat should attack immediately per turn.")
        return
    var immediate_attack_count := 0
    immediate_attack_count += 1 if enemy_wharf_cutthroat_a.has_attacked else 0
    immediate_attack_count += 1 if enemy_wharf_cutthroat_b.has_attacked else 0
    if immediate_attack_count != 1:
        _fail("Exactly one newly played Quick Paws cat should spend the immediate attack.")
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

    _reset_battle_state(battle, player_state, enemy_state)

    player_state.life = 3
    var player_blocker = battle._create_card_instance(&"dockside_bruiser", battle.PLAYER_ID)
    player_blocker.current_life = 8
    _place_card(player_state, player_blocker, 0)

    var enemy_decoy = battle._create_card_instance(&"alley_scrapper", battle.ENEMY_ID)
    enemy_decoy.current_attack = 2
    var enemy_finisher = battle._create_card_instance(&"alley_scrapper", battle.ENEMY_ID)
    enemy_finisher.current_attack = 2
    var enemy_lethal_collar = battle._create_card_instance(&"spiked_collar", battle.ENEMY_ID)
    _place_card(enemy_state, enemy_decoy, 0, true, false)
    _place_card(enemy_state, enemy_finisher, 2, true, false)
    enemy_state.hand.append(enemy_lethal_collar)

    battle._run_enemy_stub_turn()

    if player_state.life > 0:
        _fail("Enemy did not use Spiked Collar to convert an open lane into lethal.")
        return
    if enemy_finisher.attached_item_instance_id != enemy_lethal_collar.instance_id:
        _fail("Enemy attached Spiked Collar to the wrong attacker instead of the lethal lane.")
        return

    print("Enemy AI support verification passed.")
    quit()
