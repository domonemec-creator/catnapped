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

    player_state.life = 1
    battle._adjust_player_life(player_state, -3)
    if player_state.life != 0:
        _fail("Player Life should clamp to 0 after lethal direct damage.")
        return

    battle._clear_selection_state()
    battle._battle_state.battle_over = false
    battle._battle_state.winner_player_id = -1

    var buff_target = battle._create_card_instance(&"alley_scrapper", battle.PLAYER_ID)
    buff_target.current_life = 1
    buff_target.temporary_life_bonus = 2
    player_state.board[1].occupant = buff_target
    buff_target.lane_index = 1

    battle._clear_end_of_turn_modifiers(player_state)
    if not player_state.discard.has(buff_target):
        _fail("Card with 0 Life should be sent to discard after cleanup.")
        return
    if buff_target.current_life != 0:
        _fail("Card Life should clamp to 0 when removing temporary life bonus.")
        return

    print("Life floor verification passed.")
    quit()
