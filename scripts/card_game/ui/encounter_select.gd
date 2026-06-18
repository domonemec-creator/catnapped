class_name EncounterSelectMenu
extends Control

const BattleScene: PackedScene = preload("res://scenes/card_game/battle_scene.tscn")
const ProgressionScreen: PackedScene = preload("res://scenes/card_game/progression_screen.tscn")
const ENCOUNTER_IDS: Array[StringName] = [&"smug_tabby", &"ragclaw_brawler", &"harbor_warden", &"lantern_striker"]
const HEADER_TEXTURE_PATH := "res://assets/card_game/ui/header_panel_drapes.png"

var _panel_style: StyleBoxFlat
var _button_normal_style: StyleBoxFlat
var _button_hover_style: StyleBoxFlat
var _button_pressed_style: StyleBoxFlat
var _start_button_normal_style: StyleBoxFlat
var _start_button_hover_style: StyleBoxFlat
var _start_button_pressed_style: StyleBoxFlat
var _progress_button_normal_style: StyleBoxFlat
var _progress_button_hover_style: StyleBoxFlat
var _progress_button_pressed_style: StyleBoxFlat

var _encounters: Array[EncounterDefinition] = []
var _encounter_buttons: Dictionary = {}
var _selected_encounter: EncounterDefinition
var _progression_system := ProgressionSystem.new()

var _encounter_list: VBoxContainer
var _selected_portrait: TextureRect
var _selected_title: Label
var _selected_npc: Label
var _selected_summary: Label
var _selected_stats: Label
var _status_label: Label
var _run_button: Button
var _run_note_label: Label
var _progress_button: Button
var _start_button: Button


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _build_styles()
    _build_ui()
    _load_encounters()
    _populate_encounter_list()

    if _encounters.is_empty():
        _set_empty_state()
    else:
        _select_encounter(_encounters[0].id)


