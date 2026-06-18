class_name CardView
extends PanelContainer

const CardDefinition = preload("res://scripts/card_game/data/card_definition.gd")
const CardGameConstants = preload("res://scripts/card_game/data/card_game_constants.gd")
const CardInstance = preload("res://scripts/card_game/runtime/card_instance.gd")
const CardTextFormatter = preload("res://scripts/card_game/ui/card_text_formatter.gd")

const CAT_FRAME_PATH := "res://assets/card_game/card_frames/cat_frame.png"
const TRICK_FRAME_PATH := "res://assets/card_game/card_frames/trick_frame.png"
const ITEM_FRAME_PATH := "res://assets/card_game/card_frames/item_frame.png"
const FRAME_PATHS_BY_VARIANT := {
    &"default": "",
    &"cat": CAT_FRAME_PATH,
    &"trick": TRICK_FRAME_PATH,
    &"item": ITEM_FRAME_PATH,
}

signal card_pressed(instance_id: int)

const VISUAL_PRESETS := {
    CardGameConstants.CardType.CAT: {
        "panel_bg": Color(0.17, 0.12, 0.08, 0.96),
        "panel_border": Color(0.77, 0.62, 0.35, 0.96),
        "surface_bg": Color(0.12, 0.22, 0.31, 1.0),
        "surface_border": Color(0.83, 0.68, 0.36, 1.0),
        "title_color": Color(0.98, 0.95, 0.9, 1.0),
        "body_color": Color(0.95, 0.92, 0.86, 1.0),
        "accent_text": Color(1, 1, 1, 1.0),
        "placeholder_text": "",
        "type_text": "",
        "show_stats": true,
        "frame_path": "",
        "frame_alpha": 0.0,
    },
    CardGameConstants.CardType.TRICK: {
        "panel_bg": Color(0.2, 0.09, 0.08, 0.98),
        "panel_border": Color(0.84, 0.48, 0.31, 1.0),
        "surface_bg": Color(0.29, 0.12, 0.1, 0.92),
        "surface_border": Color(0.87, 0.58, 0.33, 1.0),
        "title_color": Color(1.0, 0.9, 0.8, 1.0),
        "body_color": Color(0.98, 0.91, 0.85, 1.0),
        "accent_text": Color(1.0, 0.96, 0.9, 1.0),
        "placeholder_text": "TRICK",
        "type_text": "TRICK",
        "show_stats": false,
        "frame_path": TRICK_FRAME_PATH,
        "frame_alpha": 0.18,
    },
    CardGameConstants.CardType.ITEM: {
        "panel_bg": Color(0.12, 0.16, 0.16, 0.98),
        "panel_border": Color(0.67, 0.73, 0.62, 1.0),
        "surface_bg": Color(0.16, 0.23, 0.23, 0.92),
        "surface_border": Color(0.78, 0.8, 0.63, 1.0),
        "title_color": Color(0.93, 0.97, 0.92, 1.0),
        "body_color": Color(0.88, 0.93, 0.89, 1.0),
        "accent_text": Color(0.97, 0.99, 0.95, 1.0),
        "placeholder_text": "ITEM",
        "type_text": "ITEM",
        "show_stats": false,
        "frame_path": ITEM_FRAME_PATH,
        "frame_alpha": 0.22,
    },
}

@onready var card_panel: PanelContainer = self
@onready var frame_texture: TextureRect = $FrameTexture
@onready var cost_badge: PanelContainer = $Margin/VBox/Header/CostBadge
@onready var cost_label: Label = $Margin/VBox/Header/CostBadge/CostLabel
@onready var name_label: Label = $Margin/VBox/Header/NameLabel
@onready var art_panel: PanelContainer = $Margin/VBox/Art
@onready var art_texture: TextureRect = $Margin/VBox/Art/ArtTexture
@onready var art_label: Label = $Margin/VBox/Art/ArtLabel
@onready var text_body_panel: PanelContainer = $Margin/VBox/TextBody
@onready var rules_label: RichTextLabel = $Margin/VBox/TextBody/RulesLabel
@onready var attack_badge: PanelContainer = $Margin/VBox/Footer/AttackBadge
@onready var attack_label: Label = $Margin/VBox/Footer/AttackBadge/AttackLabel
@onready var type_badge: PanelContainer = $Margin/VBox/Footer/TypeBadge
@onready var type_label: Label = $Margin/VBox/Footer/TypeBadge/TypeLabel
@onready var life_badge: PanelContainer = $Margin/VBox/Footer/LifeBadge
@onready var life_label: Label = $Margin/VBox/Footer/LifeBadge/LifeLabel
@onready var selection_glow: ColorRect = $SelectionGlow
@onready var playable_glow: ColorRect = $PlayableGlow

var card_instance: CardInstance
var _interactive: bool = true
static var _frame_texture_cache: Dictionary = {}


func _ready() -> void:
    selection_glow.visible = false
    playable_glow.visible = false
    frame_texture.visible = false


func set_card_instance(value: CardInstance) -> void:
    card_instance = value
    _refresh()


func set_interactive(enabled: bool) -> void:
    _interactive = enabled


