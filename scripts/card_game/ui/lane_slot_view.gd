class_name LaneSlotView
extends PanelContainer

const CardInstance = preload("res://scripts/card_game/runtime/card_instance.gd")
const SelectedCardPreviewScript = preload("res://scripts/card_game/ui/selected_card_preview.gd")
const CardArtCache = preload("res://scripts/card_game/ui/card_art_cache.gd")
const BattleFx = preload("res://scripts/card_game/ui/battle_fx.gd")

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
@onready var empty_frame_texture: TextureRect = $Margin/VBox/SlotShell/EmptyFrame/EmptyFrameTexture
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
var _empty_hint: String = "Volná lajna."
var _current_highlight_mode: StringName = &"none"
var _recent_event_text: String = ""
var _recent_event_tone: StringName = &"neutral"
var _preview_event_text: String = ""
var _preview_event_tone: StringName = &"neutral"
static var _ui_texture_cache: Dictionary = {}

# Compact board token (built in code) shown for a placed cat instead of the
# shrunk ornate full-card frame, which looked like an empty placeholder.
var _token_panel: PanelContainer
var _token_cost: Label
var _token_keyword: Label
var _token_name: Label
var _token_attack: Label
var _token_life: Label
var _token_art: TextureRect
var _token_keyword_box: PanelContainer
var _token_content: Control
var _token_keyword_icon: TextureRect

const OWNER_PLAYER := 0
const OWNER_ENEMY := 1

const HIGHLIGHT_NONE := &"none"
const HIGHLIGHT_PLAY := &"play"
const HIGHLIGHT_SELECTED := &"selected"
const HIGHLIGHT_ATTACK := &"attack"
const HIGHLIGHT_THREAT := &"threat"

const HIGHLIGHT_COLORS := {
	HIGHLIGHT_PLAY: Color(0.42, 0.94, 0.56, 0.34),
	HIGHLIGHT_SELECTED: Color(0.99, 0.86, 0.4, 0.34),
	HIGHLIGHT_ATTACK: Color(0.98, 0.48, 0.22, 0.38),
	HIGHLIGHT_THREAT: Color(0.96, 0.22, 0.18, 0.32),
}

const HIGHLIGHT_BORDER_COLORS := {
	HIGHLIGHT_PLAY: Color(0.56, 0.92, 0.58, 0.96),
	HIGHLIGHT_SELECTED: Color(0.99, 0.84, 0.43, 0.98),
	HIGHLIGHT_ATTACK: Color(0.96, 0.43, 0.27, 0.98),
	HIGHLIGHT_THREAT: Color(0.99, 0.36, 0.24, 0.98),
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
	HIGHLIGHT_THREAT: TARGET_FRAME_ATTACK_PATH,
}

