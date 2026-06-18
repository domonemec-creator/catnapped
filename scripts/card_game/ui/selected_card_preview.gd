class_name SelectedCardPreview
extends Control

const CardGameConstants = preload("res://scripts/card_game/data/card_game_constants.gd")
const CardInstance = preload("res://scripts/card_game/runtime/card_instance.gd")
const CardTextFormatter = preload("res://scripts/card_game/ui/card_text_formatter.gd")

const CAT_FRAME_PATH := "res://assets/card_game/card_frames/cat_frame.png"
const TRICK_FRAME_PATH := "res://assets/card_game/card_frames/trick_frame.png"
const ITEM_FRAME_PATH := "res://assets/card_game/card_frames/item_frame.png"

const LAYOUTS := {
    CardGameConstants.CardType.CAT: {
        "canvas_size": Vector2(258, 387),
        "art_rect": Rect2(28, 18, 202, 168),
        "cost_rect": Rect2(8, 18, 48, 54),
        "name_rect": Rect2(34, 194, 196, 34),
        "rules_rect": Rect2(44, 248, 176, 76),
        "attack_rect": Rect2(14, 340, 44, 36),
        "life_rect": Rect2(206, 340, 38, 36),
        "type_rect": Rect2(79, 341, 100, 28),
        "show_stats": true,
        "show_name": true,
        "show_type_badge": false,
        "name_mode": "display_name",
        "placeholder": "",
        "frame_path": CAT_FRAME_PATH,
        "title_color": Color(0.96, 0.93, 0.88, 1.0),
        "text_color": Color(0.25, 0.18, 0.12, 1.0),
        "accent_color": Color(1, 1, 1, 1.0),
        "badge_bg": Color(0.1, 0.2, 0.28, 0.92),
        "badge_border": Color(0.83, 0.68, 0.36, 1.0),
        "art_bg": Color(0.07, 0.08, 0.1, 0.0),
        "name_font_size": 20,
        "rules_font_size": 15,
        "cost_font_size": 28,
        "stat_font_size": 28,
        "type_font_size": 18,
        "art_font_size": 26,
    },
    CardGameConstants.CardType.TRICK: {
        "canvas_size": Vector2(258, 387),
        "art_rect": Rect2(28, 18, 202, 160),
        "cost_rect": Rect2(106, 4, 46, 44),
        "name_rect": Rect2(32, 194, 200, 32),
        "rules_rect": Rect2(48, 252, 168, 78),
        "attack_rect": Rect2(0, 0, 0, 0),
        "life_rect": Rect2(0, 0, 0, 0),
        "type_rect": Rect2(0, 0, 0, 0),
        "show_stats": false,
        "show_name": true,
        "show_type_badge": false,
        "name_mode": "type_label",
        "placeholder": "",
        "frame_path": TRICK_FRAME_PATH,
        "title_color": Color(0.98, 0.91, 0.83, 1.0),
        "text_color": Color(0.33, 0.17, 0.12, 1.0),
        "accent_color": Color(1.0, 0.95, 0.88, 1.0),
        "badge_bg": Color(0.39, 0.15, 0.12, 0.86),
        "badge_border": Color(0.87, 0.58, 0.33, 1.0),
        "art_bg": Color(0.13, 0.06, 0.05, 0.86),
        "name_font_size": 18,
        "rules_font_size": 16,
        "cost_font_size": 26,
        "stat_font_size": 24,
        "type_font_size": 18,
        "art_font_size": 16,
    },
    CardGameConstants.CardType.ITEM: {
        "canvas_size": Vector2(258, 387),
        "art_rect": Rect2(30, 18, 198, 166),
        "cost_rect": Rect2(8, 10, 44, 46),
        "name_rect": Rect2(32, 194, 200, 32),
        "rules_rect": Rect2(46, 252, 172, 76),
        "attack_rect": Rect2(0, 0, 0, 0),
        "life_rect": Rect2(0, 0, 0, 0),
        "type_rect": Rect2(0, 0, 0, 0),
        "show_stats": false,
        "show_name": true,
        "show_type_badge": false,
        "name_mode": "display_name",
        "placeholder": "",
        "frame_path": ITEM_FRAME_PATH,
        "title_color": Color(0.91, 0.95, 0.92, 1.0),
        "text_color": Color(0.18, 0.2, 0.18, 1.0),
        "accent_color": Color(0.97, 0.99, 0.96, 1.0),
        "badge_bg": Color(0.18, 0.23, 0.22, 0.88),
        "badge_border": Color(0.78, 0.8, 0.63, 1.0),
        "art_bg": Color(0.07, 0.09, 0.1, 0.82),
        "name_font_size": 18,
        "rules_font_size": 15,
        "cost_font_size": 26,
        "stat_font_size": 24,
        "type_font_size": 18,
        "art_font_size": 16,
    },
}

