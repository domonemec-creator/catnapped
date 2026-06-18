class_name TablePowerDefinition
extends Resource

const CardEffect = preload("res://scripts/card_game/data/card_effect.gd")

@export var id: StringName = StringName()
@export var display_name: String = ""
@export var cost: int = 0
@export_multiline var rules_text: String = ""
@export var effects: Array[CardEffect] = []
