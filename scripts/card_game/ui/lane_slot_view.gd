class_name LaneSlotView
extends PanelContainer

const CardInstance = preload("res://scripts/card_game/runtime/card_instance.gd")

signal slot_pressed(lane_index: int, owner_id: int)
signal card_dropped(instance_id: int, lane_index: int, owner_id: int)

@onready var lane_label: Label = $Margin/VBox/LaneLabel
@onready var art_panel: PanelContainer = $Margin/VBox/CardRow/ArtPanel
@onready var art_texture: TextureRect = $Margin/VBox/CardRow/ArtPanel/ArtTexture
@onready var art_label: Label = $Margin/VBox/CardRow/ArtPanel/ArtLabel
@onready var highlight_frame: TextureRect = $Margin/VBox/CardRow/ArtPanel/HighlightFrame
@onready var target_ring_center: CenterContainer = $Margin/VBox/CardRow/ArtPanel/TargetRingCenter
@onready var target_ring: TextureRect = $Margin/VBox/CardRow/ArtPanel/TargetRingCenter/TargetRing
@onready var flash_texture: TextureRect = $Margin/VBox/CardRow/ArtPanel/FlashTexture
@onready var event_token_center: CenterContainer = $Margin/VBox/CardRow/ArtPanel/EventTokenCenter
@onready var event_token: TextureRect = $Margin/VBox/CardRow/ArtPanel/EventTokenCenter/EventToken
@onready var status_badge: TextureRect = $Margin/VBox/CardRow/ArtPanel/StatusBadge
@onready var status_badge_label: Label = $Margin/VBox/CardRow/ArtPanel/StatusBadge/StatusLabel
@onready var event_panel: PanelContainer = $Margin/VBox/CardRow/ArtPanel/EventPanel
@onready var event_background: TextureRect = $Margin/VBox/CardRow/ArtPanel/EventPanel/EventBackground
@onready var event_label: Label = $Margin/VBox/CardRow/ArtPanel/EventPanel/EventLabel
@onready var occupant_label: Label = $Margin/VBox/CardRow/TextColumn/OccupantLabel
@onready var stats_label: Label = $Margin/VBox/CardRow/TextColumn/StatsLabel
@onready var highlight: ColorRect = $Highlight

var lane_index: int = -1
var owner_id: int = -1
var _card_instance: CardInstance
var _empty_hint: String = "Volna lajna."
static var _art_texture_cache: Dictionary = {}
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

const TARGET_FRAME_SELECTED_PATH := "res://assets/card_game/ui/combat/combat_target_frame_selected.png"
const TARGET_FRAME_VALID_PATH := "res://assets/card_game/ui/combat/combat_target_frame_valid.png"
const TARGET_FRAME_ATTACK_PATH := "res://assets/card_game/ui/combat/combat_target_frame_invalid.png"
const TARGET_RING_ATTACK_PATH := "res://assets/card_game/ui/combat/combat_target_ring_attack.png"
const TARGET_RING_FRIENDLY_PATH := "res://assets/card_game/ui/combat/combat_target_ring_friendly.png"
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

const STATUS_BADGE_TEXTURES := {
	STATUS_READY: READY_BADGE_PATH,
	STATUS_SPENT: SPENT_BADGE_PATH,
}

var _recent_event_text: String = ""
var _recent_event_tone: StringName = EVENT_NEUTRAL


func _ready() -> void:
	highlight.visible = false
	_make_children_click_through(self)
	art_texture.visible = false
	highlight_frame.visible = false
	target_ring_center.visible = false
	flash_texture.visible = false
	event_token_center.visible = false
	status_badge.visible = false
	status_badge_label.visible = false
	event_panel.visible = false
	event_background.visible = false
	event_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())


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
		lane_label.add_theme_color_override("font_color", Color(0.98, 0.9, 0.86, 1.0))
	else:
		sb.bg_color = Color(0.10, 0.11, 0.07, 0.55)
		sb.border_color = Color(0.6, 0.66, 0.34, 0.72)
		lane_label.add_theme_color_override("font_color", Color(0.95, 0.96, 0.86, 1.0))
	add_theme_stylebox_override("panel", sb)


