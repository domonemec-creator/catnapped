class_name EncounterSelectMenu
extends Control

const BATTLE_SCENE_PATH := "res://scenes/card_game/battle_scene.tscn"
const PROGRESSION_SCREEN_PATH := "res://scenes/card_game/progression_screen.tscn"
const ENCOUNTER_IDS: Array[StringName] = [&"smug_tabby", &"ragclaw_brawler", &"harbor_warden", &"lantern_striker", &"fog_seer", &"bilge_king"]
const HEADER_TEXTURE_PATH := "res://assets/card_game/ui/header_panel_drapes.png"
const CardArtCache = preload("res://scripts/card_game/ui/card_art_cache.gd")
const RunSessionScript = preload("res://scripts/card_game/systems/run_session.gd")

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
        # Výchozí výběr: nejvyšší odemčený soupeř tréninku.
        var cleared := _progression_system.get_training_cleared(_progression_system.load_state())
        var order := ProgressionSystem.TRAINING_ORDER
        var default_id: StringName = order[mini(cleared, order.size() - 1)]
        _select_encounter(default_id if _get_encounter_by_id(default_id) != null else _encounters[0].id)


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
    # Interiér krčmy (art majitele) ztlumený pod celým menu.
    var backdrop := TextureRect.new()
    backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
    backdrop.texture = load("res://assets/card_game/ui/tavern_backdrop.jpg")
    backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    backdrop.modulate = Color(0.38, 0.33, 0.3, 1)
    backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(backdrop)

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
    title.text = "Catnapped!"
    _style_label(title, 48, Color(0.98, 0.84, 0.5, 1))
    var title_font := FontVariation.new()
    title_font.base_font = load("res://assets/fonts/Cinzel-Variable.ttf")
    title_font.variation_opentype = {2003265652: 700}
    title.add_theme_font_override("font", title_font)
    title.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.02, 1))
    title.add_theme_constant_override("outline_size", 6)
    header_vbox.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Kočičí karetní souboje v přístavní krčmě. Vyber prvního soupeře a spusť run."
    _style_label(subtitle, 18, Color(0.9, 0.82, 0.67, 0.95), true)
    header_vbox.add_child(subtitle)

    _run_button = Button.new()
    _run_button.text = "Spustit run"
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
    _run_note_label.text = "Run začne od vybraného soupeře a projde všechny soupeře."
    header_vbox.add_child(_run_note_label)

    _progress_button = Button.new()
    _progress_button.text = "Balík a postup"
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
    var secondary_row := HBoxContainer.new()
    secondary_row.add_theme_constant_override("separation", 12)
    header_vbox.add_child(secondary_row)
    secondary_row.add_child(_progress_button)

    # Nastavení hlasitosti + titulky (licence CC BY vyžaduje uvedení autorů).
    var settings_button := _progress_button.duplicate() as Button
    settings_button.text = "Nastavení a titulky"
    settings_button.size_flags_horizontal = Control.SIZE_FILL
    settings_button.custom_minimum_size = Vector2(260, 48)
    settings_button.pressed.connect(_open_settings)
    secondary_row.add_child(settings_button)

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
    list_title.text = "Soupeři"
    _style_label(list_title, 24, Color(0.96, 0.88, 0.73, 1))
    list_vbox.add_child(list_title)

    var list_note := Label.new()
    list_note.text = "Vyber jednoho soupeře a spusť souboj."
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
    _start_button.text = "Jen jeden souboj (trénink)"
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
    # Seznam v pořadí runu (od nejlehčího), s číslem a portrétem.
    var roster: Array = RunSessionScript.DEFAULT_RUN_ROSTER
    var ordered := _encounters.duplicate()
    ordered.sort_custom(func(a, b) -> bool:
        var ia := roster.find(a.id)
        var ib := roster.find(b.id)
        return (ia if ia >= 0 else 99) < (ib if ib >= 0 else 99)
    )
    var progress_state := _progression_system.load_state()
    for encounter: EncounterDefinition in ordered:
        var encounter_id := encounter.id
        if encounter_id == StringName():
            encounter_id = StringName(encounter.display_name.to_lower().replace(" ", "_"))
        var button := Button.new()
        button.name = "%sButton" % String(encounter_id)
        button.toggle_mode = true
        button.custom_minimum_size = Vector2(0, 96)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var order := roster.find(encounter.id)
        button.text = ("%s. " % (order + 1) if order >= 0 else "") + _build_encounter_button_text(encounter)
        if not _progression_system.is_training_unlocked(progress_state, encounter.id):
            button.text += "  (zamčeno)"
            button.modulate = Color(0.6, 0.6, 0.6, 1)
        button.tooltip_text = _build_encounter_tooltip(encounter)
        button.icon = CardArtCache.get_cropped_aspect(encounter.portrait_path, 1.45)
        button.expand_icon = true
        button.add_theme_constant_override("icon_max_width", 150)
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.add_theme_constant_override("h_separation", 16)
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
    _selected_npc.text = "Pořadí v runu: %s. soupeř" % (RunSessionScript.DEFAULT_RUN_ROSTER.find(_selected_encounter.id) + 1)
    _selected_summary.text = "%s. S každou prohrou proti němu roste hrozba a jeho balík sílí." % str(ENCOUNTER_STYLES.get(_selected_encounter.id, "Soupeř"))
    _selected_stats.text = "Startovní životy v tréninku: %s" % _training_life(_selected_encounter)
    if _selected_encounter.table_power_id != StringName():
        _selected_stats.text += "\nSíla stolu: %s" % _get_table_power_display_name(_selected_encounter.table_power_id)
    # Výřez podle poměru stran rámečku (cca 2.7:1): u portrétů na výšku horní pás s hlavou, ne trup.
    var portrait_aspect := _selected_portrait.size.x / _selected_portrait.custom_minimum_size.y if _selected_portrait.size.x > 0.0 else 2.7
    var portrait_full := CardArtCache.get_full(_selected_encounter.portrait_path)
    var portrait_top := 0.1 if portrait_full != null and portrait_full.get_height() > portrait_full.get_width() else 0.03
    _selected_portrait.texture = CardArtCache.get_cropped_aspect(_selected_encounter.portrait_path, portrait_aspect, portrait_top)
    var progress_state := _progression_system.load_state()
    var bonus := _progression_system.get_training_threat_bonus(_selected_encounter.id)
    var unlocked := _progression_system.is_training_unlocked(progress_state, _selected_encounter.id)
    var ladder_index := ProgressionSystem.TRAINING_ORDER.find(_selected_encounter.id)
    _run_note_label.text = "Run má %s soubojů. První soupeř: %s." % [RunSessionScript.DEFAULT_RUN_ROSTER.size(), _selected_encounter.display_name]
    _run_button.disabled = false
    _start_button.disabled = not unlocked
    if not unlocked and ladder_index > 0:
        var previous := _get_encounter_by_id(ProgressionSystem.TRAINING_ORDER[ladder_index - 1])
        _status_label.text = "Zamčeno. V tréninku nejdřív poraz: %s." % (previous.display_name if previous != null else "předchozího soupeře")
    elif bonus > 0:
        _status_label.text = "Trénink: %s. stupeň, soupeř má hrozbu +%s. Výhra odemkne dalšího." % [ladder_index + 1, bonus]
    else:
        _status_label.text = "Trénink: první stupeň. Výhra odemkne dalšího, silnějšího soupeře."


