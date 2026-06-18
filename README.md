# Catnapped!

Godot prototype of a singleplayer lane-based card battler set in a cat tavern.

## Current entry point

- Main scene: `res://scenes/card_game/battle_scene.tscn`

## Core game

- `1v1` card battle
- `3 lanes`
- card types: `Cat`, `Trick`, `Item`
- player and NPC table powers
- threat-based rematch progression

## Important docs

- [design/catnapped_master_notes.md](design/catnapped_master_notes.md)
- [design/cat_table_card_prototype.md](design/cat_table_card_prototype.md)
- [design/cat_table_hearthstone_hybrid.md](design/cat_table_hearthstone_hybrid.md)

## Multiplayer

The old FPS content was removed, but the generic networking layer was intentionally kept:

- `res://scripts/multiplayer_manager.gd`

It is retained for future multiplayer work on `Catnapped!`.
