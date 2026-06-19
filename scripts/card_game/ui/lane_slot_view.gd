class_name LaneSlotView
extends PanelContainer

const CardInstance = preload("res://scripts/card_game/runtime/card_instance.gd")

signal slot_pressed(lane_index: int, owner_id: int)
signal card_dropped(instance_id: int, lane_index: int, owner_id: int)

@onready var lane_label: Label = $Margin/VBox/LaneLabel
@onready var art_panel: PanelContainer = $Margin/VBox/CardRow/ArtPanel
@onready var art_texture: TextureRect = $Margin/VBox/CardRow/ArtPanel/ArtTexture
@onready var art_label: Label = $Margin/VBox/CardRow/ArtPanel/ArtLabel
@onready var event_panel: PanelContainer = $Margin/VBox/CardRow/ArtPanel/EventPanel
@onready var event_label: Label = $Margin/VBox/CardRow/ArtPanel/EventPanel/EventLabel
@onready var occupant_label: Label = $Margin/VBox/CardRow/TextColumn/OccupantLabel
@onready var stats_label: Label = $Margin/VBox/CardRow/TextColumn/StatsLabel
@onready var highlight: ColorRect = $Highlight

var lane_index: int = -1
var owner_id: int = -1
var _card_instance: CardInstance
var _empty_hint: String = "Open lane."
static var _art_texture_cache: Dictionary = {}

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

const EVENT_NEUTRAL := &"neutral"
const EVENT_ACTION := &"action"
const EVENT_DAMAGE := &"damage"
const EVENT_SUPPORT := &"support"
const EVENT_BLOCK := &"block"
const EVENT_DIRECT := &"direct"
const EVENT_KO := &"ko"

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

var _recent_event_text: String = ""
var _recent_event_tone: StringName = EVENT_NEUTRAL


func _ready() -> void:
	highlight.visible = false
	_make_children_click_through(self)
	art_texture.visible = false
	event_panel.visible = false


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
		art_texture.texture = null
		art_texture.visible = false
		art_label.visible = false
		art_label.text = ""
	else:
		occupant_label.text = card_instance.definition.display_name
		var ready_text := "READY" if card_instance.can_attack and not card_instance.has_attacked else "SPENT"
		stats_label.text = "%s ATK / %s LIFE | %s" % [card_instance.current_attack, card_instance.current_life, ready_text]
		_refresh_art(card_instance)
	_refresh_state_text()
	_refresh_recent_event()


func set_highlight_mode(mode: StringName) -> void:
	if mode == HIGHLIGHT_NONE:
		highlight.visible = false
		return

	highlight.visible = true
	highlight.color = HIGHLIGHT_COLORS.get(mode, HIGHLIGHT_COLORS[HIGHLIGHT_PLAY])


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
		art_label.text = "Empty"
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
		stats_label.modulate = Color(0.9, 0.86, 0.76, 0.95)
		return

	if _card_instance.can_attack and not _card_instance.has_attacked:
		stats_label.modulate = Color(0.76, 0.94, 0.72, 1.0)
		return

	stats_label.modulate = Color(0.9, 0.86, 0.76, 0.95)


func _refresh_recent_event() -> void:
	if _recent_event_text.is_empty():
		event_panel.visible = false
		return

	var style_data: Dictionary = EVENT_STYLES.get(_recent_event_tone, EVENT_STYLES[EVENT_NEUTRAL])
	event_panel.visible = true
	event_panel.add_theme_stylebox_override("panel", _build_style_box(style_data["bg"], style_data["border"]))
	event_label.add_theme_color_override("font_color", style_data["text"])
	event_label.text = _recent_event_text


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


func _make_children_click_through(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_make_children_click_through(child)
