class_name CardGameConstants
extends RefCounted

enum CardType {
    CAT,
    TRICK,
    ITEM,
}

const SAVED_TUNA_CAP := 2
# Odveta (D-014): napadená kočka vrací útočníkovi úder svým útokem. Static var, aby šlo
# v simulaci porovnat obě varianty; ve hře se nemění.
static var combat_retaliation := true
# Ekonomika karet (D-015): líznutí za tah a startovní ruka. Static var kvůli A/B simulaci.
static var draw_per_turn := 1
static var starting_hand := 4
# Ochrana kryje přímý zásah i ze sousedních lajn (D-019). Static var kvůli A/B simulaci.
static var guard_covers_adjacent := true
# Žebříček tréninku (D-022): hrozba podle pořadí soupeře. Simulace ho vypne argumentem „noladder“.
static var training_ladder := true
# Experiment (výměny): útočník udeří první, odveta jen od přeživší kočky. Ve hře vypnuto.
static var attacker_first_strike := false
# Počítadla pro simulaci: útoky na kočku a kolik z nich skončilo smrtí obou.
static var stat_cat_attacks := 0
static var stat_mutual_kills := 0

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
    KEYWORD_BATTLECRY: "Bojový nástup",
    KEYWORD_LAST_BREATH: "Poslední dech",
    KEYWORD_QUICK_PAWS: "Rychlé tlapy",
    KEYWORD_GUARD: "Ochrana",
    KEYWORD_POUNCE: "Výpad",
    KEYWORD_FEAST: "Hostina",
}

const KEYWORD_SUMMARIES := {
    KEYWORD_BATTLECRY: "Spustí se hned po vyložení karty.",
    KEYWORD_LAST_BREATH: "Spustí se při smrti kočky.",
    KEYWORD_QUICK_PAWS: "V tahu může hned útočit jen jedna nová kočka s tímto klíčovým slovem.",
    KEYWORD_GUARD: "Zachytí přímé zranění ve své lajně i v sousedních lajnách.",
    KEYWORD_POUNCE: "Může útočit na protilehlou nebo sousední lajnu.",
    KEYWORD_FEAST: "Když umře jakákoliv jiná kočka, tahle získá +1/+1 napevno.",
}


static func keyword_label(keyword: StringName) -> String:
    return str(KEYWORD_LABELS.get(keyword, String(keyword).capitalize()))


static func keyword_summary(keyword: StringName) -> String:
    return str(KEYWORD_SUMMARIES.get(keyword, ""))
