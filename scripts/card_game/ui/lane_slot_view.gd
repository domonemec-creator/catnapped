class_name LaneSlotView
extends PanelContainer

const CardInstance = preload("res://scripts/card_game/runtime/card_instance.gd")
const SelectedCardPreviewScript = preload("res://scripts/card_game/ui/selected_card_preview.gd")

signal slot_pressed(lane_index: int, owner_id: int)
signal card_dropped(instance_id: int, lane_index: int, owner_id: int)

@onready var side_badge: PanelContainer = $Margin/VBox/Header/SideBadge
@onready var side_label: Label = $Margin/VBox/Header/SideBadge/SideLabel
@onready var lane_label: Label = $Margin/VBox/Header/LaneLabel
@onready var slot_shell: PanelContainer = $Margin/VBox/SlotShell
@onready var slot_glow: ColorRect = $Margin/VBox/SlotShell/SlotGlow
@onready var card_shadow: PanelContainer = $Margin/VBox/SlotShell/CardShadow
@onready var card_preview: SelectedCardPreview = $Margin/VBox/SlotShell/CardAnchor/CardPreview
@onready var wound_glow: ColorRect = $Margin/VBox/SlotShell/WoundGlow
@onready var empty_frame: PanelContainer = $Margin/VBox/SlotShell/EmptyFrame
@onready var empty_label: Label = $Margin/VBox/SlotShell/EmptyFrame/EmptyLabel
@onready var empty_hint_label: Label = $Margin/VBox/SlotShell/EmptyHintLabel
@onready var name_ribbon: PanelContainer = $Margin/VBox/SlotShell/NameRibbon
@onready var occupant_label: Label = $Margin/VBox/SlotShell/NameRibbon/OccupantLabel
@onready var highlight_frame: TextureRect = $Margin/VBox/SlotShell/HighlightFrame
@onready var target_ring_center: CenterContainer = $Margin/VBox/SlotShell/TargetRingCenter
@onready var target_ring: TextureRect = $Margin/VBox/SlotShell/TargetRingCenter/TargetRing
@onready var flash_texture: TextureRect = $Margin/VBox/SlotShell/FlashTexture
@onready var event_token_center: CenterContainer = $Margin/VBox/SlotShell/EventTokenCenter
@onready var event_token: TextureRect = $Margin/VBox/SlotShell/EventTokenCenter/EventToken
@onready var status_badge: TextureRect = $Margin/VBox/SlotShell/StatusBadge
@onready var status_badge_label: Label = $Margin/VBox/SlotShell/StatusBadge/StatusLabel
@onready var event_panel: PanelContainer = $Margin/VBox/SlotShell/EventPanel
@onready var event_background: TextureRect = $Margin/VBox/SlotShell/EventPanel/EventBackground
@onready var event_label: Label = $Margin/VBox/SlotShell/EventPanel/EventLabel
@onready var highlight: ColorRect = $Highlight

var lane_index: int = -1
var owner_id: int = -1
var _card_instance: CardInstance
var _empty_hint: String = "Volna lajna."
var _current_highlight_mode: StringName = &"none"
var _recent_event_text: String = ""
var _recent_event_tone: StringName = &"neutral"
static var _ui_texture_cache: Dictionary = {}

const OWNER_PLAYER := 0
const OWNER_ENEMY := 1

const HIGHLIGHT_NONE := &"none"
const HIGHLIGHT_PLAY := &"play"
const HIGHLIGHT_SELECTED := &"selected"
const HIGHLIGHT_ATTACK := &"attack"

const HIGHLIGHT_COLORS := {
	HIGHLIGHT_PLAY: Color(0.42, 0.94, 0.56, 0.34),
	HIGHLIGHT_SELECTED: Color(0.99, 0.86, 0.4, 0.34),
	HIGHLIGHT_ATTACK: Color(0.98, 0.48, 0.22, 0.38),
}

