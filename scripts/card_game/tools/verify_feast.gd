extends SceneTree


func _init() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    push_error(message)
    quit(1)


func _reset(player_state, enemy_state) -> void:
    for state in [player_state, enemy_state]:
        state.hand.clear()
        state.deck.clear()
        state.discard.clear()
        for slot in state.board:
            slot.occupant = null


func _place(battle, state, lane_index: int, card_id: StringName, owner_id: int):
    var card = battle._create_card_instance(card_id, owner_id)
    state.board[lane_index].occupant = card
    card.lane_index = lane_index
    return card


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

    # --- Test 1: another cat dying grows the Feast cat +1/+1 ---
    _reset(player_state, enemy_state)
    var feaster = _place(battle, player_state, 0, &"carrion_prowler", battle.PLAYER_ID)
    var base_atk: int = feaster.definition.attack
    var base_life: int = feaster.definition.life
    var victim = _place(battle, enemy_state, 0, &"candlepaw_scout", battle.ENEMY_ID)
    victim.current_life = 0
    battle._resolve_deaths(enemy_state)

    if feaster.current_attack != base_atk + 1 or feaster.current_life != base_life + 1:
        _fail("Feast: cat did not gain +1/+1 from an enemy death (got %s/%s)." % [feaster.current_attack, feaster.current_life])
        return

    # --- Test 2: a Feast cat does NOT feast on its own death; another Feast cat does ---
    _reset(player_state, enemy_state)
    var dying_feaster = _place(battle, player_state, 0, &"carrion_prowler", battle.PLAYER_ID)
    var other_feaster = _place(battle, player_state, 1, &"carrion_prowler", battle.PLAYER_ID)
    var of_atk: int = other_feaster.definition.attack
    var of_life: int = other_feaster.definition.life
    dying_feaster.current_life = 0
    battle._resolve_deaths(player_state)

    if not player_state.discard.has(dying_feaster):
        _fail("Feast: dying cat was not discarded.")
        return
    if other_feaster.current_attack != of_atk + 1 or other_feaster.current_life != of_life + 1:
        _fail("Feast: surviving Feast cat should gain exactly +1/+1 from one death (got %s/%s)." % [other_feaster.current_attack, other_feaster.current_life])
        return

    # --- Test 3: two deaths in one resolution grow the Feast cat +2/+2 ---
    _reset(player_state, enemy_state)
    var grower = _place(battle, player_state, 0, &"carrion_prowler", battle.PLAYER_ID)
    var g_atk: int = grower.definition.attack
    var g_life: int = grower.definition.life
    var v1 = _place(battle, enemy_state, 0, &"candlepaw_scout", battle.ENEMY_ID)
    var v2 = _place(battle, enemy_state, 1, &"alley_scrapper", battle.ENEMY_ID)
    v1.current_life = 0
    v2.current_life = 0
    battle._resolve_deaths(enemy_state)

    if grower.current_attack != g_atk + 2 or grower.current_life != g_life + 2:
        _fail("Feast: cat should gain +2/+2 from two deaths (got %s/%s)." % [grower.current_attack, grower.current_life])
        return

    # --- Test 4: Hostina má strop FEAST_MAX_STACKS (3 smrti navíc už nic nepřidají) ---
    for i in 4:
        var snack = _place(battle, enemy_state, 2, &"candlepaw_scout", battle.ENEMY_ID)
        snack.current_life = 0
        battle._resolve_deaths(enemy_state)
    if grower.current_attack != g_atk + 3 or grower.current_life != g_life + 3 or grower.feast_stacks != 3:
        _fail("Feast: strop 3× nedodržen (got %s/%s, stacks %s)." % [grower.current_attack, grower.current_life, grower.feast_stacks])
        return

    print("Feast verification passed.")
    quit()
