class_name LaneSlotView
extends PanelContainer

const CardInstance = preload("res://scripts/card_game/runtime/card_instance.gd")

signal slot_pressed(lane_index: int, owner_id: int)

@onready var lane_label: Label = $Margin/VBox/LaneLabel
@onready var occupant_label: Label = $Margin/VBox/OccupantLabel
@onready var stats_label: Label = $Margin/VBox/StatsLabel
@onready var highlight: ColorRect = $Highlight

var lane_index: int = -1
var owner_id: int = -1
var _card_instance: CardInstance
var _empty_hint: String = "Open lane."

const OWNER_PLAYER := 0
const OWNER_ENEMY := 1

const HIGHLIGHT_NONE := &"none"
const HIGHLIGHT_PLAY := &"play"
const HIGHLIGHT_SELECTED := &"selected"
const HIGHLIGHT_ATTACK := &"attack"

const HIGHLIGHT_COLORS := {
    HIGHLIGHT_PLAY: Color(0.38, 0.9, 0.52, 0.2),
    HIGHLIGHT_SELECTED: Color(0.98, 0.84, 0.38, 0.22),
    HIGHLIGHT_ATTACK: Color(0.92, 0.44, 0.24, 0.22),
}


func _ready() -> void:
    highlight.visible = false


func configure(new_lane_index: int, new_owner_id: int, title: String, empty_hint: String) -> void:
    lane_index = new_lane_index
    owner_id = new_owner_id
    lane_label.text = title
    _empty_hint = empty_hint
    _apply_side_accent()


# Tint the slot per side so the board reads at a glance:
# enemy (top) cool/red = danger, player (bottom) warm green-gold = friendly.
func _apply_side_accent() -> void:
    var base := get_theme_stylebox("panel")
    if not (base is StyleBoxFlat):
        return
    var sb := (base as StyleBoxFlat).duplicate() as StyleBoxFlat
    if owner_id == OWNER_ENEMY:
        sb.bg_color = Color(0.16, 0.08, 0.07, 0.55)
        sb.border_color = Color(0.74, 0.36, 0.30, 0.7)
    else:
        sb.bg_color = Color(0.10, 0.11, 0.07, 0.55)
        sb.border_color = Color(0.6, 0.66, 0.34, 0.72)
    add_theme_stylebox_override("panel", sb)


func set_card_instance(card_instance: CardInstance) -> void:
    _card_instance = card_instance
    if card_instance == null:
        occupant_label.text = "Empty"
        stats_label.text = _empty_hint
    else:
        occupant_label.text = card_instance.definition.display_name
        var ready_text := "Ready" if card_instance.can_attack and not card_instance.has_attacked else "Waiting"
        stats_label.text = "%s / %s | %s" % [card_instance.current_attack, card_instance.current_life, ready_text]


func set_highlight_mode(mode: StringName) -> void:
    if mode == HIGHLIGHT_NONE:
        highlight.visible = false
        return

    highlight.visible = true
    highlight.color = HIGHLIGHT_COLORS.get(mode, HIGHLIGHT_COLORS[HIGHLIGHT_PLAY])


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        slot_pressed.emit(lane_index, owner_id)
        get_viewport().set_input_as_handled()