static var _frame_texture_cache: Dictionary = {}

@onready var center_container: CenterContainer = $CenterContainer
@onready var card_canvas: Control = $CenterContainer/CardCanvas
@onready var frame_texture: TextureRect = $CenterContainer/CardCanvas/FrameTexture
@onready var art_rect: PanelContainer = $CenterContainer/CardCanvas/ArtRect
@onready var art_texture: TextureRect = $CenterContainer/CardCanvas/ArtRect/ArtTexture
@onready var art_label: Label = $CenterContainer/CardCanvas/ArtRect/ArtLabel
@onready var cost_label: Label = $CenterContainer/CardCanvas/CostLabel
@onready var name_label: Label = $CenterContainer/CardCanvas/NameLabel
@onready var rules_label: RichTextLabel = $CenterContainer/CardCanvas/RulesLabel
@onready var attack_label: Label = $CenterContainer/CardCanvas/AttackLabel
@onready var life_label: Label = $CenterContainer/CardCanvas/LifeLabel
@onready var type_badge: PanelContainer = $CenterContainer/CardCanvas/TypeBadge
@onready var type_label: Label = $CenterContainer/CardCanvas/TypeBadge/TypeLabel
@onready var empty_hint: Label = $EmptyHint

var _card_instance: CardInstance
var _interactive := false


func _ready() -> void:
    _refresh()


func set_card_instance(card_instance: CardInstance) -> void:
    _card_instance = card_instance
    _refresh()


func set_interactive(enabled: bool) -> void:
    _interactive = enabled


func set_selected(_is_selected: bool) -> void:
    pass


func set_playable(_is_playable: bool) -> void:
    pass


func _refresh() -> void:
    if _card_instance == null or _card_instance.definition == null:
        center_container.visible = false
        empty_hint.visible = true
        return

    center_container.visible = true
    empty_hint.visible = false

    var layout := _get_layout(_card_instance)
    _apply_layout(layout)
    _apply_content(layout)


func _get_layout(card_instance: CardInstance) -> Dictionary:
    return LAYOUTS.get(card_instance.definition.card_type, LAYOUTS[CardGameConstants.CardType.CAT])


func _apply_layout(layout: Dictionary) -> void:
    var canvas_size: Vector2 = layout["canvas_size"]
    card_canvas.custom_minimum_size = canvas_size
    card_canvas.size = canvas_size
    _apply_rect(art_rect, layout["art_rect"])
    _apply_rect(cost_label, layout["cost_rect"])
    _apply_rect(name_label, layout["name_rect"])
    _apply_rect(rules_label, layout["rules_rect"])
    _apply_rect(attack_label, layout["attack_rect"])
    _apply_rect(life_label, layout["life_rect"])
    _apply_rect(type_badge, layout["type_rect"])