func _build_styles() -> void:
    _panel_style = _make_style(Color(0.13, 0.1, 0.08, 0.96), Color(0.6, 0.46, 0.24, 0.92), 2, 18, 8)
    _button_normal_style = _make_style(Color(0.24, 0.19, 0.13, 1), Color(0.6, 0.46, 0.24, 0.92), 2, 12, 4)
    _button_hover_style = _make_style(Color(0.31, 0.24, 0.16, 1), Color(0.77, 0.59, 0.31, 0.98), 2, 12, 4)
    _button_pressed_style = _make_style(Color(0.42, 0.3, 0.17, 1), Color(0.9, 0.69, 0.36, 1), 2, 12, 4)
    _start_button_normal_style = _make_style(Color(0.82, 0.56, 0.2, 1), Color(0.93, 0.75, 0.41, 1), 2, 12, 4)
    _start_button_hover_style = _make_style(Color(0.92, 0.66, 0.28, 1), Color(0.98, 0.82, 0.5, 1), 2, 12, 4)
    _start_button_pressed_style = _make_style(Color(0.82, 0.56, 0.2, 1), Color(0.93, 0.75, 0.41, 1), 2, 12, 4)
    _progress_button_normal_style = _make_style(Color(0.2, 0.16, 0.11, 1), Color(0.62, 0.48, 0.26, 0.95), 2, 12, 4)
    _progress_button_hover_style = _make_style(Color(0.27, 0.2, 0.13, 1), Color(0.8, 0.62, 0.34, 1), 2, 12, 4)
    _progress_button_pressed_style = _make_style(Color(0.34, 0.24, 0.15, 1), Color(0.9, 0.7, 0.38, 1), 2, 12, 4)


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
    header.custom_minimum_size = Vector2(0, 180)
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
    title.text = "Choose Encounter"
    _style_label(title, 34, Color(0.96, 0.88, 0.73, 1))
    header_vbox.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Pick the opponent before the battle starts. The save and threat progress stay intact."
    _style_label(subtitle, 18, Color(0.9, 0.82, 0.67, 0.95), true)
    header_vbox.add_child(subtitle)

    _run_button = Button.new()
    _run_button.text = "Start Run"
    _run_button.custom_minimum_size = Vector2(0, 56)
    _run_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _run_button.add_theme_font_size_override("font_size", 21)
    _run_button.add_theme_color_override("font_color", Color(0.13, 0.09, 0.04, 1))
    _run_button.add_theme_color_override("font_hover_color", Color(0.1, 0.07, 0.03, 1))
    _run_button.add_theme_color_override("font_pressed_color", Color(0.13, 0.09, 0.04, 1))
    _run_button.add_theme_stylebox_override("normal", _start_button_normal_style)
    _run_button.add_theme_stylebox_override("hover", _start_button_hover_style)
    _run_button.add_theme_stylebox_override("pressed", _start_button_pressed_style)
    _run_button.pressed.connect(_start_run)
    header_vbox.add_child(_run_button)

    _run_note_label = Label.new()
    _style_label(_run_note_label, 15, Color(0.88, 0.79, 0.64, 0.95), true)
    _run_note_label.text = "Run mode starts from the selected encounter and alternates through the roster for 5 fights."
    header_vbox.add_child(_run_note_label)

    _progress_button = Button.new()
    _progress_button.text = "Deck & Progress"
    _progress_button.custom_minimum_size = Vector2(0, 48)
    _progress_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _progress_button.add_theme_font_size_override("font_size", 18)
    _progress_button.add_theme_color_override("font_color", Color(0.95, 0.86, 0.7, 1))
    _progress_button.add_theme_color_override("font_hover_color", Color(0.98, 0.9, 0.75, 1))
    _progress_button.add_theme_color_override("font_pressed_color", Color(0.95, 0.86, 0.7, 1))
    _progress_button.add_theme_stylebox_override("normal", _progress_button_normal_style)
    _progress_button.add_theme_stylebox_override("hover", _progress_button_hover_style)
    _progress_button.add_theme_stylebox_override("pressed", _progress_button_pressed_style)
    _progress_button.pressed.connect(_open_progression_screen)
    header_vbox.add_child(_progress_button)

    var body := HBoxContainer.new()
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 18)
    layout.add_child(body)

    var list_panel := PanelContainer.new()
    list_panel.custom_minimum_size = Vector2(430, 0)
    list_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    list_panel.add_theme_stylebox_override("panel", _panel_style)
    body.add_child(list_panel)

    var list_margin := MarginContainer.new()
    list_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    list_margin.add_theme_constant_override("margin_left", 18)
    list_margin.add_theme_constant_override("margin_top", 18)
    list_margin.add_theme_constant_override("margin_right", 18)
    list_margin.add_theme_constant_override("margin_bottom", 18)
    list_panel.add_child(list_margin)

    var list_vbox := VBoxContainer.new()
    list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
    list_vbox.add_theme_constant_override("separation", 10)
    list_margin.add_child(list_vbox)

    var list_title := Label.new()
    list_title.text = "Encounter List"
    _style_label(list_title, 24, Color(0.96, 0.88, 0.73, 1))
    list_vbox.add_child(list_title)

    var list_note := Label.new()
    list_note.text = "Select one entry, then launch the fight."
    _style_label(list_note, 15, Color(0.88, 0.79, 0.64, 0.95), true)
    list_vbox.add_child(list_note)

    var scroll := ScrollContainer.new()
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    list_vbox.add_child(scroll)

    _encounter_list = VBoxContainer.new()
    _encounter_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _encounter_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _encounter_list.add_theme_constant_override("separation", 10)
    scroll.add_child(_encounter_list)

    var details_panel := PanelContainer.new()
    details_panel.custom_minimum_size = Vector2(620, 0)
    details_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    details_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    details_panel.add_theme_stylebox_override("panel", _panel_style)
    body.add_child(details_panel)

    var details_margin := MarginContainer.new()
    details_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    details_margin.add_theme_constant_override("margin_left", 18)
    details_margin.add_theme_constant_override("margin_top", 18)
    details_margin.add_theme_constant_override("margin_right", 18)
    details_margin.add_theme_constant_override("margin_bottom", 18)
    details_panel.add_child(details_margin)

    var details_vbox := VBoxContainer.new()
    details_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    details_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
    details_vbox.add_theme_constant_override("separation", 10)
    details_margin.add_child(details_vbox)

    _selected_portrait = TextureRect.new()
    _selected_portrait.custom_minimum_size = Vector2(0, 260)
    _selected_portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _selected_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _selected_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    _selected_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
    details_vbox.add_child(_selected_portrait)

    _selected_title = Label.new()
    _style_label(_selected_title, 28, Color(0.97, 0.88, 0.72, 1))
    details_vbox.add_child(_selected_title)

    _selected_npc = Label.new()
    _style_label(_selected_npc, 18, Color(0.9, 0.82, 0.67, 1), true)
    details_vbox.add_child(_selected_npc)

    _selected_summary = Label.new()
    _style_label(_selected_summary, 16, Color(0.88, 0.79, 0.64, 0.95), true)
    details_vbox.add_child(_selected_summary)

    _selected_stats = Label.new()
    _style_label(_selected_stats, 16, Color(0.88, 0.79, 0.64, 0.95), true)
    details_vbox.add_child(_selected_stats)

    _status_label = Label.new()
    _style_label(_status_label, 15, Color(0.75, 0.68, 0.55, 0.92), true)
    details_vbox.add_child(_status_label)

    _start_button = Button.new()
    _start_button.text = "Practice Battle"
    _start_button.custom_minimum_size = Vector2(0, 56)
    _start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _start_button.add_theme_font_size_override("font_size", 21)
    _start_button.add_theme_color_override("font_color", Color(0.13, 0.09, 0.04, 1))
    _start_button.add_theme_color_override("font_hover_color", Color(0.1, 0.07, 0.03, 1))
    _start_button.add_theme_color_override("font_pressed_color", Color(0.13, 0.09, 0.04, 1))
    _start_button.add_theme_stylebox_override("normal", _start_button_normal_style)
    _start_button.add_theme_stylebox_override("hover", _start_button_hover_style)
    _start_button.add_theme_stylebox_override("pressed", _start_button_pressed_style)
    _start_button.pressed.connect(_start_battle)
    details_vbox.add_child(_start_button)


