class_name SelectedCardPreview
extends Control

const CardGameConstants = preload("res://scripts/card_game/data/card_game_constants.gd")
const CardInstance = preload("res://scripts/card_game/runtime/card_instance.gd")
const CardTextFormatter = preload("res://scripts/card_game/ui/card_text_formatter.gd")
const CardArtCache = preload("res://scripts/card_game/ui/card_art_cache.gd")

const SELECTED_PREVIEW_FRAME_PATH := "res://assets/card_game/ui/selected_card_preview_frame.png"
const DISPLAY_FULL := &"full"
const DISPLAY_BOARD := &"board"
const DISPLAY_LARGE := &"large"  # pravý panel souboje (layout v2)

const DISPLAY_CONFIGS := {
    DISPLAY_FULL: {
        "scale": 1.0,
        "show_rules": true,
        "minimum_height": 404.0,
    },
    DISPLAY_LARGE: {
        "scale": 1.28,
        "show_rules": true,
        "minimum_height": 510.0,
    },
    DISPLAY_BOARD: {
        "scale": 0.37,
        "show_rules": false,
        "minimum_height": 144.0,
    },
}

# Velký náhled (full/large): obrázek přes celou kartu, text dole přes tmavý přechod (Mark 22. 10.).
# Žeton na stole (board) má dál výřez nahoře a jméno pod ním.
const FULL_ART_OVERRIDES := {
    "art_rect": Rect2(8, 8, 242, 371),
    "name_rect": Rect2(8, 214, 242, 28),
    "type_rect": Rect2(64, 244, 130, 24),
    "rules_rect": Rect2(18, 272, 222, 66),
}
const TEXT_SHADE_RECT := Rect2(8, 170, 242, 209)