func _apply_content(layout: Dictionary) -> void:
    var definition = _card_instance.definition
    frame_texture.texture = _load_frame_texture(layout["frame_path"])
    cost_label.text = str(definition.cost)
    var name_mode := str(layout.get("name_mode", "display_name"))
    match name_mode:
        "type_label":
            name_label.text = _card_type_label(definition.card_type)
        "none":
            name_label.text = ""
        _:
            name_label.text = definition.display_name
    rules_label.text = CardTextFormatter.rules_preview_bbcode(definition)
    attack_label.text = str(_card_instance.current_attack)
    life_label.text = str(_card_instance.current_life)
    var show_stats: bool = layout["show_stats"]
    var show_name: bool = layout["show_name"]
    var show_type_badge: bool = layout["show_type_badge"]
    attack_label.visible = show_stats
    life_label.visible = show_stats
    name_label.visible = show_name
    type_badge.visible = show_type_badge
    type_label.text = _card_type_label(definition.card_type)

    name_label.add_theme_font_size_override("font_size", int(layout["name_font_size"]))
    rules_label.add_theme_font_size_override("normal_font_size", int(layout["rules_font_size"]))
    rules_label.add_theme_font_size_override("bold_font_size", int(layout["rules_font_size"]))
    cost_label.add_theme_font_size_override("font_size", int(layout["cost_font_size"]))
    attack_label.add_theme_font_size_override("font_size", int(layout["stat_font_size"]))
    life_label.add_theme_font_size_override("font_size", int(layout["stat_font_size"]))
    type_label.add_theme_font_size_override("font_size", int(layout["type_font_size"]))
    art_label.add_theme_font_size_override("font_size", int(layout["art_font_size"]))

    name_label.add_theme_color_override("font_color", layout["title_color"])
    cost_label.add_theme_color_override("font_color", layout["accent_color"])
    art_label.add_theme_color_override("font_color", layout["accent_color"])
    rules_label.add_theme_color_override("default_color", layout["text_color"])
    attack_label.add_theme_color_override("font_color", layout["accent_color"])
    life_label.add_theme_color_override("font_color", layout["accent_color"])
    type_label.add_theme_color_override("font_color", layout["accent_color"])
    art_rect.add_theme_stylebox_override("panel", _build_panel_style(layout["art_bg"], Color(0, 0, 0, 0)))
    type_badge.add_theme_stylebox_override("panel", _build_panel_style(layout["badge_bg"], layout["badge_border"]))

    _refresh_art(layout)


func _refresh_art(layout: Dictionary) -> void:
    var definition = _card_instance.definition
    art_texture.texture = null
    if definition.art_path.is_empty():
        art_texture.visible = false
        art_label.visible = not str(layout["placeholder"]).is_empty()
        art_label.text = str(layout["placeholder"])
        return

    var texture := load(definition.art_path) as Texture2D
    if texture == null:
        art_texture.visible = false
        art_label.visible = not str(layout["placeholder"]).is_empty()
        art_label.text = str(layout["placeholder"])
        return

    art_texture.texture = texture
    art_texture.visible = true
    art_label.visible = false


func _apply_rect(control: Control, rect: Rect2) -> void:
    control.position = rect.position
    control.size = rect.size


func _load_frame_texture(frame_path: String) -> Texture2D:
    if frame_path.is_empty():
        return null
    if _frame_texture_cache.has(frame_path):
        return _frame_texture_cache[frame_path]

    var texture := load(frame_path) as Texture2D
    if texture == null:
        push_warning("Could not load frame texture %s." % frame_path)
        return null

    _frame_texture_cache[frame_path] = texture
    return texture


func _build_panel_style(background_color: Color, border_color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = background_color
    style.border_width_left = 2 if border_color.a > 0.0 else 0
    style.border_width_top = 2 if border_color.a > 0.0 else 0
    style.border_width_right = 2 if border_color.a > 0.0 else 0
    style.border_width_bottom = 2 if border_color.a > 0.0 else 0
    style.border_color = border_color
    style.corner_radius_top_left = 10
    style.corner_radius_top_right = 10
    style.corner_radius_bottom_right = 10
    style.corner_radius_bottom_left = 10
    return style


func _card_type_label(card_type: int) -> String:
    match card_type:
        CardGameConstants.CardType.TRICK:
            return "TRICK"
        CardGameConstants.CardType.ITEM:
            return "ITEM"
        _:
            return "CAT"