func set_card_instance(card_instance: CardInstance) -> void:
	_card_instance = card_instance
	if card_instance == null:
		occupant_label.text = "Prazdno"
		stats_label.text = _empty_hint
		art_texture.texture = null
		art_texture.visible = false
		art_label.visible = true
		art_label.text = _build_empty_art_label()
	else:
		occupant_label.text = card_instance.definition.display_name
		var ready_text := "PRIPR." if card_instance.can_attack and not card_instance.has_attacked else "VYCERP."
		stats_label.text = "%s UTK / %s ZIV | %s" % [card_instance.current_attack, card_instance.current_life, ready_text]
		_refresh_art(card_instance)
	_refresh_state_text()
	_refresh_status_badge()
	_refresh_recent_event()


func set_highlight_mode(mode: StringName) -> void:
	if mode == HIGHLIGHT_NONE:
		highlight.visible = false
		highlight_frame.visible = false
		target_ring_center.visible = false
		return

	highlight.visible = true
	highlight.color = HIGHLIGHT_COLORS.get(mode, HIGHLIGHT_COLORS[HIGHLIGHT_PLAY])
	highlight_frame.texture = _load_ui_texture(str(HIGHLIGHT_FRAME_TEXTURES.get(mode, "")))
	highlight_frame.visible = highlight_frame.texture != null
	target_ring.texture = _load_ui_texture(str(TARGET_RING_TEXTURES.get(mode, "")))
	target_ring_center.visible = target_ring.texture != null


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


func _refresh_art(card_instance: CardInstance) -> void:
	if card_instance == null or card_instance.definition == null:
		art_texture.texture = null
		art_texture.visible = false
		art_label.visible = true
		art_label.text = _build_empty_art_label()
		return

	var art_path := card_instance.definition.art_path
	if art_path.is_empty():
		art_texture.texture = null
		art_texture.visible = false
		art_label.visible = true
		art_label.text = card_instance.definition.display_name
		return

	var texture := _load_art_texture(art_path)
	if texture == null:
		art_texture.texture = null
		art_texture.visible = false
		art_label.visible = true
		art_label.text = card_instance.definition.display_name
		return

	art_texture.texture = texture
	art_texture.visible = true
	art_label.visible = false


func _refresh_state_text() -> void:
	if _card_instance == null:
		occupant_label.modulate = Color(0.96, 0.94, 0.9, 1.0)
		stats_label.modulate = Color(0.9, 0.86, 0.76, 0.95)
		art_label.add_theme_color_override("font_color", Color(0.96, 0.9, 0.78, 0.88))
		return

	occupant_label.modulate = Color(1, 1, 1, 1)
	if _card_instance.can_attack and not _card_instance.has_attacked:
		stats_label.modulate = Color(0.76, 0.94, 0.72, 1.0)
		return

	stats_label.modulate = Color(0.9, 0.86, 0.76, 0.95)


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
	if _recent_event_text.is_empty():
		event_panel.visible = false
		flash_texture.visible = false
		event_token_center.visible = false
		return

	var style_data: Dictionary = EVENT_STYLES.get(_recent_event_tone, EVENT_STYLES[EVENT_NEUTRAL])
	var banner_texture: Texture2D = _load_ui_texture(str(EVENT_BANNER_TEXTURES.get(_recent_event_tone, "")))
	var show_banner := banner_texture != null

	event_panel.visible = show_banner
	if show_banner:
		event_panel.add_theme_stylebox_override("panel", _build_texture_box(banner_texture))
	else:
		event_panel.add_theme_stylebox_override("panel", _build_style_box(style_data["bg"], style_data["border"]))
	event_label.visible = true
	event_label.add_theme_color_override("font_color", style_data["text"])
	event_label.text = _recent_event_text

	flash_texture.visible = false
	event_token_center.visible = false


func _build_empty_art_label() -> String:
	if owner_id == OWNER_ENEMY:
		return "PRIMY ZASAH"
	return "VYLOZ KOCKU"


func _build_style_box(background_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border_color
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	return style


func _build_texture_box(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 88.0
	style.texture_margin_top = 36.0
	style.texture_margin_right = 88.0
	style.texture_margin_bottom = 36.0
	return style


func _load_art_texture(art_path: String) -> Texture2D:
	if art_path.is_empty():
		return null
	if _art_texture_cache.has(art_path):
		return _art_texture_cache[art_path]

	var texture := load(art_path) as Texture2D
	if texture == null:
		push_warning("Could not load card art %s." % art_path)
		return null

	_art_texture_cache[art_path] = texture
	return texture


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
