class_name CardView
extends PanelContainer

const CardGameConstants = preload("res://scripts/card_game/data/card_game_constants.gd")
const CardInstance = preload("res://scripts/card_game/runtime/card_instance.gd")
const CardTextFormatter = preload("res://scripts/card_game/ui/card_text_formatter.gd")
const CardArtCache = preload("res://scripts/card_game/ui/card_art_cache.gd")

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
signal card_hovered(card_instance)

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
        "placeholder_text": "TRIK",
        "type_text": "TRIK",
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
        "placeholder_text": "PŘEDMĚT",
        "type_text": "PŘEDMĚT",
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
# Líc karty ve stejném jazyce jako token na stole (art přes celou kartu, odznaky v rozích).
var _face: Control
var _face_art: TextureRect
var _face_name: Label
var _face_cost: Label
var _face_attack: Label
var _face_life: Label
var _face_attack_badge: Panel
var _face_life_badge: Panel
var _face_keyword_box: PanelContainer
var _face_keyword: Label
var _face_keyword_icon: TextureRect
static var _frame_texture_cache: Dictionary = {}


func _ready() -> void:
    selection_glow.visible = false
    playable_glow.visible = false
    frame_texture.visible = false
    _build_face()
    mouse_entered.connect(func() -> void: card_hovered.emit(card_instance))
    mouse_exited.connect(func() -> void: card_hovered.emit(null))
    _make_children_click_through(self)


func set_card_instance(value: CardInstance) -> void:
    card_instance = value
    _refresh()


func set_interactive(enabled: bool) -> void:
    _interactive = enabled


func set_selected(is_selected: bool) -> void:
    selection_glow.visible = is_selected


func set_playable(is_playable: bool) -> void:
    # Hratelná karta svítí, nehratelná (málo Tuny / cizí tah) ztmavne, ať začátečník hned vidí volby.
    playable_glow.visible = is_playable
    playable_glow.color = Color(0.45, 0.95, 0.55, 0.26)
    modulate = Color.WHITE if is_playable else Color(0.62, 0.6, 0.58, 1.0)


func _gui_input(event: InputEvent) -> void:
    if not _interactive or card_instance == null:
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        card_pressed.emit(card_instance.instance_id)
        get_viewport().set_input_as_handled()


func _get_drag_data(_at_position: Vector2) -> Variant:
    if not _interactive or card_instance == null or card_instance.definition == null:
        return null

    var preview := PanelContainer.new()
    preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
    preview.custom_minimum_size = Vector2(180, 40)
    preview.add_theme_stylebox_override("panel", _build_style_box(Color(0.14, 0.1, 0.07, 0.96), Color(0.77, 0.62, 0.35, 0.96), 10, 3))

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_top", 6)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_bottom", 6)
    preview.add_child(margin)

    var label := Label.new()
    label.text = "%s (%s)" % [card_instance.definition.display_name, card_instance.definition.cost]
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 16)
    label.add_theme_color_override("font_color", Color(0.98, 0.92, 0.82, 1))
    margin.add_child(label)

    set_drag_preview(preview)
    return {"instance_id": card_instance.instance_id}


func _refresh() -> void:
    if card_instance == null or card_instance.definition == null:
        visible = false
        return

    visible = true
    var card_definition := card_instance.definition
    var visual := _get_visual_preset(card_definition)
    _apply_visual_theme(visual)
    text_body_panel.visible = false
    cost_label.text = str(card_definition.cost)
    name_label.text = card_definition.display_name
    _refresh_art(card_definition, visual)
    rules_label.text = CardTextFormatter.rules_preview_bbcode(card_definition)
    attack_label.text = str(card_instance.current_attack)
    life_label.text = str(card_instance.current_life)
    var show_stats := bool(visual["show_stats"])
    attack_badge.visible = show_stats
    life_badge.visible = show_stats
    # U koček ukazuje prostřední odznak první keyword, aby ho hráč viděl už v ruce.
    var keyword_text := ""
    if show_stats and not card_definition.keywords.is_empty():
        keyword_text = str(CardGameConstants.keyword_label(card_definition.keywords[0]))
    type_badge.visible = not show_stats or not keyword_text.is_empty()
    type_label.text = keyword_text if show_stats else str(visual["type_text"])
    _refresh_face(card_definition, show_stats, keyword_text if show_stats else str(visual["type_text"]))


