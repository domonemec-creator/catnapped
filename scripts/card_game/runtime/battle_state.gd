class_name BattleState
extends RefCounted

const PlayerBattleState = preload("res://scripts/card_game/runtime/player_battle_state.gd")

var turn_number: int = 1
var active_player_id: int = 0
var priority_player_id: int = 0
var player_states: Array[PlayerBattleState] = []
var selected_card_instance_id: int = -1
var battle_over: bool = false
var winner_player_id: int = -1


func get_player_state(player_id: int) -> PlayerBattleState:
    for state in player_states:
        if state.player_id == player_id:
            return state
    return null


func get_enemy_state(player_id: int) -> PlayerBattleState:
    for state in player_states:
        if state.player_id != player_id:
            return state
    return null
