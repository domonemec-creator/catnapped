class_name ProgressionScreenMenu
extends Control

const EncounterSelectScene: PackedScene = preload("res://scenes/card_game/encounter_select.tscn")
const HEADER_TEXTURE_PATH := "res://assets/card_game/ui/header_panel_drapes.png"

var _panel_style: StyleBoxFlat
var _section_style: StyleBoxFlat
var _button_normal_style: StyleBoxFlat
var _button_hover_style: StyleBoxFlat
var _button_pressed_style: StyleBoxFlat
var _reset_button_normal_style: StyleBoxFlat
var _reset_button_hover_style: StyleBoxFlat
var _reset_button_pressed_style: StyleBoxFlat

var _progression_system := ProgressionSystem.new()
var _card_library: Dictionary = {}
var _progression_state: Dictionary = {}
var _deck_list: VBoxContainer
var _deck_total_label: Label
var _threat_label: Label
var _win_label: Label
var _loss_label: Label
var _run_label: Label
var _status_label: Label
var _reset_button: Button


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _build_styles()
    _build_ui()
    _load_state()
    _refresh_ui()


func _build_styles() -> void:
    _panel_style = _make_style(Color(0.13, 0.1, 0.08, 0.96), Color(0.6, 0.46, 0.24, 0.92), 2, 18, 8)
    _section_style = _make_style(Color(0.18, 0.14, 0.1, 0.96), Color(0.6, 0.46, 0.24, 0.92), 2, 14, 6)
    _button_normal_style = _make_style(Color(0.24, 0.19, 0.13, 1), Color(0.6, 0.46, 0.24, 0.92), 2, 12, 4)
    _button_hover_style = _make_style(Color(0.31, 0.24, 0.16, 1), Color(0.77, 0.59, 0.31, 0.98), 2, 12, 4)
    _button_pressed_style = _make_style(Color(0.42, 0.3, 0.17, 1), Color(0.9, 0.69, 0.36, 1), 2, 12, 4)
    _reset_button_normal_style = _make_style(Color(0.22, 0.15, 0.12, 1), Color(0.78, 0.35, 0.28, 0.95), 2, 12, 4)
    _reset_button_hover_style = _make_style(Color(0.31, 0.18, 0.14, 1), Color(0.92, 0.44, 0.34, 1), 2, 12, 4)
    _reset_button_pressed_style = _make_style(Color(0.22, 0.15, 0.12, 1), Color(0.78, 0.35, 0.28, 0.95), 2, 12, 4)