func _set_empty_state() -> void:
    _selected_encounter = null
    _selected_title.text = "Soupeři se nenačetli"
    _selected_npc.text = ""
    _selected_summary.text = "Zkontroluj `res://data/encounters`."
    _selected_stats.text = ""
    _selected_portrait.texture = null
    _status_label.text = "Výběr je prázdný, souboj nejde spustit."
    _run_note_label.text = "Dokud se soupeři nenačtou, run nejde spustit."
    _run_button.disabled = true
    _start_button.disabled = true


func _get_encounter_by_id(encounter_id: StringName) -> EncounterDefinition:
    for encounter in _encounters:
        if encounter.id == encounter_id:
            return encounter
    return null


# Styl soupeře pro hráče, který karetní hry nezná (místo technických údajů).
const ENCOUNTER_STYLES := {
    &"smug_tabby": "Učitel · drží obranu, dobrý na začátek",
    &"ragclaw_brawler": "Rváč · rychlé útoky hned od prvního kola, Kapsáři",
    &"lantern_striker": "Útočník · skoky do sousedních lajn, Lampářky",
    &"harbor_warden": "Kapitán · tvrdá obrana, velké kočky a Harpunář",
    &"fog_seer": "Věštkyně · zranění z mlhy, Lampářky a Lodní hlídky",
    &"bilge_king": "Finální boss · hodování na padlých, Pašeráci",
}