func _build_face() -> void:
    $Margin.visible = false
    _face = Control.new()
    _face.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _face.clip_contents = true
    add_child(_face)
    move_child(_face, $Margin.get_index())
    _face_art = TextureRect.new()
    _face_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _face_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _face_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    _face_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    _face.add_child(_face_art)
    _face_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _face_art.offset_left = 3
    _face_art.offset_top = 3
    _face_art.offset_right = -3
    _face_art.offset_bottom = -3
    var strip := Panel.new()
    strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
    strip.add_theme_stylebox_override("panel", _build_style_box(Color(0.06, 0.04, 0.03, 0.85), Color(0, 0, 0, 0), 0, 0))
    _face.add_child(strip)
    strip.anchor_top = 1.0
    strip.anchor_right = 1.0
    strip.anchor_bottom = 1.0
    strip.offset_left = 3
    strip.offset_right = -3
    strip.offset_top = -30
    strip.offset_bottom = -3
    _face_name = Label.new()
    _face_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _face_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _face_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _face_name.clip_text = true
    _face_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    _face_name.add_theme_font_size_override("font_size", 14)
    _face_name.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
    _face_name.add_theme_constant_override("outline_size", 3)
    _face.add_child(_face_name)
    _face_name.anchor_top = 1.0
    _face_name.anchor_right = 1.0
    _face_name.anchor_bottom = 1.0
    _face_name.offset_left = 34
    _face_name.offset_right = -34
    _face_name.offset_top = -30
    _face_name.offset_bottom = -3
    _face_cost = _make_face_badge(Color(0.16, 0.34, 0.62), 0.0, 0.0, 5, 5, 26).get_child(0)
    _face_attack_badge = _make_face_badge(Color(0.7, 0.42, 0.1), 0.0, 1.0, 4, -32, 28)
    _face_attack = _face_attack_badge.get_child(0)
    _face_life_badge = _make_face_badge(Color(0.62, 0.16, 0.14), 1.0, 1.0, -32, -32, 28)
    _face_life = _face_life_badge.get_child(0)
    _face_keyword_box = PanelContainer.new()
    _face_keyword_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var pill := _build_style_box(Color(0.08, 0.06, 0.04, 0.88), Color(0.9, 0.78, 0.45, 0.7), 8, 0)
    pill.set_border_width_all(1)
    pill.content_margin_left = 5
    pill.content_margin_right = 6
    _face_keyword_box.add_theme_stylebox_override("panel", pill)
    _face.add_child(_face_keyword_box)
    _face_keyword_box.anchor_left = 1.0
    _face_keyword_box.anchor_right = 1.0
    _face_keyword_box.offset_top = 5
    _face_keyword_box.offset_right = -5
    _face_keyword_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
    var row := HBoxContainer.new()
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_theme_constant_override("separation", 3)
    _face_keyword_box.add_child(row)
    _face_keyword_icon = TextureRect.new()
    _face_keyword_icon.custom_minimum_size = Vector2(13, 13)
    _face_keyword_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _face_keyword_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _face_keyword_icon.modulate = Color(0.98, 0.84, 0.5)
    _face_keyword_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(_face_keyword_icon)
    _face_keyword = Label.new()
    _face_keyword.add_theme_font_size_override("font_size", 11)
    _face_keyword.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(_face_keyword)


func _make_face_badge(color: Color, ax: float, ay: float, ox: float, oy: float, diameter: float) -> Panel:
    var badge := Panel.new()
    badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var style := _build_style_box(color, Color(0.98, 0.88, 0.62, 0.95), int(diameter / 2.0), 3)
    style.set_border_width_all(2)
    badge.add_theme_stylebox_override("panel", style)
    _face.add_child(badge)
    badge.anchor_left = ax
    badge.anchor_right = ax
    badge.anchor_top = ay
    badge.anchor_bottom = ay
    badge.offset_left = ox
    badge.offset_top = oy
    badge.offset_right = ox + diameter
    badge.offset_bottom = oy + diameter
    var label := Label.new()
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", int(diameter * 0.62))
    label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
    label.add_theme_constant_override("outline_size", 3)
    badge.add_child(label)
    label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    return badge


func _refresh_face(card_definition: CardDefinition, show_stats: bool, badge_text: String) -> void:
    if _face == null:
        return
    _face_art.texture = CardArtCache.get_cropped(card_definition.art_path, 0.04, 0.42)
    _face_name.text = card_definition.display_name
    # Dlouhá jména zmenšit, ať se vejdou mezi odznaky útoku a životů.
    var name_length := card_definition.display_name.length()
    _face_name.add_theme_font_size_override("font_size", 14 if name_length <= 13 else (12 if name_length <= 17 else 11))
    _face_cost.text = str(card_definition.cost)
    _face_attack.text = str(card_instance.current_attack)
    _face_life.text = str(card_instance.current_life)
    _face_attack_badge.visible = show_stats
    _face_life_badge.visible = show_stats
    _face_keyword_box.visible = not badge_text.is_empty()
    _face_keyword.text = badge_text
    var icon: Texture2D = null
    if show_stats and not card_definition.keywords.is_empty():
        icon = CardArtCache.get_keyword_icon(card_definition.keywords[0])
    _face_keyword_icon.texture = icon
    _face_keyword_icon.visible = icon != null


func _refresh_art(card_definition: CardDefinition, visual: Dictionary) -> void:
    art_texture.texture = null
    if card_definition.art_path.is_empty():
        art_texture.visible = false
        art_label.visible = true
        var placeholder_text := str(visual["placeholder_text"])
        art_label.text = placeholder_text if not placeholder_text.is_empty() else card_definition.display_name
        return

    var texture := CardArtCache.get_cropped(card_definition.art_path, 0.06, 0.36)
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
    rules_label.add_theme_font_size_override("normal_font_size", 13)
    rules_label.add_theme_font_size_override("bold_font_size", 13)
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


func _make_children_click_through(node: Node) -> void:
    for child in node.get_children():
        if child is Control:
            (child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
        _make_children_click_through(child)
