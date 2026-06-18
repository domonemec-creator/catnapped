class_name PlayerBattleState
extends RefCounted

const CardInstance = preload("res://scripts/card_game/runtime/card_instance.gd")
const LaneSlotState = preload("res://scripts/card_game/runtime/lane_slot_state.gd")

var player_id: int = -1
var display_name: String = ""
var life: int = 10
var tuna_current: int = 0
var tuna_max: int = 0
var deck: Array[CardInstance] = []
var hand: Array[CardInstance] = []
var discard: Array[CardInstance] = []
var board: Array[LaneSlotState] = []
var table_power_id: StringName = StringName()
var table_power_used_this_turn: bool = false


func initialize(player_id_value: int, display_name_value: String, starting_life: int, starting_tuna: int, table_power_id_value: StringName, lane_count: int) -> void:
    player_id = player_id_value
    display_name = display_name_value
    life = starting_life
    tuna_current = starting_tuna
    tuna_max = starting_tuna
    table_power_id = table_power_id_value
    board.clear()
    for lane_index in range(lane_count):
        var slot: LaneSlotState = LaneSlotState.new()
        slot.lane_index = lane_index
        board.append(slot)