const TARGET_RING_TEXTURES := {
	HIGHLIGHT_PLAY: TARGET_RING_FRIENDLY_PATH,
	HIGHLIGHT_SELECTED: TARGET_RING_FRIENDLY_PATH,
	HIGHLIGHT_ATTACK: TARGET_RING_ATTACK_PATH,
	HIGHLIGHT_THREAT: TARGET_RING_ATTACK_PATH,
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
		"side_text": "TY",
		"panel_bg": Color(0.09, 0.1, 0.07, 0.68),
		"panel_border": Color(0.56, 0.64, 0.33, 0.78),
		"slot_bg": Color(0.08, 0.09, 0.06, 0.72),
		"slot_border": Color(0.72, 0.78, 0.38, 0.62),
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
		"side_text": "SOUPEŘ",
		"panel_bg": Color(0.12, 0.08, 0.07, 0.68),
		"panel_border": Color(0.68, 0.31, 0.28, 0.78),
		"slot_bg": Color(0.1, 0.05, 0.05, 0.72),
		"slot_border": Color(0.78, 0.36, 0.32, 0.62),
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
	_build_token_panel()
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
	highlight.visible = false
	slot_glow.visible = false
	highlight_frame.visible = false
	if mode == HIGHLIGHT_NONE:
		target_ring_center.visible = false
		_apply_side_accent()
		return

	target_ring.texture = _load_ui_texture(str(TARGET_RING_TEXTURES.get(mode, "")))
	target_ring_center.visible = target_ring.texture != null and _should_show_target_ring()
	_apply_side_accent()


func set_recent_event(text: String, tone: StringName = EVENT_NEUTRAL) -> void:
	_recent_event_text = text.strip_edges()
	_recent_event_tone = tone
	_refresh_recent_event()


func clear_recent_event() -> void:
	set_recent_event("", EVENT_NEUTRAL)


func set_preview_event(text: String, tone: StringName = EVENT_NEUTRAL) -> void:
	_preview_event_text = text.strip_edges()
	_preview_event_tone = tone
	_refresh_recent_event()


func clear_preview_event() -> void:
	set_preview_event("", EVENT_NEUTRAL)


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
	# Board now renders a compact code-built token, not the ornate full-card preview.
	card_preview.set_card_instance(null)
	card_preview.visible = false
	card_shadow.visible = has_card
	wound_glow.visible = has_card and _is_card_wounded(_card_instance)
	empty_frame.visible = not has_card
	empty_label.visible = not has_card
	empty_hint_label.visible = false
	name_ribbon.visible = false

	if _token_panel != null:
		_token_panel.visible = has_card
		if has_card:
			_populate_token()

	if has_card:
		occupant_label.text = _card_instance.definition.display_name
	else:
		occupant_label.text = "Prázdno"
		empty_label.text = _build_empty_art_label()

	_apply_side_accent()


func _apply_side_accent() -> void:
	var side_theme: Dictionary = SIDE_THEMES.get(owner_id, SIDE_THEMES[OWNER_PLAYER])
	var ribbon_bg: Color = side_theme["ribbon_bg"]
	var ribbon_border: Color = side_theme["ribbon_border"]

	if _is_card_wounded(_card_instance):
		ribbon_border = ribbon_border.lerp(Color(0.95, 0.34, 0.3, 0.98), 0.7)

	var accent_tone := _get_active_event_tone()
	var accent: Dictionary = EVENT_SURFACE_ACCENTS.get(accent_tone, {})
	if _current_highlight_mode != HIGHLIGHT_NONE and not _should_show_target_ring():
		ribbon_border = HIGHLIGHT_BORDER_COLORS.get(_current_highlight_mode, ribbon_border)

	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	slot_shell.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	side_badge.add_theme_stylebox_override("panel", _build_style_box(side_theme["badge_bg"], side_theme["badge_border"], 10, 1))
	empty_frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	name_ribbon.add_theme_stylebox_override("panel", _build_style_box(ribbon_bg, ribbon_border, 12, 1))

	side_label.text = str(side_theme["side_text"])
	side_label.add_theme_color_override("font_color", side_theme["badge_text"])
	lane_label.add_theme_color_override("font_color", side_theme["lane_text"])
	empty_label.add_theme_color_override("font_color", side_theme["empty_text"])
	empty_hint_label.add_theme_color_override("font_color", side_theme["hint_text"])
	occupant_label.add_theme_color_override("font_color", side_theme["ribbon_text"])
	empty_frame_texture.texture = _load_ui_texture(_empty_frame_texture_path())
	empty_frame_texture.modulate = _empty_frame_modulate()
	target_ring_center.visible = target_ring.texture != null and _should_show_target_ring()
	slot_glow.visible = false
	if _card_instance != null and _card_instance.definition != null:
		_style_token()


func _build_token_panel() -> void:
	_token_panel = PanelContainer.new()
	_token_panel.anchor_right = 1.0
	_token_panel.anchor_bottom = 1.0
	_token_panel.offset_left = 6.0
	_token_panel.offset_top = 6.0
	_token_panel.offset_right = -6.0
	_token_panel.offset_bottom = -6.0
	_token_panel.visible = false
	slot_shell.add_child(_token_panel)
	# Sit just above the card layer but below the event/KO/flash overlays.
	slot_shell.move_child(_token_panel, 3)

	# Free-layout content so labels are placed by anchors (nested HBox/VBox
	# wouldn't distribute reliably inside the slot's container chain).
	var content := Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.clip_contents = true
	_token_panel.add_child(content)
	_token_content = content

	# Art karty přes celý token (oříznutý na střed), aby hráč poznal kočku na první pohled.
	_token_art = TextureRect.new()
	_token_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_token_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_token_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_token_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	content.add_child(_token_art)
	_token_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Tmavý pruh dole pod jménem a staty, aby text byl čitelný přes art.
	var strip := Panel.new()
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_theme_stylebox_override("panel", _build_style_box(Color(0.06, 0.04, 0.03, 0.82), Color(0, 0, 0, 0), 0, 0))
	content.add_child(strip)
	strip.anchor_top = 1.0
	strip.anchor_right = 1.0
	strip.anchor_bottom = 1.0
	strip.offset_top = -44.0

	_token_name = _make_token_label("", 16, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
	_token_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_token_name.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_token_name.add_theme_constant_override("outline_size", 4)
	_place_token_label(content, _token_name, 0.0, 1.0, 1.0, 1.0, 54.0, -44.0, -54.0, 0.0)

	_token_cost = _make_token_badge(content, Color(0.16, 0.34, 0.62), 0.0, 0.0, 6.0, 6.0, 34.0, 20)
	_token_attack = _make_token_badge(content, Color(0.7, 0.42, 0.1), 0.0, 1.0, 6.0, -46.0, 40.0, 24)
	_token_life = _make_token_badge(content, Color(0.62, 0.16, 0.14), 1.0, 1.0, -46.0, -46.0, 40.0, 24)

	_token_keyword_box = PanelContainer.new()
	_token_keyword_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_token_keyword_box.add_theme_stylebox_override("panel", _build_style_box(Color(0.08, 0.06, 0.04, 0.85), Color(0.9, 0.78, 0.45, 0.7), 8, 1))
	content.add_child(_token_keyword_box)
	_token_keyword_box.anchor_left = 0.5
	_token_keyword_box.anchor_right = 0.5
	_token_keyword_box.offset_top = 6.0
	_token_keyword_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	var keyword_row := HBoxContainer.new()
	keyword_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	keyword_row.add_theme_constant_override("separation", 4)
	_token_keyword_box.add_child(keyword_row)
	# Ikona keywordu (game-icons.net, CC BY 3.0, viz assets/card_game/icons/ATTRIBUTION.md).
	_token_keyword_icon = TextureRect.new()
	_token_keyword_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_token_keyword_icon.custom_minimum_size = Vector2(16, 16)
	_token_keyword_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_token_keyword_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_token_keyword_icon.modulate = Color(0.98, 0.84, 0.5)
	keyword_row.add_child(_token_keyword_icon)
	_token_keyword = _make_token_label("", 13, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
	keyword_row.add_child(_token_keyword)

	_fix_status_badge_layout()


# Kruhový odznak s číslem (cena / útok / životy) v rohu tokenu.
func _make_token_badge(parent: Control, color: Color, anchor_x: float, anchor_y: float, off_x: float, off_y: float, diameter: float, font_size: int) -> Label:
	var badge := Panel.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override("panel", _build_style_box(color, Color(0.98, 0.88, 0.62, 0.95), int(diameter / 2.0), 2, 4, Color(0, 0, 0, 0.5)))
	parent.add_child(badge)
	badge.anchor_left = anchor_x
	badge.anchor_right = anchor_x
	badge.anchor_top = anchor_y
	badge.anchor_bottom = anchor_y
	badge.offset_left = off_x
	badge.offset_top = off_y
	badge.offset_right = off_x + diameter
	badge.offset_bottom = off_y + diameter
	var label := _make_token_label("0", font_size, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 4)
	badge.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return label


# SlotShell je PanelContainer, který ignoruje anchory dětí a StatusBadge roztáhl přes
# celý slot (velký medailon přes kartu). Přesuneme ho do volného overlaye, kde anchory platí.
func _fix_status_badge_layout() -> void:
	if status_badge.get_parent() != slot_shell:
		return
	var overlay := Control.new()
	overlay.name = "StatusOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_shell.add_child(overlay)
	slot_shell.move_child(overlay, status_badge.get_index())
	status_badge.reparent(overlay, false)
	status_badge.anchor_left = 1.0
	status_badge.anchor_right = 1.0
	status_badge.anchor_top = 0.0
	status_badge.anchor_bottom = 0.0
	status_badge.offset_left = -50.0
	status_badge.offset_top = 4.0
	status_badge.offset_right = -6.0
	status_badge.offset_bottom = 48.0

	# Event štítek: dole nad pruhem se jménem, uprostřed, jen tak velký jako text.
	if event_panel.get_parent() == slot_shell:
		var event_overlay := Control.new()
		event_overlay.name = "EventOverlay"
		event_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_shell.add_child(event_overlay)
		event_panel.reparent(event_overlay, false)
		event_panel.anchor_left = 0.5
		event_panel.anchor_right = 0.5
		event_panel.anchor_top = 1.0
		event_panel.anchor_bottom = 1.0
		event_panel.offset_left = 0.0
		event_panel.offset_right = 0.0
		event_panel.offset_top = -88.0
		event_panel.offset_bottom = -54.0
		event_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
		event_panel.grow_vertical = Control.GROW_DIRECTION_BOTH


func _make_token_label(text: String, font_size: int, halign: int, valign: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = halign
	label.vertical_alignment = valign
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _place_token_label(parent: Control, label: Label, al: float, at: float, ar: float, ab: float, ol: float, ot: float, orr: float, ob: float) -> void:
	parent.add_child(label)
	label.anchor_left = al
	label.anchor_top = at
	label.anchor_right = ar
	label.anchor_bottom = ab
	label.offset_left = ol
	label.offset_top = ot
	label.offset_right = orr
	label.offset_bottom = ob


func _populate_token() -> void:
	if _token_panel == null or _card_instance == null or _card_instance.definition == null:
		return
	var def = _card_instance.definition
	_token_cost.text = str(def.cost)
	_token_name.text = def.display_name
	_token_art.texture = CardArtCache.get_cropped(def.art_path)
	_token_attack.text = str(_card_instance.current_attack)
	_token_life.text = str(_card_instance.current_life)

	var keywords: Array = def.keywords
	if keywords.size() > 0:
		var keyword_text := str(CardGameConstants.keyword_label(keywords[0]))
		if keywords.size() > 1:
			keyword_text += " +%s" % (keywords.size() - 1)
		_token_keyword.text = "%s " % keyword_text
		_token_keyword_icon.texture = CardArtCache.get_keyword_icon(keywords[0])
		_token_keyword_icon.visible = _token_keyword_icon.texture != null
		_token_keyword_box.visible = true
	else:
		_token_keyword_box.visible = false

	var wounded := _is_card_wounded(_card_instance)
	var base_attack: int = def.attack
	var base_life: int = def.life
	var buffed_life: bool = _card_instance.current_life > base_life
	_token_cost.add_theme_color_override("font_color", Color(0.74, 0.88, 1.0))
	_token_keyword.add_theme_color_override("font_color", Color(0.9, 0.84, 0.6))
	_token_name.add_theme_color_override("font_color", Color(0.97, 0.94, 0.86))
	var attack_color: Color = Color(0.6, 0.95, 0.62) if _card_instance.current_attack > base_attack else Color(0.99, 0.76, 0.36)
	_token_attack.add_theme_color_override("font_color", attack_color)
	var life_color: Color = Color(0.96, 0.5, 0.45) if wounded else (Color(0.6, 0.95, 0.62) if buffed_life else Color(0.96, 0.86, 0.7))
	_token_life.add_theme_color_override("font_color", life_color)

	_style_token()


func _style_token() -> void:
	if _token_panel == null:
		return
	var side_theme: Dictionary = SIDE_THEMES.get(owner_id, SIDE_THEMES[OWNER_PLAYER])
	var bg := Color(0.13, 0.1, 0.08, 1.0)
	var border: Color = side_theme["ribbon_border"]
	if _is_card_wounded(_card_instance):
		border = border.lerp(Color(0.95, 0.34, 0.3, 0.98), 0.7)
	if _current_highlight_mode != HIGHLIGHT_NONE and not _should_show_target_ring():
		border = HIGHLIGHT_BORDER_COLORS.get(_current_highlight_mode, border)
	_token_panel.add_theme_stylebox_override("panel", _build_style_box(bg, border, 12, 2, 8, Color(0, 0, 0, 0.35)))


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
	var active_text := _get_active_event_text()
	if active_text.is_empty():
		event_panel.visible = false
		flash_texture.visible = false
		event_token_center.visible = false
		event_token.texture = null
		return

	if _should_hide_preview_banner():
		event_panel.visible = false
		flash_texture.visible = false
		event_token_center.visible = false
		event_token.texture = null
		return

	var active_tone := _get_active_event_tone()
	var style_data: Dictionary = EVENT_STYLES.get(active_tone, EVENT_STYLES[EVENT_NEUTRAL])
	var banner_texture: Texture2D = _load_ui_texture(str(EVENT_BANNER_TEXTURES.get(active_tone, "")))
	var flash_texture_resource: Texture2D = _load_ui_texture(str(EVENT_FLASH_TEXTURES.get(active_tone, "")))
	var event_token_texture: Texture2D = _load_ui_texture(str(EVENT_TOKEN_TEXTURES.get(active_tone, "")))
	var show_banner := banner_texture != null

	# Kompaktní štítek místo velkého texturového banneru přes celou kartu (D-008). Záblesky
	# a otřesy teď dělá BattleFx, takže celoplošné flash/token textury se u obsazeného slotu nekreslí.
	event_panel.visible = show_banner or not active_text.is_empty()
	var pill := _build_style_box(style_data["bg"], style_data["border"], 12, 2, 6, Color(0, 0, 0, 0.5))
	pill.content_margin_left = 12.0
	pill.content_margin_right = 12.0
	pill.content_margin_top = 3.0
	pill.content_margin_bottom = 3.0
	event_panel.add_theme_stylebox_override("panel", pill)
	event_background.visible = false
	event_label.visible = true
	event_label.add_theme_color_override("font_color", style_data["text"])
	event_label.add_theme_font_size_override("font_size", 16)
	event_label.text = active_text

	var has_card := _card_instance != null
	flash_texture.texture = flash_texture_resource
	flash_texture.visible = false
	event_token.texture = event_token_texture
	event_token_center.visible = event_token_texture != null and not has_card


func _get_active_event_text() -> String:
	if not _preview_event_text.is_empty():
		return _preview_event_text
	return _recent_event_text


func _get_active_event_tone() -> StringName:
	if not _preview_event_text.is_empty():
		return _preview_event_tone
	return _recent_event_tone


func _is_card_wounded(card_instance: CardInstance) -> bool:
	return card_instance != null and card_instance.definition != null and card_instance.current_life < card_instance.definition.life


func _build_empty_art_label() -> String:
	if owner_id == OWNER_ENEMY:
		return "PŘÍMÝ ZÁSAH"
	return "VYLOŽ KOČKU"


func _empty_frame_texture_path() -> String:
	if owner_id == OWNER_ENEMY:
		return SPENT_BADGE_PATH
	return READY_BADGE_PATH


func _should_show_target_ring() -> bool:
	return _current_highlight_mode != HIGHLIGHT_NONE and (_card_instance == null or _card_instance.definition == null)


func _should_hide_preview_banner() -> bool:
	return not _preview_event_text.is_empty() and _card_instance != null and _card_instance.definition != null


func _empty_frame_modulate() -> Color:
	var tint := Color(1.0, 1.0, 1.0, 0.94)
	if _current_highlight_mode != HIGHLIGHT_NONE:
		var highlight_color: Color = HIGHLIGHT_COLORS.get(_current_highlight_mode, Color.WHITE)
		tint = tint.lerp(Color(highlight_color.r, highlight_color.g, highlight_color.b, 1.0), 0.18)
	return tint


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
	style.texture_margin_left = 52.0
	style.texture_margin_top = 20.0
	style.texture_margin_right = 52.0
	style.texture_margin_bottom = 20.0
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


# --- Bojové efekty (volá controller po změně stavu) ---

# Útočník vyrazí směrem k soupeři.
func fx_attack() -> void:
	var direction := -1.0 if owner_id == OWNER_PLAYER else 1.0
	BattleFx.lunge(_token_panel, direction)


# Zásah do kočky v tomhle slotu.
func fx_hit(amount: int) -> void:
	BattleFx.shake(slot_shell)
	BattleFx.flash(slot_shell)
	BattleFx.float_text(slot_shell, "-%s" % amount, Color(1.0, 0.42, 0.36))


# Přímé zranění hráči skrz prázdnou lajnu.
func fx_direct(amount: int) -> void:
	BattleFx.flash(slot_shell, Color(1.7, 1.2, 0.5))
	BattleFx.float_text(slot_shell, "-%s ♥" % amount, Color(1.0, 0.78, 0.3), 46)


# Ochrana zachytila zásah.
func fx_block(amount: int) -> void:
	BattleFx.shake(slot_shell, 5.0)
	BattleFx.flash(slot_shell, Color(0.7, 1.0, 1.6))
	BattleFx.float_text(slot_shell, "-%s" % amount, Color(0.6, 0.85, 1.0))


# Nově vyložená kočka „dopadne“ na stůl.
func fx_enter() -> void:
	if not BattleFx.is_enabled() or _token_panel == null:
		return
	_token_panel.pivot_offset = _token_panel.size * 0.5
	_token_panel.scale = Vector2(1.18, 1.18)
	_token_panel.modulate.a = 0.0
	var tween := _token_panel.create_tween().set_parallel(true)
	tween.tween_property(_token_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_token_panel, "modulate:a", 1.0, 0.14)


func _make_children_click_through(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_make_children_click_through(child)