const HIGHLIGHT_BORDER_COLORS := {
	HIGHLIGHT_PLAY: Color(0.56, 0.92, 0.58, 0.96),
	HIGHLIGHT_SELECTED: Color(0.99, 0.84, 0.43, 0.98),
	HIGHLIGHT_ATTACK: Color(0.96, 0.43, 0.27, 0.98),
}

const TARGET_FRAME_SELECTED_PATH := "res://assets/card_game/ui/combat/combat_target_frame_selected.png"
const TARGET_FRAME_VALID_PATH := "res://assets/card_game/ui/combat/combat_target_frame_valid.png"
const TARGET_FRAME_ATTACK_PATH := "res://assets/card_game/ui/combat/combat_target_frame_invalid.png"
const TARGET_RING_ATTACK_PATH := "res://assets/card_game/ui/combat/combat_target_ring_attack.png"
const TARGET_RING_FRIENDLY_PATH := "res://assets/card_game/ui/combat/combat_target_ring_friendly.png"
const ACTION_GLOW_PATH := "res://assets/card_game/ui/combat/combat_card_select_glow.png"
const DAMAGE_POPUP_PATH := "res://assets/card_game/ui/combat/combat_damage_popup_red.png"
const HEAL_POPUP_PATH := "res://assets/card_game/ui/combat/combat_heal_popup_green.png"
const GUARD_BLOCK_PATH := "res://assets/card_game/ui/combat/combat_guard_block.png"
const DIRECT_HIT_BURST_PATH := "res://assets/card_game/ui/combat/combat_direct_hit_burst.png"
const KO_STAMP_PATH := "res://assets/card_game/ui/combat/combat_ko_stamp.png"
const LANE_FLASH_HIT_PATH := "res://assets/card_game/ui/combat/combat_lane_flash_hit.png"
const LANE_FLASH_KO_PATH := "res://assets/card_game/ui/combat/combat_lane_flash_ko.png"
const READY_BADGE_PATH := "res://assets/card_game/ui/combat/combat_ready_badge.png"
const SPENT_BADGE_PATH := "res://assets/card_game/ui/combat/combat_spent_badge.png"

const HIGHLIGHT_FRAME_TEXTURES := {
	HIGHLIGHT_PLAY: TARGET_FRAME_VALID_PATH,
	HIGHLIGHT_SELECTED: TARGET_FRAME_SELECTED_PATH,
	HIGHLIGHT_ATTACK: TARGET_FRAME_ATTACK_PATH,
}

const TARGET_RING_TEXTURES := {
	HIGHLIGHT_PLAY: TARGET_RING_FRIENDLY_PATH,
	HIGHLIGHT_ATTACK: TARGET_RING_ATTACK_PATH,
}

const EVENT_NEUTRAL := &"neutral"
const EVENT_ACTION := &"action"
const EVENT_DAMAGE := &"damage"
const EVENT_SUPPORT := &"support"
const EVENT_BLOCK := &"block"
const EVENT_DIRECT := &"direct"
const EVENT_KO := &"ko"

const STATUS_READY := &"ready"
const STATUS_SPENT := &"spent"

