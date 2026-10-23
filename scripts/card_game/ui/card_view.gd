class_name CardView
extends PanelContainer

const CardGameConstants = preload("res://scripts/card_game/data/card_game_constants.gd")
const CardInstance = preload("res://scripts/card_game/runtime/card_instance.gd")
const CardTextFormatter = preload("res://scripts/card_game/ui/card_text_formatter.gd")
const CardArtCache = preload("res://scripts/card_game/ui/card_art_cache.gd")

const CAT_FRAME_PATH := "res://assets/card_game/card_frames/cat_frame.png"
const TRICK_FRAME_PATH := "res://assets/card_game/card_frames/trick_frame.png"
const ITEM_FRAME_PATH := "res://assets/card_game/card_frames/item_frame.png"
# Malované díly z archu (design/card_parts_prompt.md). Pozice jsou v podílech velikosti karty,
# změřené na rámech: středy kruhových výřezů v rozích a pruh pro jméno nad spodní lištou.
const FACE_PARTS_DIR := "res://assets/card_game/ui/sheet/"
const FACE_FRAME_BY_TYPE := {
    CardGameConstants.CardType.CAT: "frame_cat",
    CardGameConstants.CardType.TRICK: "frame_trick",
    CardGameConstants.CardType.ITEM: "frame_item",
}
const FACE_COST_CENTER := Vector2(0.12, 0.115)
const FACE_ATTACK_CENTER := Vector2(0.12, 0.918)
const FACE_LIFE_CENTER := Vector2(0.885, 0.918)
const FACE_HOLDER_WIDTH := 0.27  # průměr medailonu jako podíl šířky karty
const FACE_BANNER_RECT := Rect2(0.16, 0.775, 0.68, 0.125)
const FACE_HOLE_WIDTH := 0.19  # tmavý kotouč do prázdného výřezu (trik/předmět nemá útok ani životy)
const FACE_HOLE_COLOR := Color(0.07, 0.05, 0.04, 0.92)


# Kulatý tmavý kotouč pro prázdný výřez rámu; sdílí ho náhled karty.
static func make_face_hole() -> Panel:
    var hole := Panel.new()
    hole.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var style := StyleBoxFlat.new()
    style.bg_color = FACE_HOLE_COLOR
    style.set_corner_radius_all(999)
    hole.add_theme_stylebox_override("panel", style)
    return hole
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
var _face_frame: TextureRect
var _face_banner: TextureRect
var _face_cost_badge: TextureRect
var _face_attack_badge: TextureRect
var _face_life_badge: TextureRect
var _face_holes: Array[Panel] = []
var _face_keyword_box: PanelContainer
var _face_keyword: Label
var _face_keyword_icon: TextureRect
var _face_badge_text := ""
var _face_type: Label  # „KOUZLO“ / „PŘEDMĚT“ místo odznaků útoku a životů
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
    # UI rozbor: 0.62 bylo moc tmavé, karta nešla přečíst.
    modulate = Color.WHITE if is_playable else Color(0.8, 0.78, 0.76, 1.0)


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
    resized.connect(_update_face_keyword_visibility)
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
    _face_frame = _make_face_texture("frame_cat")
    _face_banner = _make_face_texture("banner_name")
    _face_name = _make_face_label(14)
    _face_name.clip_text = true
    _face_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    _face_name.add_theme_color_override("font_color", Color(1.0, 0.94, 0.8))
    _face_type = _make_face_label(11)
    for i in 2:
        _face_holes.append(make_face_hole())
        _face.add_child(_face_holes[i])
    _face_cost_badge = _make_face_holder("holder_cost")
    _face_cost = _face_cost_badge.get_child(0)
    _face_attack_badge = _make_face_holder("holder_attack")
    _face_attack = _face_attack_badge.get_child(0)
    _face_life_badge = _make_face_holder("holder_health")
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
    resized.connect(_layout_face)
    _layout_face()


func _make_face_texture(part_id: String) -> TextureRect:
    var rect := TextureRect.new()
    rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    rect.stretch_mode = TextureRect.STRETCH_SCALE
    rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    rect.texture = _load_frame_texture(FACE_PARTS_DIR + part_id + ".png")
    _face.add_child(rect)
    return rect


func _make_face_label(font_size: int) -> Label:
    var label := Label.new()
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
    label.add_theme_constant_override("outline_size", 3)
    _face.add_child(label)
    return label


# Medailon s číslem uprostřed; velikost písma dopočítá _layout_face podle karty.
func _make_face_holder(part_id: String) -> TextureRect:
    var holder := _make_face_texture(part_id)
    holder.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var label := Label.new()
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88))
    label.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02, 0.95))
    holder.add_child(label)
    label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    return holder


