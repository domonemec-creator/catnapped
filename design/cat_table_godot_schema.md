# Cat Table Godot Schema

## Goal

Use a small data-driven structure that fits Godot well and does not require one custom script per card.

For MVP, use:

- `Resource` for authored game data
- `RefCounted` or plain script objects for runtime state
- one battle scene controller as the orchestration layer

## Recommended folder structure

```text
design/
data/
  cards/
  decks/
  encounters/
  table_powers/
scripts/
  card_game/
    data/
    runtime/
    systems/
    ui/
scenes/
  card_game/
```

## Authoring data types

### `CardDefinition`

Use a `Resource`.

Suggested file:

- `scripts/card_game/data/card_definition.gd`

Fields:

- `id: StringName`
- `display_name: String`
- `card_type: int`
- `cost: int`
- `attack: int`
- `life: int`
- `rules_text: String`
- `keywords: Array[StringName]`
- `effects: Array[CardEffect]`
- `art_path: String`
- `frame_variant: StringName`

Notes:

- `attack` and `life` are `0` for non-Cat cards
- `rules_text` is display text only
- gameplay should read `keywords` and `effects`, not parse text

### `CardEffect`

Use a `Resource` or plain Dictionary-like data Resource.

Fields:

- `trigger: StringName`
- `action: StringName`
- `target_mode: StringName`
- `value: int`
- `value_2: int`
- `keyword_arg: StringName`

For MVP, keep the action vocabulary small.

Recommended triggers:

- `battlecry`
- `last_breath`
- `on_direct_damage`

Recommended actions:

- `draw_cards`
- `discard_cards`
- `deal_damage`
- `heal_life`
- `gain_tuna_next_turn`
- `grant_keyword_until_end_turn`
- `attack_again`
- `return_to_hand`
- `modify_stats`

### `DeckDefinition`

Use a `Resource`.

Fields:

- `id: StringName`
- `display_name: String`
- `cards: Array[DeckEntry]`

### `DeckEntry`

Use a small `Resource` or Dictionary structure.

Fields:

- `card_id: StringName`
- `count: int`

### `TablePowerDefinition`

Use a `Resource`.

Fields:

- `id: StringName`
- `display_name: String`
- `cost: int`
- `rules_text: String`
- `effects: Array[CardEffect]`

### `EncounterDefinition`

Use a `Resource`.

Fields:

- `id: StringName`
- `display_name: String`
- `npc_name: String`
- `portrait_path: String`
- `deck_id: StringName`
- `table_power_id: StringName`
- `starting_life: int`

## Runtime state types

Authoring data should stay immutable. Runtime state should be separate.

### `CardInstance`

Use `RefCounted`.

Fields:

- `instance_id: int`
- `definition: CardDefinition`
- `owner_id: int`
- `current_attack: int`
- `current_life: int`
- `lane_index: int`
- `can_attack: bool`
- `has_attacked: bool`
- `attached_item_instance_id: int`
- `temporary_keywords: Array[StringName]`

### `PlayerBattleState`

Use `RefCounted`.

Fields:

- `player_id: int`
- `display_name: String`
- `life: int`
- `tuna_current: int`
- `tuna_max: int`
- `deck: Array[CardInstance]`
- `hand: Array[CardInstance]`
- `discard: Array[CardInstance]`
- `board: Array[LaneSlotState]`
- `table_power_id: StringName`
- `table_power_used_this_turn: bool`

### `LaneSlotState`

Use `RefCounted`.

Fields:

- `lane_index: int`
- `occupant: CardInstance`

### `BattleState`

Use `RefCounted`.

Fields:

- `turn_number: int`
- `active_player_id: int`
- `priority_player_id: int`
- `player_states: Array[PlayerBattleState]`
- `selected_card_instance_id: int`
- `battle_over: bool`
- `winner_player_id: int`

## Enums and constants

Do not scatter string literals everywhere.

Recommended enums/constants:

- `CardType`: `CAT`, `TRICK`, `ITEM`
- `Keyword`: `BATTLECRY`, `LAST_BREATH`, `QUICK_PAWS`, `GUARD`, `POUNCE`
- `Trigger`: `BATTLECRY`, `LAST_BREATH`, `ON_DIRECT_DAMAGE`
- `TargetMode`: `SELF`, `SELF_OWNER`, `ALLY_CAT`, `ENEMY_CAT`, `OPPOSITE_LANE`, `ADJACENT_LANE`, `ENEMY_PLAYER`