const SIDE_THEMES := {
	OWNER_PLAYER: {
		"side_text": "TVA",
		"panel_bg": Color(0.09, 0.1, 0.07, 0.68),
		"panel_border": Color(0.56, 0.64, 0.33, 0.78),
		"slot_bg": Color(0.08, 0.09, 0.06, 0.94),
		"slot_border": Color(0.72, 0.78, 0.38, 0.74),
		"badge_bg": Color(0.16, 0.18, 0.09, 0.92),
		"badge_border": Color(0.76, 0.78, 0.38, 0.96),
		"badge_text": Color(0.95, 0.98, 0.9, 1.0),
		"lane_text": Color(0.95, 0.98, 0.88, 1.0),
		"empty_bg": Color(0.11, 0.13, 0.08, 0.46),
		"empty_border": Color(0.62, 0.67, 0.34, 0.56),
		"empty_text": Color(0.93, 0.96, 0.86, 0.82),
		"hint_text": Color(0.84, 0.9, 0.75, 0.95),
		"ribbon_bg": Color(0.14, 0.14, 0.08, 0.94),
		"ribbon_border": Color(0.78, 0.76, 0.4, 0.96),
		"ribbon_text": Color(0.98, 0.98, 0.92, 1.0),
		"glow": Color(0.54, 0.82, 0.36, 0.07),
	},
	OWNER_ENEMY: {
		"side_text": "SOUPER",
		"panel_bg": Color(0.12, 0.08, 0.07, 0.68),
		"panel_border": Color(0.68, 0.31, 0.28, 0.78),
		"slot_bg": Color(0.1, 0.05, 0.05, 0.94),
		"slot_border": Color(0.78, 0.36, 0.32, 0.74),
		"badge_bg": Color(0.22, 0.09, 0.08, 0.92),
		"badge_border": Color(0.82, 0.41, 0.34, 0.96),
		"badge_text": Color(1.0, 0.93, 0.9, 1.0),
		"lane_text": Color(0.99, 0.9, 0.86, 1.0),
		"empty_bg": Color(0.15, 0.08, 0.07, 0.46),
		"empty_border": Color(0.6, 0.3, 0.26, 0.56),
		"empty_text": Color(0.98, 0.9, 0.87, 0.82),
		"hint_text": Color(0.96, 0.8, 0.74, 0.95),
		"ribbon_bg": Color(0.22, 0.09, 0.08, 0.94),
		"ribbon_border": Color(0.82, 0.41, 0.34, 0.96),
		"ribbon_text": Color(1.0, 0.95, 0.93, 1.0),
		"glow": Color(0.78, 0.18, 0.16, 0.08),
	},
}

const EVENT_STYLES := {
	EVENT_NEUTRAL: {
		"bg": Color(0.37, 0.22, 0.09, 0.94),
		"border": Color(0.88, 0.72, 0.42, 0.95),
		"text": Color(0.98, 0.92, 0.82, 1.0),
	},
	EVENT_ACTION: {
		"bg": Color(0.43, 0.28, 0.09, 0.95),
		"border": Color(0.95, 0.78, 0.38, 0.98),
		"text": Color(1.0, 0.95, 0.84, 1.0),
	},
	EVENT_DAMAGE: {
		"bg": Color(0.39, 0.1, 0.08, 0.95),
		"border": Color(0.93, 0.45, 0.35, 0.98),
		"text": Color(1.0, 0.87, 0.82, 1.0),
	},
	EVENT_SUPPORT: {
		"bg": Color(0.11, 0.28, 0.2, 0.95),
		"border": Color(0.56, 0.88, 0.62, 0.96),
		"text": Color(0.92, 0.98, 0.93, 1.0),
	},
	EVENT_BLOCK: {
		"bg": Color(0.18, 0.22, 0.3, 0.95),
		"border": Color(0.58, 0.72, 0.9, 0.96),
		"text": Color(0.93, 0.96, 1.0, 1.0),
	},
	EVENT_DIRECT: {
		"bg": Color(0.49, 0.24, 0.08, 0.95),
		"border": Color(0.98, 0.67, 0.23, 0.98),
		"text": Color(1.0, 0.94, 0.86, 1.0),
	},
	EVENT_KO: {
		"bg": Color(0.27, 0.06, 0.06, 0.96),
		"border": Color(0.92, 0.3, 0.3, 0.98),
		"text": Color(1.0, 0.89, 0.89, 1.0),
	},
}

const EVENT_BANNER_TEXTURES := {
	EVENT_ACTION: DAMAGE_POPUP_PATH,
	EVENT_DAMAGE: DAMAGE_POPUP_PATH,
	EVENT_SUPPORT: HEAL_POPUP_PATH,
	EVENT_DIRECT: DAMAGE_POPUP_PATH,
	EVENT_BLOCK: DAMAGE_POPUP_PATH,
	EVENT_KO: DAMAGE_POPUP_PATH,
}

