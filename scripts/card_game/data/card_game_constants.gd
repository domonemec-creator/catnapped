class_name CardGameConstants
extends RefCounted

enum CardType {
    CAT,
    TRICK,
    ITEM,
}

const KEYWORD_BATTLECRY := &"battlecry"
const KEYWORD_LAST_BREATH := &"last_breath"
const KEYWORD_QUICK_PAWS := &"quick_paws"
const KEYWORD_GUARD := &"guard"
const KEYWORD_POUNCE := &"pounce"

const TRIGGER_BATTLECRY := &"battlecry"
const TRIGGER_LAST_BREATH := &"last_breath"
const TRIGGER_ON_DIRECT_DAMAGE := &"on_direct_damage"

const TARGET_SELF := &"self"
const TARGET_SELF_OWNER := &"self_owner"
const TARGET_ALLY_CAT := &"ally_cat"
const TARGET_ENEMY_CAT := &"enemy_cat"
const TARGET_ANY_CAT := &"any_cat"
const TARGET_OPPOSITE_LANE := &"opposite_lane"
const TARGET_ADJACENT_LANE := &"adjacent_lane"
const TARGET_ENEMY_PLAYER := &"enemy_player"

const KEYWORD_LABELS := {
    KEYWORD_BATTLECRY: "Battlecry",
    KEYWORD_LAST_BREATH: "Last Breath",
    KEYWORD_QUICK_PAWS: "Quick Paws",
    KEYWORD_GUARD: "Guard",
    KEYWORD_POUNCE: "Pounce",
}

const KEYWORD_SUMMARIES := {
    KEYWORD_BATTLECRY: "Triggers immediately after the card is played.",
    KEYWORD_LAST_BREATH: "Triggers when the cat dies.",
    KEYWORD_QUICK_PAWS: "Can attack on the same turn it is played.",
    KEYWORD_GUARD: "Intercepts direct damage through its lane and adjacent lanes.",
    KEYWORD_POUNCE: "Can attack the opposite lane or one adjacent lane.",
}


static func keyword_label(keyword: StringName) -> String:
    return str(KEYWORD_LABELS.get(keyword, String(keyword).capitalize()))


static func keyword_summary(keyword: StringName) -> String:
    return str(KEYWORD_SUMMARIES.get(keyword, ""))