## Systems

### `BattleController`

Main scene orchestrator.

Responsibilities:

- setup battle
- own `BattleState`
- route UI input
- call gameplay systems
- emit signals to UI

### `BattleRules`

Pure rules helper.

Responsibilities:

- validate plays
- validate attack targets
- compute guard interception
- compute pounce targets
- detect lethal

### `DeckSystem`

Responsibilities:

- build runtime deck from `DeckDefinition`
- shuffle
- draw
- mill or fail draw later if needed

### `EffectResolver`

Responsibilities:

- resolve `CardEffect`
- dispatch by `trigger`
- keep effect vocabulary centralized

### `CombatResolver`

Responsibilities:

- apply attack
- apply direct damage
- handle death checks
- queue `Last Breath`

### `AiController`

Responsibilities:

- choose play actions
- choose attack targets
- end turn

Keep it simple in MVP.

## UI scene responsibilities

### `battle_scene.tscn`

- root scene
- board
- HUD
- hand
- selected card panel
- End Turn button

### `card_view.tscn`

- renders one card from `CardInstance`
- never contains gameplay rules
- supports states:
  - idle
  - hover
  - selected
  - playable
  - invalid

### `lane_slot_view.tscn`

- renders empty or occupied lane
- handles highlight states:
  - default
  - valid play
  - valid attack
  - blocked
  - targeted

## Recommended signal flow

Example signals:

- `card_selected(instance_id)`
- `card_play_requested(instance_id, lane_index)`
- `attack_requested(attacker_instance_id, target_lane_index)`
- `turn_ended(player_id)`
- `battle_state_changed()`
- `battle_finished(winner_player_id)`

Keep state changes centralized in `BattleController`.

## Sample `CardDefinition`

```gdscript
class_name CardDefinition
extends Resource

@export var id: StringName
@export var display_name := ""
@export var card_type := 0
@export var cost := 0
@export var attack := 0
@export var life := 0
@export_multiline var rules_text := ""
@export var keywords: Array[StringName] = []
@export var effects: Array[CardEffect] = []
@export_file("*.png") var art_path := ""
@export var frame_variant: StringName = &"default"
```

## Sample starter card data

Shown as pseudo authored data, not as a full copy-paste `.gd` file.

```gdscript
# Alley Scrapper
id = &"alley_scrapper"
display_name = "Alley Scrapper"
card_type = CardType.CAT
cost = 2
attack = 3
life = 2
rules_text = ""
keywords = []
effects = []
```

```gdscript
# Rafter Pouncer
id = &"rafter_pouncer"
display_name = "Rafter Pouncer"
card_type = CardType.CAT
cost = 3
attack = 4
life = 1
rules_text = "Pounce"
keywords = [&"pounce"]
effects = []
```

```gdscript
# Dockside Bruiser
id = &"dockside_bruiser"
display_name = "Dockside Bruiser"
card_type = CardType.CAT
cost = 4
attack = 3
life = 6
rules_text = "Battlecry: Heal 1 Life."
keywords = [&"battlecry"]
effects = [
    {
        "trigger": &"battlecry",
        "action": &"heal_life",
        "target_mode": &"self_owner",
        "value": 1,
    }
]
```

## Sample `DeckDefinition`

```gdscript
deck_id = &"starter_player"
display_name = "Starter Player Deck"
cards = [
    { "card_id": &"alley_scrapper", "count": 2 },
    { "card_id": &"rafter_pouncer", "count": 2 },
    { "card_id": &"dockside_bruiser", "count": 1 },
]
```

## Rules implementation notes

- do not parse card text for gameplay
- do not make one GDScript file per card
- do not let UI nodes own battle truth
- do not put runtime mutable values into authoring Resources

## Minimum keyword logic needed in code

### `Quick Paws`

- on play, set `can_attack = true`

### `Pounce`

- during target validation, allow opposite lane and adjacent lane targets

### `Guard`

- when direct damage would hit player Life through an empty lane, search that lane and adjacent lanes for legal Guards
- if multiple Guards exist, defender chooses one, or MVP can default to nearest lane first

### `Battlecry`

- resolve immediately after successful play

### `Last Breath`

- resolve after death is confirmed, before card fully leaves cleanup queue

## First concrete implementation slice

Build only these data assets first:

- `3` Cat cards
- `1` starter deck
- `1` NPC deck
- `1` NPC encounter
- `1` table power for player
- `1` table power for NPC

If these six assets work end to end, the schema is good enough.