const LAYOUTS := {
    CardGameConstants.CardType.CAT: {
        "canvas_size": Vector2(258, 387),
        "art_rect": Rect2(8, 8, 242, 188),
        "cost_rect": Rect2(14, 14, 40, 40),
        "name_rect": Rect2(8, 200, 242, 30),
        "rules_rect": Rect2(18, 262, 222, 74),
        "attack_rect": Rect2(12, 338, 42, 42),
        "life_rect": Rect2(204, 338, 42, 42),
        "type_rect": Rect2(64, 232, 130, 24),
        "show_stats": true,
        "show_name": true,
        "show_type_badge": true,
        "name_mode": "display_name",
        "placeholder": "",
        "frame_path": "",
        "title_color": Color(0.96, 0.93, 0.88, 1.0),
        "text_color": Color(0.93, 0.89, 0.8, 1.0),
        "accent_color": Color(1, 1, 1, 1.0),
        "badge_bg": Color(0.1, 0.2, 0.28, 0.92),
        "badge_border": Color(0.83, 0.68, 0.36, 1.0),
        "art_bg": Color(0.08, 0.08, 0.09, 0.92),
        "name_font_size": 20,
        "rules_font_size": 15,
        "cost_font_size": 28,
        "stat_font_size": 28,
        "type_font_size": 18,
        "art_font_size": 26,
    },
    CardGameConstants.CardType.TRICK: {
        "canvas_size": Vector2(258, 387),
        "art_rect": Rect2(8, 8, 242, 188),
        "cost_rect": Rect2(14, 14, 40, 40),
        "name_rect": Rect2(8, 200, 242, 30),
        "rules_rect": Rect2(18, 262, 222, 74),
        "attack_rect": Rect2(12, 338, 42, 42),
        "life_rect": Rect2(204, 338, 42, 42),
        "type_rect": Rect2(64, 232, 130, 24),
        "show_stats": false,
        "show_name": true,
        "show_type_badge": true,
        "name_mode": "display_name",
        "placeholder": "",
        "frame_path": "",
        "title_color": Color(0.98, 0.91, 0.83, 1.0),
        "text_color": Color(0.95, 0.88, 0.82, 1.0),
        "accent_color": Color(1.0, 0.95, 0.88, 1.0),
        "badge_bg": Color(0.39, 0.15, 0.12, 0.86),
        "badge_border": Color(0.87, 0.58, 0.33, 1.0),
        "art_bg": Color(0.13, 0.06, 0.05, 0.92),
        "name_font_size": 18,
        "rules_font_size": 16,
        "cost_font_size": 26,
        "stat_font_size": 24,
        "type_font_size": 18,
        "art_font_size": 16,
    },
    CardGameConstants.CardType.ITEM: {
        "canvas_size": Vector2(258, 387),
        "art_rect": Rect2(8, 8, 242, 188),
        "cost_rect": Rect2(14, 14, 40, 40),
        "name_rect": Rect2(8, 200, 242, 30),
        "rules_rect": Rect2(18, 262, 222, 74),
        "attack_rect": Rect2(12, 338, 42, 42),
        "life_rect": Rect2(204, 338, 42, 42),
        "type_rect": Rect2(64, 232, 130, 24),
        "show_stats": false,
        "show_name": true,
        "show_type_badge": true,
        "name_mode": "display_name",
        "placeholder": "",
        "frame_path": "",
        "title_color": Color(0.91, 0.95, 0.92, 1.0),
        "text_color": Color(0.88, 0.93, 0.9, 1.0),
        "accent_color": Color(0.97, 0.99, 0.96, 1.0),
        "badge_bg": Color(0.18, 0.23, 0.22, 0.88),
        "badge_border": Color(0.78, 0.8, 0.63, 1.0),
        "art_bg": Color(0.07, 0.09, 0.1, 0.9),
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
var _text_shade: TextureRect  # tmavý přechod pod textem přes obrázek (full/large)

var _card_instance: CardInstance
var _interactive := false
var _display_mode: StringName = DISPLAY_FULL
var _card_background: Panel
var _guide_label: RichTextLabel


func _ready() -> void:
    # Čistý podklad karty místo ozdobného rámu, jehož okna neseděla na art ani texty.
    _card_background = Panel.new()
    _card_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card_canvas.add_child(_card_background)
    card_canvas.move_child(_card_background, 0)
    _card_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    frame_texture.visible = false
    _text_shade = TextureRect.new()
    _text_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _text_shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _text_shade.stretch_mode = TextureRect.STRETCH_SCALE
    var gradient := Gradient.new()
    gradient.set_color(0, Color(0.06, 0.04, 0.03, 0.0))
    gradient.set_color(1, Color(0.06, 0.04, 0.03, 0.95))
    gradient.add_point(0.3, Color(0.06, 0.04, 0.03, 0.82))
    var shade_texture := GradientTexture2D.new()
    shade_texture.gradient = gradient
    shade_texture.fill_from = Vector2(0, 0)
    shade_texture.fill_to = Vector2(0, 1)
    shade_texture.width = 4
    shade_texture.height = 128
    _text_shade.texture = shade_texture
    card_canvas.add_child(_text_shade)
    card_canvas.move_child(_text_shade, art_rect.get_index() + 1)
    art_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    art_texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    for label in [cost_label, attack_label, life_label]:
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
        label.add_theme_constant_override("outline_size", 4)
    name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    name_label.clip_text = true
    type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    # Průvodce „Co teď?“ v prázdném stavu (vyplňuje battle_preview_presenter).
    _guide_label = RichTextLabel.new()
    _guide_label.bbcode_enabled = true
    _guide_label.fit_content = false
    _guide_label.scroll_active = false
    _guide_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _guide_label.add_theme_font_size_override("normal_font_size", 16)
    _guide_label.add_theme_font_size_override("bold_font_size", 17)
    _guide_label.add_theme_color_override("default_color", Color(0.92, 0.88, 0.8))
    add_child(_guide_label)
    _guide_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _guide_label.offset_left = 10.0
    _guide_label.offset_right = -10.0
    _guide_label.offset_top = 14.0
    _guide_label.visible = false
    _refresh()


func set_card_instance(card_instance: CardInstance) -> void:
    _card_instance = card_instance
    _refresh()


func set_empty_guide(bbcode: String) -> void:
    if _guide_label == null:
        return
    _guide_label.text = bbcode
    _refresh()


func set_interactive(enabled: bool) -> void:
    _interactive = enabled


func set_display_mode(mode: StringName) -> void:
    _display_mode = mode if DISPLAY_CONFIGS.has(mode) else DISPLAY_FULL
    _refresh()


func get_display_mode() -> StringName:
    return _display_mode


func set_selected(_is_selected: bool) -> void:
    pass


func set_playable(_is_playable: bool) -> void:
    pass


func _refresh() -> void:
    _apply_display_root()
    if _card_instance == null or _card_instance.definition == null:
        center_container.visible = false
        var has_guide := _guide_label != null and not _guide_label.text.is_empty()
        empty_hint.visible = not has_guide
        if _guide_label != null:
            _guide_label.visible = has_guide
        return

    center_container.visible = true
    empty_hint.visible = false
    if _guide_label != null:
        _guide_label.visible = false

    var layout := _get_layout(_card_instance)
    _apply_layout(layout)
    _apply_content(layout)


func _get_layout(card_instance: CardInstance) -> Dictionary:
    return LAYOUTS.get(card_instance.definition.card_type, LAYOUTS[CardGameConstants.CardType.CAT])


func _is_full_art() -> bool:
    return _display_mode != DISPLAY_BOARD


func _apply_layout(base_layout: Dictionary) -> void:
    var layout := base_layout.duplicate()
    if _is_full_art():
        layout.merge(FULL_ART_OVERRIDES, true)
    _text_shade.visible = _is_full_art()
    var display_config := _get_display_config()
    var display_scale := float(display_config["scale"])
    _apply_rect(_text_shade, TEXT_SHADE_RECT, display_scale)
    var canvas_size: Vector2 = layout["canvas_size"] * display_scale
    card_canvas.custom_minimum_size = canvas_size
    card_canvas.size = canvas_size
    _apply_rect(art_rect, layout["art_rect"], display_scale)
    _apply_rect(cost_label, layout["cost_rect"], display_scale)
    _apply_rect(name_label, layout["name_rect"], display_scale)
    _apply_rect(rules_label, layout["rules_rect"], display_scale)
    _apply_rect(attack_label, layout["attack_rect"], display_scale)
    _apply_rect(life_label, layout["life_rect"], display_scale)
    _apply_rect(type_badge, layout["type_rect"], display_scale)


func _apply_content(layout: Dictionary) -> void:
    var display_config := _get_display_config()
    var display_scale := float(display_config["scale"])
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
    var show_rules := bool(display_config["show_rules"])
    attack_label.visible = show_stats
    life_label.visible = show_stats
    name_label.visible = show_name
    type_badge.visible = show_type_badge
    rules_label.visible = show_rules
    # U koček ukazuje odznak první keyword (víc řekne než „KOČKA“), jinak typ karty.
    type_label.text = _card_type_label(definition.card_type)
    if definition.card_type == CardGameConstants.CardType.CAT and not definition.keywords.is_empty():
        type_label.text = str(CardGameConstants.keyword_label(definition.keywords[0])).to_upper()

    name_label.add_theme_font_size_override("font_size", _scaled_font_size(int(layout["name_font_size"]), display_scale, 12))
    rules_label.add_theme_font_size_override("normal_font_size", _scaled_font_size(int(layout["rules_font_size"]), display_scale, 10))
    rules_label.add_theme_font_size_override("bold_font_size", _scaled_font_size(int(layout["rules_font_size"]), display_scale, 10))
    cost_label.add_theme_font_size_override("font_size", _scaled_font_size(int(layout["cost_font_size"]), display_scale, 14))
    attack_label.add_theme_font_size_override("font_size", _scaled_font_size(int(layout["stat_font_size"]), display_scale, 14))
    life_label.add_theme_font_size_override("font_size", _scaled_font_size(int(layout["stat_font_size"]), display_scale, 14))
    type_label.add_theme_font_size_override("font_size", _scaled_font_size(int(layout["type_font_size"]), display_scale, 12))
    art_label.add_theme_font_size_override("font_size", _scaled_font_size(int(layout["art_font_size"]), display_scale, 12))

    name_label.add_theme_color_override("font_color", layout["title_color"])
    cost_label.add_theme_color_override("font_color", layout["accent_color"])
    art_label.add_theme_color_override("font_color", layout["accent_color"])
    rules_label.add_theme_color_override("default_color", layout["text_color"])
    attack_label.add_theme_color_override("font_color", layout["accent_color"])
    life_label.add_theme_color_override("font_color", layout["accent_color"])
    type_label.add_theme_color_override("font_color", layout["accent_color"])
    var art_background: Color = layout["art_bg"]
    if _display_mode == DISPLAY_BOARD:
        # Solid warm fill so the lane tint (red/green) can't bleed through an empty art window.
        art_background = Color(0.15, 0.11, 0.08, 1.0)
    art_rect.add_theme_stylebox_override("panel", _build_panel_style(art_background, Color(0, 0, 0, 0)))
    type_badge.add_theme_stylebox_override("panel", _build_panel_style(layout["badge_bg"], layout["badge_border"]))
    _card_background.add_theme_stylebox_override("panel", _build_panel_style(Color(0.12, 0.09, 0.07, 0.98), layout["badge_border"]))
    cost_label.add_theme_stylebox_override("normal", _build_round_style(Color(0.16, 0.34, 0.62), display_scale))
    attack_label.add_theme_stylebox_override("normal", _build_round_style(Color(0.7, 0.42, 0.1), display_scale))
    life_label.add_theme_stylebox_override("normal", _build_round_style(Color(0.62, 0.16, 0.14), display_scale))

    _refresh_art(layout)


func _refresh_art(layout: Dictionary) -> void:
    var definition = _card_instance.definition
    art_texture.texture = null

    var texture: Texture2D = null
    if not definition.art_path.is_empty():
        texture = CardArtCache.get_full(definition.art_path) if _is_full_art() else CardArtCache.get_cropped(definition.art_path, 0.03, 0.5)
        if texture == null:
            texture = CardArtCache.get_cropped(definition.art_path, 0.03, 0.5)  # chybějící art: rub s tlapkou

    if texture != null:
        art_texture.texture = texture
        art_texture.visible = true
        art_label.visible = false
        return

    art_texture.visible = false
    art_label.visible = not str(layout["placeholder"]).is_empty()
    art_label.text = str(layout["placeholder"])


func _apply_rect(control: Control, rect: Rect2, scale: float) -> void:
    control.position = rect.position * scale
    control.size = rect.size * scale


func _apply_display_root() -> void:
    var display_config := _get_display_config()
    var layout := LAYOUTS[CardGameConstants.CardType.CAT]
    var canvas_size: Vector2 = layout["canvas_size"] * float(display_config["scale"])
    custom_minimum_size = Vector2(canvas_size.x, float(display_config["minimum_height"]))
    empty_hint.add_theme_font_size_override("font_size", _scaled_font_size(16, float(display_config["scale"]), 12))


func _get_display_config() -> Dictionary:
    return DISPLAY_CONFIGS.get(_display_mode, DISPLAY_CONFIGS[DISPLAY_FULL])


func _scaled_font_size(base_size: int, scale: float, minimum: int) -> int:
    return maxi(minimum, int(round(base_size * scale)))


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


func _build_round_style(color: Color, scale: float) -> StyleBoxFlat:
    var style := _build_panel_style(color, Color(0.98, 0.88, 0.62, 0.95))
    var radius := int(21.0 * scale)
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_right = radius
    style.corner_radius_bottom_left = radius
    return style


func _card_type_label(card_type: int) -> String:
    match card_type:
        CardGameConstants.CardType.TRICK:
            return "TRIK"
        CardGameConstants.CardType.ITEM:
            return "PŘEDMĚT"
        _:
            return "KOČKA"