func _build_ui() -> void:
    var background := ColorRect.new()
    background.set_anchors_preset(Control.PRESET_FULL_RECT)
    background.color = Color(0.08, 0.06, 0.04, 1)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)

    var margin := MarginContainer.new()
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 28)
    margin.add_theme_constant_override("margin_top", 28)
    margin.add_theme_constant_override("margin_right", 28)
    margin.add_theme_constant_override("margin_bottom", 28)
    add_child(margin)

    var layout := VBoxContainer.new()
    layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
    layout.add_theme_constant_override("separation", 18)
    margin.add_child(layout)

    var header := PanelContainer.new()
    header.custom_minimum_size = Vector2(0, 170)
    header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_theme_stylebox_override("panel", _panel_style)
    layout.add_child(header)

    var header_art := TextureRect.new()
    header_art.set_anchors_preset(Control.PRESET_FULL_RECT)
    header_art.texture = _load_texture(HEADER_TEXTURE_PATH)
    header_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    header_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    header_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    header.add_child(header_art)

    var header_margin := MarginContainer.new()
    header_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    header_margin.add_theme_constant_override("margin_left", 30)
    header_margin.add_theme_constant_override("margin_top", 26)
    header_margin.add_theme_constant_override("margin_right", 30)
    header_margin.add_theme_constant_override("margin_bottom", 22)
    header.add_child(header_margin)

    var header_vbox := VBoxContainer.new()
    header_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
    header_vbox.add_theme_constant_override("separation", 6)
    header_margin.add_child(header_vbox)

    var title := Label.new()
    title.text = "Deck & Progress"
    _style_label(title, 34, Color(0.96, 0.88, 0.73, 1))
    header_vbox.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Saved threat, wins and deck live here. Reward choices update this save."
    _style_label(subtitle, 18, Color(0.9, 0.82, 0.67, 0.95), true)
    header_vbox.add_child(subtitle)

    var body := HBoxContainer.new()
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 18)
    layout.add_child(body)

    var stats_panel := PanelContainer.new()
    stats_panel.custom_minimum_size = Vector2(360, 0)
    stats_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stats_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stats_panel.add_theme_stylebox_override("panel", _panel_style)
    body.add_child(stats_panel)

    var stats_margin := MarginContainer.new()
    stats_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    stats_margin.add_theme_constant_override("margin_left", 18)
    stats_margin.add_theme_constant_override("margin_top", 18)
    stats_margin.add_theme_constant_override("margin_right", 18)
    stats_margin.add_theme_constant_override("margin_bottom", 18)
    stats_panel.add_child(stats_margin)

    var stats_vbox := VBoxContainer.new()
    stats_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stats_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stats_vbox.add_theme_constant_override("separation", 10)
    stats_margin.add_child(stats_vbox)

    var stats_title := Label.new()
    stats_title.text = "Progress"
    _style_label(stats_title, 24, Color(0.96, 0.88, 0.73, 1))
    stats_vbox.add_child(stats_title)

    _status_label = Label.new()
    _style_label(_status_label, 15, Color(0.88, 0.79, 0.64, 0.95), true)
    _status_label.text = "Loading..."
    stats_vbox.add_child(_status_label)

    _threat_label = _make_stat_label(stats_vbox, "Threat")
    _win_label = _make_stat_label(stats_vbox, "Wins")
    _loss_label = _make_stat_label(stats_vbox, "Losses")
    _deck_total_label = _make_stat_label(stats_vbox, "Deck size")
    _run_label = _make_stat_label(stats_vbox, "Run")

    var reset_tip := Label.new()
    reset_tip.text = "Reset restores the starter deck and clears threat/wins/losses."
    _style_label(reset_tip, 14, Color(0.82, 0.73, 0.58, 0.92), true)
    stats_vbox.add_child(reset_tip)

    var deck_panel := PanelContainer.new()
    deck_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    deck_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    deck_panel.add_theme_stylebox_override("panel", _panel_style)
    body.add_child(deck_panel)

    var deck_margin := MarginContainer.new()
    deck_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    deck_margin.add_theme_constant_override("margin_left", 18)
    deck_margin.add_theme_constant_override("margin_top", 18)
    deck_margin.add_theme_constant_override("margin_right", 18)
    deck_margin.add_theme_constant_override("margin_bottom", 18)
    deck_panel.add_child(deck_margin)

    var deck_vbox := VBoxContainer.new()
    deck_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    deck_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
    deck_vbox.add_theme_constant_override("separation", 10)
    deck_margin.add_child(deck_vbox)

    var deck_title := Label.new()
    deck_title.text = "Deck"
    _style_label(deck_title, 24, Color(0.96, 0.88, 0.73, 1))
    deck_vbox.add_child(deck_title)

    var deck_note := Label.new()
    deck_note.text = "Current saved deck composition."
    _style_label(deck_note, 15, Color(0.88, 0.79, 0.64, 0.95), true)
    deck_vbox.add_child(deck_note)

    var scroll := ScrollContainer.new()
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    deck_vbox.add_child(scroll)

    _deck_list = VBoxContainer.new()
    _deck_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _deck_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _deck_list.add_theme_constant_override("separation", 8)
    scroll.add_child(_deck_list)

    var button_row := HBoxContainer.new()
    button_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button_row.add_theme_constant_override("separation", 12)
    layout.add_child(button_row)

    _reset_button = Button.new()
    _reset_button.text = "Reset Progress"
    _reset_button.custom_minimum_size = Vector2(0, 52)
    _reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _reset_button.add_theme_font_size_override("font_size", 18)
    _reset_button.add_theme_color_override("font_color", Color(0.98, 0.9, 0.87, 1))
    _reset_button.add_theme_color_override("font_hover_color", Color(1, 0.94, 0.9, 1))
    _reset_button.add_theme_color_override("font_pressed_color", Color(0.98, 0.9, 0.87, 1))
    _reset_button.add_theme_stylebox_override("normal", _reset_button_normal_style)
    _reset_button.add_theme_stylebox_override("hover", _reset_button_hover_style)
    _reset_button.add_theme_stylebox_override("pressed", _reset_button_pressed_style)
    _reset_button.pressed.connect(_reset_progress)
    button_row.add_child(_reset_button)

    var back_button := Button.new()
    back_button.text = "Back to Encounters"
    back_button.custom_minimum_size = Vector2(0, 52)
    back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    back_button.add_theme_font_size_override("font_size", 18)
    back_button.add_theme_color_override("font_color", Color(0.13, 0.09, 0.04, 1))
    back_button.add_theme_color_override("font_hover_color", Color(0.1, 0.07, 0.03, 1))
    back_button.add_theme_color_override("font_pressed_color", Color(0.13, 0.09, 0.04, 1))
    back_button.add_theme_stylebox_override("normal", _button_normal_style)
    back_button.add_theme_stylebox_override("hover", _button_hover_style)
    back_button.add_theme_stylebox_override("pressed", _button_pressed_style)
    back_button.pressed.connect(_return_to_selector)
    button_row.add_child(back_button)


func _load_state() -> void:
    _card_library = _load_resources_by_id("res://data/cards")
    _progression_state = _progression_system.load_state()