# Díly rozmístí podle aktuální velikosti karty (ruka, náhled i odměna mají jinou).
func _layout_face() -> void:
    if _face == null:
        return
    var card := size
    _face_frame.position = Vector2.ZERO
    _face_frame.size = card
    var banner := FACE_BANNER_RECT
    _face_banner.position = Vector2(banner.position.x * card.x, banner.position.y * card.y)
    _face_banner.size = Vector2(banner.size.x * card.x, banner.size.y * card.y)
    # Látka stuhy je mezi koncovkami; text drž uvnitř a lehce nad středem (spodní okraj je roztřepený).
    _face_name.position = _face_banner.position + Vector2(_face_banner.size.x * 0.13, 0.0)
    _face_name.size = Vector2(_face_banner.size.x * 0.74, _face_banner.size.y * 0.8)
    _face_type.position = Vector2(card.x * 0.25, card.y * 0.895)
    _face_type.size = Vector2(card.x * 0.5, card.y * 0.05)
    var diameter := card.x * FACE_HOLDER_WIDTH
    _place_face_holder(_face_cost_badge, FACE_COST_CENTER, diameter, 0.06)
    _place_face_holder(_face_attack_badge, FACE_ATTACK_CENTER, diameter, 0.04)
    _place_face_holder(_face_life_badge, FACE_LIFE_CENTER, diameter, -0.02)
    # Dlouhá jména zmenšit, ať se vejdou na stuhu; písmo roste s kartou (náhled je větší než ruka).
    var name_length := _face_name.text.length()
    var name_size := clampf(card.x / 176.0, 0.8, 1.6) * (13.0 if name_length <= 13 else (11.0 if name_length <= 18 else 10.0))
    _face_name.add_theme_font_size_override("font_size", int(name_size))
    var inset := card.x * 0.03
    _face_art.offset_left = inset
    _face_art.offset_top = inset
    _face_art.offset_right = -inset
    _face_art.offset_bottom = -inset
    var hole := card.x * FACE_HOLE_WIDTH
    for i in 2:
        var center := FACE_ATTACK_CENTER if i == 0 else FACE_LIFE_CENTER
        _face_holes[i].size = Vector2(hole, hole)
        _face_holes[i].position = Vector2(center.x * card.x, center.y * card.y) - _face_holes[i].size * 0.5
    _face_keyword_box.offset_top = card.y * 0.12
    _face_keyword_box.offset_right = -card.x * 0.07


func _place_face_holder(holder: TextureRect, center: Vector2, diameter: float, text_shift: float) -> void:
    holder.size = Vector2(diameter, diameter)
    holder.position = Vector2(center.x * size.x, center.y * size.y) - holder.size * 0.5
    var label := holder.get_child(0) as Label
    label.add_theme_font_size_override("font_size", maxi(10, int(diameter * 0.46)))
    label.add_theme_constant_override("outline_size", maxi(2, int(diameter * 0.09)))
    # Medailony mají ozdobu nahoře, takže střed výplně je níž než střed obrázku.
    label.offset_top = diameter * text_shift
    label.offset_bottom = diameter * text_shift


# Na úzké kartě (plná ruka) by štítek překryl cenu; detail je pak v náhledu pod myší.
func _update_face_keyword_visibility() -> void:
    if _face_keyword_box != null:
        _face_keyword_box.visible = not _face_badge_text.is_empty() and size.x >= 140.0


func _refresh_face(card_definition: CardDefinition, show_stats: bool, badge_text: String) -> void:
    if _face == null:
        return
    _face_art.texture = CardArtCache.get_cropped_aspect(card_definition.art_path, 0.85, 0.02)  # karta na výšku: hlava + trup
    _face_name.text = card_definition.display_name
    _face_frame.texture = _load_frame_texture(FACE_PARTS_DIR + str(FACE_FRAME_BY_TYPE.get(card_definition.card_type, "frame_cat")) + ".png")
    _face_cost.text = str(card_definition.cost)
    _face_attack.text = str(card_instance.current_attack)
    _face_life.text = str(card_instance.current_life)
    _face_attack_badge.visible = show_stats
    _face_life_badge.visible = show_stats
    for hole in _face_holes:
        hole.visible = not show_stats
    _face_type.visible = not show_stats
    _face_type.text = badge_text.to_upper()
    _face_type.add_theme_color_override("font_color", Color(1.0, 0.62, 0.5) if card_definition.card_type == CardGameConstants.CardType.TRICK else Color(0.6, 0.8, 1.0))
    _face_badge_text = badge_text
    _face_keyword.text = badge_text
    _update_face_keyword_visibility()
    _layout_face()
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