func _load_encounters() -> void:
    _encounters.clear()
    for encounter_id in ENCOUNTER_IDS:
        var encounter_path := "res://data/encounters/%s.tres" % String(encounter_id)
        var encounter := load(encounter_path) as EncounterDefinition
        if encounter == null:
            push_warning("Could not load encounter %s." % encounter_path)
            continue
        _encounters.append(encounter)


func _populate_encounter_list() -> void:
    for child in _encounter_list.get_children():
        child.queue_free()

    _encounter_buttons.clear()
    for encounter in _encounters:
        var encounter_id := encounter.id
        if encounter_id == StringName():
            encounter_id = StringName(encounter.display_name.to_lower().replace(" ", "_"))
        var button := Button.new()
        button.name = "%sButton" % String(encounter_id)
        button.toggle_mode = true
        button.custom_minimum_size = Vector2(0, 104)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.text = _build_encounter_button_text(encounter)
        button.tooltip_text = _build_encounter_tooltip(encounter)
        button.add_theme_font_size_override("font_size", 18)
        button.add_theme_color_override("font_color", Color(0.96, 0.88, 0.73, 1))
        button.add_theme_color_override("font_hover_color", Color(0.99, 0.92, 0.8, 1))
        button.add_theme_color_override("font_pressed_color", Color(1, 0.95, 0.85, 1))
        button.add_theme_stylebox_override("normal", _button_normal_style)
        button.add_theme_stylebox_override("hover", _button_hover_style)
        button.add_theme_stylebox_override("pressed", _button_pressed_style)
        button.pressed.connect(_select_encounter.bind(encounter_id))
        _encounter_list.add_child(button)
        _encounter_buttons[encounter_id] = button


