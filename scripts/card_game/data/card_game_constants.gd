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
const KEYWORD_FEAST := &"feast"

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
    KEYWORD_BATTLECRY: "Bojovy nastup",
    KEYWORD_LAST_BREATH: "Posledni dech",
    KEYWORD_QUICK_PAWS: "Rychle tlapy",
    KEYWORD_GUARD: "Ochrana",
    KEYWORD_POUNCE: "Vypad",
    KEYWORD_FEAST: "Hostina",
}

const KEYWORD_SUMMARIES := {
    KEYWORD_BATTLECRY: "Spusti se hned po vylozeni karty.",
    KEYWORD_LAST_BREATH: "Spusti se pri smrti kocky.",
    KEYWORD_QUICK_PAWS: "V tahu muze hned utocit jen jedna nova kocka s timto keywordem.",
    KEYWORD_GUARD: "Zachyti prime zraneni ve sve lajne i sousednich lajnach.",
    KEYWORD_POUNCE: "Muze utocit na protilehlou nebo sousedni lajnu.",
    KEYWORD_FEAST: "Kdyz umre jakakoliv jina kocka, tahle ziska +1/+1 napevno.",
}


static func keyword_label(keyword: StringName) -> String:
    return str(KEYWORD_LABELS.get(keyword, String(keyword).capitalize()))


static func keyword_summary(keyword: StringName) -> String:
    return str(KEYWORD_SUMMARIES.get(keyword, ""))