const EVENT_FLASH_TEXTURES := {
	EVENT_ACTION: ACTION_GLOW_PATH,
	EVENT_DAMAGE: LANE_FLASH_HIT_PATH,
	EVENT_BLOCK: LANE_FLASH_HIT_PATH,
	EVENT_DIRECT: LANE_FLASH_HIT_PATH,
	EVENT_KO: LANE_FLASH_KO_PATH,
}

const EVENT_TOKEN_TEXTURES := {
	EVENT_DAMAGE: DAMAGE_POPUP_PATH,
	EVENT_SUPPORT: HEAL_POPUP_PATH,
	EVENT_BLOCK: GUARD_BLOCK_PATH,
	EVENT_DIRECT: DIRECT_HIT_BURST_PATH,
	EVENT_KO: KO_STAMP_PATH,
}

const EVENT_SURFACE_ACCENTS := {
	EVENT_ACTION: {
		"border": Color(0.95, 0.76, 0.34, 0.96),
		"bg": Color(0.27, 0.15, 0.08, 0.62),
	},
	EVENT_DAMAGE: {
		"border": Color(0.94, 0.42, 0.35, 0.96),
		"bg": Color(0.24, 0.08, 0.08, 0.64),
	},
	EVENT_SUPPORT: {
		"border": Color(0.56, 0.88, 0.62, 0.96),
		"bg": Color(0.10, 0.18, 0.12, 0.64),
	},
	EVENT_BLOCK: {
		"border": Color(0.58, 0.72, 0.9, 0.96),
		"bg": Color(0.11, 0.14, 0.2, 0.64),
	},
	EVENT_DIRECT: {
		"border": Color(0.98, 0.66, 0.22, 0.98),
		"bg": Color(0.27, 0.13, 0.07, 0.66),
	},
	EVENT_KO: {
		"border": Color(0.92, 0.3, 0.3, 0.98),
		"bg": Color(0.24, 0.06, 0.06, 0.66),
	},
}

const STATUS_BADGE_TEXTURES := {
	STATUS_READY: READY_BADGE_PATH,
	STATUS_SPENT: SPENT_BADGE_PATH,
}


func _ready() -> void:
	highlight.visible = false
	slot_glow.visible = false
	card_shadow.visible = false
	card_preview.set_display_mode(SelectedCardPreviewScript.DISPLAY_BOARD)
	card_preview.set_card_instance(null)
	card_preview.visible = false
	wound_glow.visible = false
	highlight_frame.visible = false
	target_ring_center.visible = false
	flash_texture.visible = false
	event_token_center.visible = false
	status_badge.visible = false
	status_badge_label.visible = false
	event_panel.visible = false
	event_background.visible = false
	event_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_make_children_click_through(self)
	_apply_side_accent()
	_refresh_slot_contents()


func configure(new_lane_index: int, new_owner_id: int, title: String, empty_hint: String) -> void:
	lane_index = new_lane_index
	owner_id = new_owner_id
	lane_label.text = title
	_empty_hint = empty_hint
	_apply_side_accent()
	_refresh_slot_contents()


func set_card_instance(card_instance: CardInstance) -> void:
	_card_instance = card_instance
	_refresh_slot_contents()
	_refresh_status_badge()
	_refresh_recent_event()


func set_highlight_mode(mode: StringName) -> void:
	_current_highlight_mode = mode
	if mode == HIGHLIGHT_NONE:
		highlight.visible = false
		highlight_frame.visible = false
		target_ring_center.visible = false
		slot_glow.visible = false
		_apply_side_accent()
		return

	highlight.visible = true
	var glow_color: Color = HIGHLIGHT_COLORS.get(mode, HIGHLIGHT_COLORS[HIGHLIGHT_PLAY])
	highlight.color = glow_color
	slot_glow.visible = true
	slot_glow.color = Color(glow_color.r, glow_color.g, glow_color.b, glow_color.a * 0.34)
	highlight_frame.texture = _load_ui_texture(str(HIGHLIGHT_FRAME_TEXTURES.get(mode, "")))
	highlight_frame.visible = highlight_frame.texture != null
	target_ring.texture = _load_ui_texture(str(TARGET_RING_TEXTURES.get(mode, "")))
	target_ring_center.visible = target_ring.texture != null
	_apply_side_accent()