func _select_encounter(encounter_id: StringName) -> void:
    var encounter := _get_encounter_by_id(encounter_id)
    if encounter == null:
        return

    _selected_encounter = encounter
    for key in _encounter_buttons.keys():
        var button := _encounter_buttons[key] as Button
        if button == null:
            continue
        button.button_pressed = key == encounter_id

    _refresh_details()


func _refresh_details() -> void:
    if _selected_encounter == null:
        return

    _selected_title.text = _selected_encounter.display_name
    _selected_npc.text = "NPC: %s" % _selected_encounter.npc_name
    _selected_summary.text = "Deck: %s" % _selected_encounter.deck_id
    _selected_stats.text = "Table power: %s\nStarting life: %s" % [
        _selected_encounter.table_power_id,
        _selected_encounter.starting_life,
    ]
    _selected_portrait.texture = _load_texture(_selected_encounter.portrait_path)
    _status_label.text = "This only picks the next practice battle. Progress stays in the save."
    _run_note_label.text = "Run mode starts from %s and chains 5 fights." % _selected_encounter.display_name
    _run_button.disabled = false
    _start_button.disabled = false


func _set_empty_state() -> void:
    _selected_encounter = null
    _selected_title.text = "No encounters loaded"
    _selected_npc.text = ""
    _selected_summary.text = "Check `res://data/encounters`."
    _selected_stats.text = ""
    _selected_portrait.texture = null
    _status_label.text = "Selector is empty, so the battle cannot start."
    _run_note_label.text = "No run can start until encounters load."
    _run_button.disabled = true
    _start_button.disabled = true


func _get_encounter_by_id(encounter_id: StringName) -> EncounterDefinition:
    for encounter in _encounters:
        if encounter.id == encounter_id:
            return encounter
    return null


func _build_encounter_button_text(encounter: EncounterDefinition) -> String:
    var summary := "Deck %s | Power %s" % [encounter.deck_id, encounter.table_power_id]
    return "%s\n%s" % [encounter.display_name, summary]


func _build_encounter_tooltip(encounter: EncounterDefinition) -> String:
    return "Deck: %s\nTable power: %s\nStarting life: %s" % [
        encounter.deck_id,
        encounter.table_power_id,
        encounter.starting_life,
    ]


func _start_battle() -> void:
    if _selected_encounter == null and not _encounters.is_empty():
        _select_encounter(_encounters[0].id)
    if _selected_encounter == null:
        return

    _get_run_session().end_run()
    _open_battle_scene(_selected_encounter.id)


func _start_run() -> void:
    if _selected_encounter == null and not _encounters.is_empty():
        _select_encounter(_encounters[0].id)
    if _selected_encounter == null:
        return

    var progression_state: Dictionary = _progression_system.load_state()
    var starting_deck_card_ids: Array[StringName] = _progression_system.get_player_deck_card_ids(progression_state)
    _get_run_session().start_new_run(_selected_encounter.id, 5, starting_deck_card_ids)
    _open_battle_scene()


func _open_progression_screen() -> void:
    var progression_scene: Control = ProgressionScreen.instantiate() as Control
    var tree := get_tree()
    tree.root.add_child(progression_scene)
    tree.current_scene = progression_scene
    queue_free()


func _open_battle_scene(encounter_id: StringName = StringName()) -> void:
    var battle_scene := BattleScene.instantiate()
    if encounter_id != StringName():
        battle_scene.startup_encounter_id = encounter_id
    var tree := get_tree()
    tree.root.add_child(battle_scene)
    tree.current_scene = battle_scene
    queue_free()


func _load_texture(resource_path: String) -> Texture2D:
    if resource_path.is_empty():
        return null
    var texture := load(resource_path) as Texture2D
    if texture == null:
        push_warning("Could not load texture from %s." % resource_path)
        return null
    return texture


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


func _get_run_session():
    return get_node("/root/RunSession")
