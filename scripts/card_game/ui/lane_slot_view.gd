class_name LaneSlotView
extends PanelContainer

const CardInstance = preload("res://scripts/card_game/runtime/card_instance.gd")

signal slot_pressed(lane_index: int, owner_id: int)
signal card_dropped(instance_id: int, lane_index: int, owner_id: int)

@onready var lane_label: Label = $Margin/VBox/LaneLabel
@onready var art_panel: PanelContainer = $Margin/VBox/CardRow/ArtPanel
@onready var art_texture: TextureRect = $Margin/VBox/CardRow/ArtPanel/ArtTexture
@onready var art_label: Label = $Margin/VBox/CardRow/ArtPanel/ArtLabel
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


func _ready() -> void:
	highlight.visible = false
	_make_children_click_through(self)
	art_texture.visible = false


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
		art_label.visible = true
		art_label.text = "Empty"
	else:
		occupant_label.text = card_instance.definition.display_name
		var ready_text := "Ready" if card_instance.can_attack and not card_instance.has_attacked else "Waiting"
		stats_label.text = "%s ATK / %s LIFE | %s" % [card_instance.current_attack, card_instance.current_life, ready_text]
		_refresh_art(card_instance)


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