func _refresh_ui() -> void:
    _threat_label.text = "Threat: %s (%s)" % [
        _progression_system.get_threat_level(_progression_state),
        _progression_system.get_threat_label(_progression_system.get_threat_level(_progression_state)),
    ]
    _win_label.text = "Wins: %s" % _progression_system.get_win_count(_progression_state)
    _loss_label.text = "Losses: %s" % _progression_system.get_loss_count(_progression_state)

    var deck_card_ids: Array[StringName] = _progression_system.get_player_deck_card_ids(_progression_state)
    _deck_total_label.text = "Deck size: %s" % deck_card_ids.size()
    _refresh_run_label()
    _refresh_deck_list(deck_card_ids)


func _refresh_run_label() -> void:
    var run_session = _get_run_session()
    if run_session != null and run_session.is_active():
        var route_summary: String = run_session.get_run_roster_summary()
        var progress_text: String = run_session.get_run_progress_text()
        if route_summary.is_empty():
            _run_label.text = "Run: %s" % progress_text
        elif progress_text.is_empty():
            _run_label.text = "Run: %s" % route_summary
        else:
            _run_label.text = "Run: %s | %s" % [progress_text, route_summary]
        return

    _run_label.text = "Run: none active"


func _refresh_deck_list(deck_card_ids: Array[StringName]) -> void:
    for child in _deck_list.get_children():
        child.queue_free()

    if deck_card_ids.is_empty():
        var empty_label := Label.new()
        _style_label(empty_label, 15, Color(0.88, 0.79, 0.64, 0.95), true)
        empty_label.text = "Deck is empty."
        _deck_list.add_child(empty_label)
        return

    var card_counts: Dictionary = {}
    var card_order: Array[StringName] = []
    for card_id in deck_card_ids:
        if not card_counts.has(card_id):
            card_order.append(card_id)
            card_counts[card_id] = 0
        card_counts[card_id] = int(card_counts.get(card_id, 0)) + 1

    for card_id in card_order:
        var card_definition: CardDefinition = _card_library.get(card_id) as CardDefinition
        var card_name := String(card_id) if card_definition == null or card_definition.display_name.is_empty() else card_definition.display_name
        var card_line := Label.new()
        _style_label(card_line, 16, Color(0.95, 0.88, 0.74, 1), true)
        card_line.text = "%sx %s" % [card_counts.get(card_id, 0), card_name]
        _deck_list.add_child(card_line)


func _reset_progress() -> void:
    var run_session = _get_run_session()
    if run_session != null and run_session.is_active():
        run_session.end_run()
    _progression_state = _progression_system.reset_state()
    _refresh_ui()


func _return_to_selector() -> void:
    var packed_scene := EncounterSelectScene as PackedScene
    if packed_scene == null:
        push_error("Could not load encounter_select.tscn")
        return

    var select_scene: Control = packed_scene.instantiate() as Control
    var tree := get_tree()
    tree.root.add_child(select_scene)
    tree.current_scene = select_scene
    queue_free()


func _load_resources_by_id(directory_path: String) -> Dictionary:
    var library: Dictionary = {}
    var directory := DirAccess.open(directory_path)
    if directory == null:
        push_warning("Could not open %s." % directory_path)
        return library

    for file_name in directory.get_files():
        if not file_name.ends_with(".tres") and not file_name.ends_with(".res"):
            continue
        var resource_path := "%s/%s" % [directory_path, file_name]
        var resource := load(resource_path)
        if resource == null:
            continue
        var resource_id: Variant = resource.get("id")
        if resource_id == null or resource_id == StringName():
            continue
        library[resource_id] = resource

    return library


func _get_run_session():
    return get_node("/root/RunSession")


func _make_stat_label(parent: VBoxContainer, title_text: String) -> Label:
    var label := Label.new()
    _style_label(label, 16, Color(0.88, 0.79, 0.64, 0.95), true)
    label.text = "%s: -" % title_text
    parent.add_child(label)
    return label


func _style_label(label: Label, font_size: int, font_color: Color, should_wrap: bool = false) -> void:
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", font_color)
    if should_wrap:
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _make_style(bg_color: Color, border_color: Color, border_width: int, radius: int, shadow_size: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg_color
    style.border_width_left = border_width
    style.border_width_top = border_width
    style.border_width_right = border_width
    style.border_width_bottom = border_width
    style.border_color = border_color
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_right = radius
    style.corner_radius_bottom_left = radius
    style.shadow_color = Color(0, 0, 0, 0.3)
    style.shadow_size = shadow_size
    return style


func _load_texture(resource_path: String) -> Texture2D:
    if resource_path.is_empty():
        return null
    var texture := load(resource_path) as Texture2D
    if texture == null:
        push_warning("Could not load texture from %s." % resource_path)
        return null
    return texture