func set_recent_event(text: String, tone: StringName = EVENT_NEUTRAL) -> void:
	_recent_event_text = text.strip_edges()
	_recent_event_tone = tone
	_refresh_recent_event()


func clear_recent_event() -> void:
	set_recent_event("", EVENT_NEUTRAL)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		slot_pressed.emit(lane_index, owner_id)
		get_viewport().set_input_as_handled()


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("instance_id")


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY or not data.has("instance_id"):
		return
	card_dropped.emit(int(data["instance_id"]), lane_index, owner_id)


func _refresh_slot_contents() -> void:
	var has_card := _card_instance != null and _card_instance.definition != null
	card_preview.set_card_instance(_card_instance)
	card_preview.visible = has_card
	card_shadow.visible = has_card
	wound_glow.visible = has_card and _is_card_wounded(_card_instance)
	empty_frame.visible = not has_card
	empty_label.visible = not has_card
	empty_hint_label.visible = false
	name_ribbon.visible = has_card

	if has_card:
		occupant_label.text = _card_instance.definition.display_name
	else:
		occupant_label.text = "Prazdno"
		empty_label.text = _build_empty_art_label()

	_apply_side_accent()


func _apply_side_accent() -> void:
	var side_theme: Dictionary = SIDE_THEMES.get(owner_id, SIDE_THEMES[OWNER_PLAYER])
	var panel_bg: Color = side_theme["panel_bg"]
	var panel_border: Color = side_theme["panel_border"]
	var slot_bg: Color = side_theme["slot_bg"]
	var slot_border: Color = side_theme["slot_border"]
	var ribbon_bg: Color = side_theme["ribbon_bg"]
	var ribbon_border: Color = side_theme["ribbon_border"]

	if _is_card_wounded(_card_instance):
		slot_bg = slot_bg.lerp(Color(0.2, 0.05, 0.05, 0.96), 0.35)
		slot_border = slot_border.lerp(Color(0.94, 0.32, 0.28, 0.98), 0.6)
		ribbon_border = ribbon_border.lerp(Color(0.95, 0.34, 0.3, 0.98), 0.7)

	var accent: Dictionary = EVENT_SURFACE_ACCENTS.get(_recent_event_tone, {})
	if not accent.is_empty():
		slot_border = accent["border"]
		slot_bg = slot_bg.lerp(accent["bg"], 0.46)

	if _current_highlight_mode != HIGHLIGHT_NONE:
		slot_border = HIGHLIGHT_BORDER_COLORS.get(_current_highlight_mode, slot_border)
		slot_glow.color = Color(HIGHLIGHT_COLORS[_current_highlight_mode].r, HIGHLIGHT_COLORS[_current_highlight_mode].g, HIGHLIGHT_COLORS[_current_highlight_mode].b, 0.1)

	add_theme_stylebox_override("panel", _build_style_box(panel_bg, panel_border, 18, 1, 6, Color(0, 0, 0, 0.16)))
	slot_shell.add_theme_stylebox_override("panel", _build_style_box(slot_bg, slot_border, 18, 2))
	side_badge.add_theme_stylebox_override("panel", _build_style_box(side_theme["badge_bg"], side_theme["badge_border"], 10, 1))
	empty_frame.add_theme_stylebox_override("panel", _build_style_box(side_theme["empty_bg"], side_theme["empty_border"], 16, 2))
	name_ribbon.add_theme_stylebox_override("panel", _build_style_box(ribbon_bg, ribbon_border, 12, 1))

	side_label.text = str(side_theme["side_text"])
	side_label.add_theme_color_override("font_color", side_theme["badge_text"])
	lane_label.add_theme_color_override("font_color", side_theme["lane_text"])
	empty_label.add_theme_color_override("font_color", side_theme["empty_text"])
	empty_hint_label.add_theme_color_override("font_color", side_theme["hint_text"])
	occupant_label.add_theme_color_override("font_color", side_theme["ribbon_text"])
	slot_glow.visible = _current_highlight_mode != HIGHLIGHT_NONE
	if _current_highlight_mode == HIGHLIGHT_NONE:
		slot_glow.color = side_theme["glow"]


