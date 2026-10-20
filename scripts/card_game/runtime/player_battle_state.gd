class_name PlayerBattleState
extends RefCounted

const CardInstance = preload("res://scripts/card_game/runtime/card_instance.gd")
const LaneSlotState = preload("res://scripts/card_game/runtime/lane_slot_state.gd")

var player_id: int = -1
var display_name: String = ""
var life: int = 10
var max_life: int = 10
var tuna_current: int = 0
var tuna_max: int = 0
var saved_tuna_current: int = 0
var deck: Array[CardInstance] = []
var hand: Array[CardInstance] = []
var discard: Array[CardInstance] = []
var board: Array[LaneSlotState] = []
var table_power_id: StringName = StringName()
var table_power_used_this_turn: bool = false
var immediate_entry_attack_used_this_turn: bool = false
# False until this player has begun their first turn. The first turn does not ramp
# Tuna, so both sides actually open on the locked 3 Tuna (the player who moves first
# trades that for initiative; the second mover's compensation is the extra turn-1 draw).
var has_started_turn: bool = false
# Hlad (D-017): kolikrát už hráč chtěl líznout z prázdného balíku. Každý další hlad bolí víc.
var hunger_count: int = 0


func initialize(player_id_value: int, display_name_value: String, starting_life: int, starting_tuna: int, table_power_id_value: StringName, lane_count: int) -> void:
    player_id = player_id_value
    display_name = display_name_value
    life = starting_life
    max_life = starting_life
    tuna_current = starting_tuna
    tuna_max = starting_tuna
    saved_tuna_current = 0
    table_power_id = table_power_id_value
    immediate_entry_attack_used_this_turn = false
    has_started_turn = false
    board.clear()
    for lane_index in range(lane_count):
        var slot: LaneSlotState = LaneSlotState.new()
        slot.lane_index = lane_index
        board.append(slot)
