class_name CardDefinition
extends Resource

const CardGameConstants = preload("res://scripts/card_game/data/card_game_constants.gd")
const CardEffect = preload("res://scripts/card_game/data/card_effect.gd")

@export var id: StringName = StringName()
@export var display_name: String = ""
@export var card_type: int = CardGameConstants.CardType.CAT
@export var cost: int = 0
@export var attack: int = 0
@export var life: int = 0
@export_multiline var rules_text: String = ""
@export var keywords: Array[StringName] = []
@export var effects: Array[CardEffect] = []
@export_file("*.png") var art_path: String = ""
@export var frame_variant: StringName = &"default"
