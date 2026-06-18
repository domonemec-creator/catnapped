extends SceneTree


func _init() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    push_error(message)
    quit(1)


func _reset_battlefield(player_state, enemy_state) -> void:
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


func _place(battle, state, lane_index: int, card_id: StringName, owner_id: int):
    var card = battle._create_card_instance(card_id, owner_id)
    state.board[lane_index].occupant = card
    card.lane_index = lane_index
    return card


func _equip(battle, host, item_id: StringName, owner_id: int):
    var item = battle._create_card_instance(item_id, owner_id)
    battle._modify_host_by_item(item, host, 1)
    host.attached_item = item
    host.attached_item_instance_id = item.instance_id
    return item


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

    # --- Test 1: STEAL moves the item and its stats ---
    _reset_battlefield(player_state, enemy_state)
    var my_cat = _place(battle, player_state, 0, &"alley_scrapper", battle.PLAYER_ID)
    var their_cat = _place(battle, enemy_state, 1, &"alley_scrapper", battle.ENEMY_ID)
    var collar = _equip(battle, their_cat, &"spiked_collar", battle.ENEMY_ID)
    var base_attack: int = their_cat.definition.attack
    if their_cat.current_attack != base_attack + 1:
        _fail("Setup: equipped collar did not raise enemy attack.")
        return

    var sticky = battle._create_card_instance(&"sticky_paws", battle.PLAYER_ID)
    player_state.hand.append(sticky)
    battle._selected_card = sticky
    battle._handle_enemy_lane_pressed(1)

    if their_cat.attached_item != null:
        _fail("Steal: enemy cat still has its item.")
        return
    if their_cat.current_attack != base_attack:
        _fail("Steal: enemy attack bonus was not stripped.")
        return
    if my_cat.attached_item != collar:
        _fail("Steal: item did not land on a friendly cat.")
        return
    if my_cat.current_attack != my_cat.definition.attack + 1:
        _fail("Steal: friendly cat did not gain the item bonus.")
        return
    if collar.owner_id != battle.PLAYER_ID:
        _fail("Steal: stolen item ownership did not flip.")
        return
    if not player_state.discard.has(sticky):
        _fail("Steal: Sticky Paws was not discarded.")
        return

    # --- Test 2: DESTROY removes the item and discards it (non-lethal) ---
    _reset_battlefield(player_state, enemy_state)
    var bowled_cat = _place(battle, enemy_state, 1, &"alley_scrapper", battle.ENEMY_ID)
    var bowl = _equip(battle, bowled_cat, &"iron_bowl", battle.ENEMY_ID)
    var base_life: int = bowled_cat.definition.life
    if bowled_cat.current_life != base_life + 2:
        _fail("Setup: equipped bowl did not raise enemy life.")
        return

    var pry = battle._create_card_instance(&"pry_bar", battle.PLAYER_ID)
    player_state.hand.append(pry)
    battle._selected_card = pry
    battle._handle_enemy_lane_pressed(1)

    if bowled_cat.attached_item != null:
        _fail("Destroy: enemy cat still has its item.")
        return
    if bowled_cat.current_life != base_life:
        _fail("Destroy: life bonus was not stripped.")
        return
    if enemy_state.board[1].occupant != bowled_cat:
        _fail("Destroy: non-lethal strip should not have killed the cat.")
        return
    if not enemy_state.discard.has(bowl):
        _fail("Destroy: destroyed item did not go to the enemy discard.")
        return
    if not player_state.discard.has(pry):
        _fail("Destroy: Pry Bar was not discarded.")
        return

    # --- Test 3: DESTROY can be lethal when the stripped Life drops the cat to 0 ---
    _reset_battlefield(player_state, enemy_state)
    var frail_cat = _place(battle, enemy_state, 1, &"candlepaw_scout", battle.ENEMY_ID)
    var lethal_bowl = _equip(battle, frail_cat, &"iron_bowl", battle.ENEMY_ID)
    frail_cat.current_life = 1  # took damage while equipped; stripping -2 is lethal

    var pry2 = battle._create_card_instance(&"pry_bar", battle.PLAYER_ID)
    player_state.hand.append(pry2)
    battle._selected_card = pry2
    battle._handle_enemy_lane_pressed(1)

    if enemy_state.board[1].occupant != null:
        _fail("Lethal destroy: cat should have died when its bowl was stripped.")
        return
    if not enemy_state.discard.has(frail_cat):
        _fail("Lethal destroy: dead cat was not discarded.")
        return
    if not enemy_state.discard.has(lethal_bowl):
        _fail("Lethal destroy: item of the dead cat was not discarded.")
        return

    # --- Test 4: cards are invalid against a cat with no item ---
    _reset_battlefield(player_state, enemy_state)
    _place(battle, enemy_state, 1, &"alley_scrapper", battle.ENEMY_ID)
    var dead_sticky = battle._create_card_instance(&"sticky_paws", battle.PLAYER_ID)
    player_state.hand.append(dead_sticky)
    battle._selected_card = dead_sticky
    battle._handle_enemy_lane_pressed(1)
    if not player_state.hand.has(dead_sticky):
        _fail("Validity: Sticky Paws resolved against an item-less cat.")
        return

    print("Item steal/burn verification passed.")
    quit()
