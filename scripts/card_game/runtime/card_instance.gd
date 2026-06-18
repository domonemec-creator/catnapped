class_name CardInstance
extends RefCounted

const CardDefinition = preload("res://scripts/card_game/data/card_definition.gd")
const CardGameConstants = preload("res://scripts/card_game/data/card_game_constants.gd")

var instance_id: int = -1
var definition: CardDefinition
var owner_id: int = -1
var current_attack: int = 0
var current_life: int = 0
var lane_index: int = -1
var can_attack: bool = false
var has_attacked: bool = false
var attached_item_instance_id: int = -1
# The actual equipped item instance (persistent), so it can be stolen or destroyed.
# Kept in sync with attached_item_instance_id.
var attached_item: CardInstance = null
var temporary_keywords: Array[StringName] = []
var temporary_attack_bonus: int = 0
var temporary_life_bonus: int = 0


func has_keyword(keyword: StringName) -> bool:
    return definition.keywords.has(keyword) or temporary_keywords.has(keyword)
