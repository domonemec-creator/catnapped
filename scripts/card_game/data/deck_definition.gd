class_name DeckDefinition
extends Resource

const DeckEntry = preload("res://scripts/card_game/data/deck_entry.gd")

@export var id: StringName = StringName()
@export var display_name: String = ""
@export var cards: Array[DeckEntry] = []
