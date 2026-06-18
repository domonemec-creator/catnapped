class_name LaneSlotState
extends RefCounted

const CardInstance = preload("res://scripts/card_game/runtime/card_instance.gd")

var lane_index: int = -1
var occupant: CardInstance


func is_empty() -> bool:
    return occupant == null