func _refresh_status_badge() -> void:
	if _card_instance == null:
		status_badge.visible = false
		status_badge_label.visible = false
		return

	var status := STATUS_READY if _card_instance.can_attack and not _card_instance.has_attacked else STATUS_SPENT
	status_badge.texture = _load_ui_texture(str(STATUS_BADGE_TEXTURES.get(status, "")))
	status_badge.visible = status_badge.texture != null
	status_badge_label.visible = false


func _refresh_recent_event() -> void:
	_apply_side_accent()
	if _recent_event_text.is_empty():
		event_panel.visible = false
		flash_texture.visible = false
		event_token_center.visible = false
		event_token.texture = null
		return

	var style_data: Dictionary = EVENT_STYLES.get(_recent_event_tone, EVENT_STYLES[EVENT_NEUTRAL])
	var banner_texture: Texture2D = _load_ui_texture(str(EVENT_BANNER_TEXTURES.get(_recent_event_tone, "")))
	var flash_texture_resource: Texture2D = _load_ui_texture(str(EVENT_FLASH_TEXTURES.get(_recent_event_tone, "")))
	var event_token_texture: Texture2D = _load_ui_texture(str(EVENT_TOKEN_TEXTURES.get(_recent_event_tone, "")))
	var show_banner := banner_texture != null

	event_panel.visible = show_banner
	if show_banner:
		event_panel.add_theme_stylebox_override("panel", _build_texture_box(banner_texture))
	else:
		event_panel.add_theme_stylebox_override("panel", _build_style_box(style_data["bg"], style_data["border"], 10, 1))
	event_label.visible = true
	event_label.add_theme_color_override("font_color", style_data["text"])
	event_label.text = _recent_event_text

	flash_texture.texture = flash_texture_resource
	flash_texture.visible = flash_texture_resource != null
	event_token.texture = event_token_texture
	event_token_center.visible = event_token_texture != null


func _is_card_wounded(card_instance: CardInstance) -> bool:
	return card_instance != null and card_instance.definition != null and card_instance.current_life < card_instance.definition.life


func _build_empty_art_label() -> String:
	if owner_id == OWNER_ENEMY:
		return "PRIMY ZASAH"
	return "VYLOZ KOCKU"


func _build_style_box(
	background_color: Color,
	border_color: Color,
	corner_radius: int,
	border_width: int,
	shadow_size: int = 0,
	shadow_color: Color = Color(0, 0, 0, 0.0)
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = border_color
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.shadow_color = shadow_color
	style.shadow_size = shadow_size
	return style


func _build_texture_box(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 88.0
	style.texture_margin_top = 36.0
	style.texture_margin_right = 88.0
	style.texture_margin_bottom = 36.0
	return style


func _load_ui_texture(resource_path: String) -> Texture2D:
	if resource_path.is_empty():
		return null
	if _ui_texture_cache.has(resource_path):
		return _ui_texture_cache[resource_path]

	var texture: Texture2D = null
	var image_path := ProjectSettings.globalize_path(resource_path)
	var image := Image.load_from_file(image_path)
	if image != null and not image.is_empty():
		texture = ImageTexture.create_from_image(image)
	if texture == null:
		push_warning("Could not load UI texture %s." % resource_path)
		return null

	_ui_texture_cache[resource_path] = texture
	return texture


func _make_children_click_through(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_make_children_click_through(child)