func _build_encounter_button_text(encounter: EncounterDefinition) -> String:
    var summary := "%s | %s životů" % [str(ENCOUNTER_STYLES.get(encounter.id, "Soupeř")), _training_life(encounter)]
    return "%s\n%s" % [encounter.display_name, summary]


# Životy soupeře podle stupně tréninku (D-022).
func _training_life(encounter: EncounterDefinition) -> int:
    return encounter.starting_life + ProgressionSystem.get_training_life_bonus(maxi(0, ProgressionSystem.TRAINING_ORDER.find(encounter.id)))


func _build_encounter_tooltip(encounter: EncounterDefinition) -> String:
    return "Síla stolu: %s\nStartovní životy: %s\nBalík soupeře se mění podle hrozby." % [
        _get_table_power_display_name(encounter.table_power_id),
        encounter.starting_life,
    ]


func _get_table_power_display_name(table_power_id: StringName) -> String:
    if table_power_id == StringName():
        return "Bez Síly stolu"

    var resource_path := "res://data/table_powers/%s.tres" % String(table_power_id)
    var power_definition := load(resource_path) as TablePowerDefinition
    if power_definition == null or power_definition.display_name.is_empty():
        return String(table_power_id)
    return power_definition.display_name


func _start_battle() -> void:
    if _selected_encounter == null and not _encounters.is_empty():
        _select_encounter(_encounters[0].id)
    if _selected_encounter == null:
        return

    _get_run_session().end_run()
    _open_battle_scene(_selected_encounter.id)


func _open_settings() -> void:
    if get_node_or_null("SettingsOverlay") != null:
        return
    var overlay: Control = load("res://scripts/card_game/ui/settings_overlay.gd").new()
    overlay.name = "SettingsOverlay"
    add_child(overlay)


func _start_run() -> void:
    if _selected_encounter == null and not _encounters.is_empty():
        _select_encounter(_encounters[0].id)
    if _selected_encounter == null:
        return

    var progression_state: Dictionary = _progression_system.load_state()
    var starting_deck_card_ids: Array[StringName] = _progression_system.get_player_deck_card_ids(progression_state)
    _get_run_session().start_new_run(_selected_encounter.id, RunSessionScript.DEFAULT_RUN_ROSTER.size(), starting_deck_card_ids)
    _open_battle_scene()


func _open_progression_screen() -> void:
    call_deferred("_deferred_open_progression_screen")


func _deferred_open_progression_screen() -> void:
    var progression_scene_resource := load(PROGRESSION_SCREEN_PATH) as PackedScene
    if progression_scene_resource == null:
        push_error("Could not load progression_screen.tscn")
        return

    var progression_scene := progression_scene_resource.instantiate() as Control
    if progression_scene == null:
        push_error("Could not instantiate progression_screen.tscn")
        return

    var tree := get_tree()
    tree.root.add_child(progression_scene)
    tree.current_scene = progression_scene
    queue_free()


func _open_battle_scene(encounter_id: StringName = StringName()) -> void:
    var battle_scene_resource := load(BATTLE_SCENE_PATH) as PackedScene
    if battle_scene_resource == null:
        push_error("Could not load battle_scene.tscn")
        return

    var battle_scene := battle_scene_resource.instantiate()
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