func set_selected(is_selected: bool) -> void:
    selection_glow.visible = is_selected


func set_playable(is_playable: bool) -> void:
    playable_glow.visible = is_playable


func _gui_input(event: InputEvent) -> void:
    if not _interactive or card_instance == null:
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        card_pressed.emit(card_instance.instance_id)
        get_viewport().set_input_as_handled()


func _refresh() -> void:
    if card_instance == null or card_instance.definition == null:
        visible = false
        return

    visible = true
    var card_definition := card_instance.definition
    var visual := _get_visual_preset(card_definition)
    _apply_visual_theme(visual)
    cost_label.text = str(card_definition.cost)
    name_label.text = card_definition.display_name
    _refresh_art(card_definition, visual)
    rules_label.text = CardTextFormatter.rules_preview_bbcode(card_definition)
    attack_label.text = str(card_instance.current_attack)
    life_label.text = str(card_instance.current_life)
    var show_stats := bool(visual["show_stats"])
    attack_badge.visible = show_stats
    life_badge.visible = show_stats
    type_badge.visible = not show_stats
    type_label.text = str(visual["type_text"])


func _refresh_art(card_definition: CardDefinition, visual: Dictionary) -> void:
    art_texture.texture = null
    if card_definition.art_path.is_empty():
        art_texture.visible = false
        art_label.visible = true
        var placeholder_text := str(visual["placeholder_text"])
        art_label.text = placeholder_text if not placeholder_text.is_empty() else card_definition.display_name
        return

    var texture := load(card_definition.art_path) as Texture2D
    if texture == null:
        art_texture.visible = false
        art_label.visible = true
        var placeholder_text := str(visual["placeholder_text"])
        art_label.text = placeholder_text if not placeholder_text.is_empty() else card_definition.display_name
        return

    art_texture.texture = texture
    art_texture.visible = true
    art_label.visible = false


func _get_visual_preset(card_definition: CardDefinition) -> Dictionary:
    var visual: Dictionary = VISUAL_PRESETS.get(card_definition.card_type, VISUAL_PRESETS[CardGameConstants.CardType.CAT]).duplicate()
    var frame_variant := card_definition.frame_variant
    if frame_variant == &"default":
        match card_definition.card_type:
            CardGameConstants.CardType.TRICK:
                frame_variant = &"trick"
            CardGameConstants.CardType.ITEM:
                frame_variant = &"item"
            _:
                frame_variant = &"default"
    visual["frame_path"] = FRAME_PATHS_BY_VARIANT.get(frame_variant, visual["frame_path"])
    return visual


func _apply_visual_theme(visual: Dictionary) -> void:
    card_panel.add_theme_stylebox_override("panel", _build_style_box(visual["panel_bg"], visual["panel_border"], 14, 6))
    cost_badge.add_theme_stylebox_override("panel", _build_style_box(visual["surface_bg"], visual["surface_border"], 10, 0))
    art_panel.add_theme_stylebox_override("panel", _build_style_box(visual["surface_bg"], visual["surface_border"], 10, 0))
    text_body_panel.add_theme_stylebox_override("panel", _build_style_box(visual["surface_bg"], visual["surface_border"], 10, 0))
    attack_badge.add_theme_stylebox_override("panel", _build_style_box(visual["surface_bg"], visual["surface_border"], 10, 0))
    life_badge.add_theme_stylebox_override("panel", _build_style_box(visual["surface_bg"], visual["surface_border"], 10, 0))
    type_badge.add_theme_stylebox_override("panel", _build_style_box(visual["surface_bg"], visual["surface_border"], 10, 0))

    name_label.add_theme_color_override("font_color", visual["title_color"])
    cost_label.add_theme_color_override("font_color", visual["accent_text"])
    art_label.add_theme_color_override("font_color", visual["accent_text"])
    rules_label.add_theme_color_override("default_color", visual["body_color"])
    rules_label.add_theme_font_size_override("normal_font_size", 15)
    rules_label.add_theme_font_size_override("bold_font_size", 15)
    attack_label.add_theme_color_override("font_color", visual["accent_text"])
    life_label.add_theme_color_override("font_color", visual["accent_text"])
    type_label.add_theme_color_override("font_color", visual["accent_text"])

    var frame_path := str(visual["frame_path"])
    if frame_path.is_empty():
        frame_texture.texture = null
        frame_texture.visible = false
    else:
        frame_texture.texture = _load_frame_texture(frame_path)
        frame_texture.modulate = Color(1, 1, 1, float(visual["frame_alpha"]))
        frame_texture.visible = frame_texture.texture != null


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


func _build_style_box(background_color: Color, border_color: Color, corner_radius: int, shadow_size: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = background_color
    style.border_width_left = 2
    style.border_width_top = 2
    style.border_width_right = 2
    style.border_width_bottom = 2
    style.border_color = border_color
    style.corner_radius_top_left = corner_radius
    style.corner_radius_top_right = corner_radius
    style.corner_radius_bottom_right = corner_radius
    style.corner_radius_bottom_left = corner_radius
    style.shadow_color = Color(0, 0, 0, 0.35)
    style.shadow_size = shadow_size
    return style
