class_name ProgressionScreenMenu
extends Control

const ENCOUNTER_SELECT_SCENE_PATH := "res://scenes/card_game/encounter_select.tscn"
const RESET_TEXT := "Smazat postup"
const CardArtCache = preload("res://scripts/card_game/ui/card_art_cache.gd")
const CardGameConstants = preload("res://scripts/card_game/data/card_game_constants.gd")
const PREVIEW_SCENE := preload("res://scenes/card_game/selected_card_preview.tscn")
const PREVIEW_SIZE := Vector2(258, 404)

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
var _collection_list: VBoxContainer
var _deck_note: Label
var _deck_total_label: Label
var _threat_label: Label
var _win_label: Label
var _loss_label: Label
var _run_label: Label
var _status_label: Label
var _reset_button: Button
var _reset_armed := false
var _back_button: Button
var _hover_preview: Control  # velká karta u myši při najetí na řádek
var _pvp_mode := false  # true = balík pro hru ve dvou ze všech karet (E5)
var _deck_title: Label
var _mode_button: Button
var _fill_button: Button
# Filtr kolekce: -1 = vše; cena = koš 0–4 (≤1, 2, 3, 4, 5+), typ = CardGameConstants.CardType.
var _cost_filter := -1
var _type_filter := -1
var _filter_row: HFlowContainer
var _curve_row: HBoxContainer
var _type_summary: Label


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _build_styles()
    _build_ui()
    _build_hover_preview()
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
    header.custom_minimum_size = Vector2(0, 0)
    header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_theme_stylebox_override("panel", _panel_style)
    layout.add_child(header)


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
    title.text = "Balík a postup"
    _style_label(title, 34, Color(0.96, 0.88, 0.73, 1))
    header_vbox.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Tvůj balík, výhry a postup tréninkem. Odměny z výprav balík mění."
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
    stats_title.text = "Postup"
    _style_label(stats_title, 24, Color(0.96, 0.88, 0.73, 1))
    stats_vbox.add_child(stats_title)

    _status_label = Label.new()
    _style_label(_status_label, 15, Color(0.88, 0.79, 0.64, 0.95), true)
    _status_label.text = "Poraz soupeře v tréninku a odemkneš dalšího."
    stats_vbox.add_child(_status_label)

    # Statistiky v jednom řádku, ať zbyde místo na kolekci.
    var stats_flow := HFlowContainer.new()
    stats_flow.add_theme_constant_override("h_separation", 28)
    stats_vbox.add_child(stats_flow)
    _threat_label = _make_stat_label(stats_flow, "Trénink")
    _win_label = _make_stat_label(stats_flow, "Výhry")
    _loss_label = _make_stat_label(stats_flow, "Prohry")
    _deck_total_label = _make_stat_label(stats_flow, "Velikost balíku")
    _run_label = _make_stat_label(stats_flow, "Výprava")

    var reset_tip := Label.new()
    reset_tip.text = "Smazání postupu vrátí startovní balík a zamkne trénink. Nejde vrátit zpět."
    _style_label(reset_tip, 14, Color(0.82, 0.73, 0.58, 0.92), true)
    stats_vbox.add_child(reset_tip)

    # Kolekce (D2): karty, které smíš dát do balíku. Tlačítko + přidá kopii.
    var collection_title := Label.new()
    collection_title.text = "Kolekce"
    _style_label(collection_title, 24, Color(0.96, 0.88, 0.73, 1))
    stats_vbox.add_child(collection_title)
    _filter_row = HFlowContainer.new()
    _filter_row.add_theme_constant_override("h_separation", 6)
    _filter_row.add_theme_constant_override("v_separation", 6)
    stats_vbox.add_child(_filter_row)

    var collection_scroll := ScrollContainer.new()
    collection_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    collection_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    collection_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    stats_vbox.add_child(collection_scroll)

    _collection_list = VBoxContainer.new()
    _collection_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _collection_list.add_theme_constant_override("separation", 6)
    collection_scroll.add_child(_collection_list)

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

    var title_row := HBoxContainer.new()
    title_row.add_theme_constant_override("separation", 12)
    deck_vbox.add_child(title_row)
    _deck_title = Label.new()
    _deck_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _style_label(_deck_title, 24, Color(0.96, 0.88, 0.73, 1))
    title_row.add_child(_deck_title)
    _mode_button = _make_small_button("", true, "Trénink a hra ve dvou mají každý svůj balík.")
    _mode_button.add_theme_font_size_override("font_size", 16)
    _mode_button.custom_minimum_size = Vector2(230, 40)
    _mode_button.pressed.connect(_toggle_pvp_mode)
    title_row.add_child(_mode_button)
    _fill_button = _make_small_button("Doplnit", true, "")
    _fill_button.add_theme_font_size_override("font_size", 16)
    _fill_button.custom_minimum_size = Vector2(110, 40)
    _fill_button.pressed.connect(_fill_deck)
    title_row.add_child(_fill_button)

    _deck_note = Label.new()
    _style_label(_deck_note, 15, Color(0.88, 0.79, 0.64, 0.95), true)
    deck_vbox.add_child(_deck_note)

    # Křivka ceny: kolik karet stojí ≤1, 2, 3, 4 a 5+ Tun.
    _curve_row = HBoxContainer.new()
    _curve_row.add_theme_constant_override("separation", 10)
    deck_vbox.add_child(_curve_row)
    _type_summary = Label.new()
    _style_label(_type_summary, 15, Color(0.88, 0.79, 0.64, 0.95), true)
    deck_vbox.add_child(_type_summary)

    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
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
    # Nevratná akce: malá, vlevo, daleko od Zpět a s potvrzením druhým klikem.
    _reset_button.text = RESET_TEXT
    _reset_button.custom_minimum_size = Vector2(220, 44)
    _reset_button.add_theme_font_size_override("font_size", 15)
    _reset_button.add_theme_color_override("font_color", Color(0.98, 0.9, 0.87, 1))
    _reset_button.add_theme_color_override("font_hover_color", Color(1, 0.94, 0.9, 1))
    _reset_button.add_theme_color_override("font_pressed_color", Color(0.98, 0.9, 0.87, 1))
    _reset_button.add_theme_stylebox_override("normal", _reset_button_normal_style)
    _reset_button.add_theme_stylebox_override("hover", _reset_button_hover_style)
    _reset_button.add_theme_stylebox_override("pressed", _reset_button_pressed_style)
    _reset_button.pressed.connect(_on_reset_pressed)
    button_row.add_child(_reset_button)

    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button_row.add_child(spacer)

    _back_button = Button.new()
    _back_button.text = "Zpět na výběr"
    _back_button.custom_minimum_size = Vector2(320, 56)
    _back_button.add_theme_font_size_override("font_size", 20)
    _back_button.add_theme_color_override("font_color", Color(0.96, 0.88, 0.73, 1))
    _back_button.add_theme_color_override("font_hover_color", Color(1, 0.94, 0.82, 1))
    _back_button.add_theme_color_override("font_pressed_color", Color(0.96, 0.88, 0.73, 1))
    _back_button.add_theme_stylebox_override("normal", _button_normal_style)
    _back_button.add_theme_stylebox_override("hover", _button_hover_style)
    _back_button.add_theme_stylebox_override("pressed", _button_pressed_style)
    _back_button.pressed.connect(_return_to_selector)
    button_row.add_child(_back_button)


func _load_state() -> void:
    _card_library = _load_resources_by_id("res://data/cards")
    _progression_state = _progression_system.load_state()


func _refresh_ui() -> void:
    # Hrozbu v UI nahradil žebříček tréninku (D-022); zůstává v tooltipu pro ladění.
    _threat_label.text = "Trénink: %s/%s poražených" % [
        _progression_system.get_training_cleared(_progression_state),
        ProgressionSystem.TRAINING_ORDER.size(),
    ]
    _threat_label.tooltip_text = "Hrozba %s" % _progression_system.get_threat_level(_progression_state)
    _win_label.text = "Výhry: %s" % _progression_system.get_win_count(_progression_state)
    _loss_label.text = "Prohry: %s" % _progression_system.get_loss_count(_progression_state)

    var deck_card_ids: Array[StringName] = _progression_system.get_deck_card_ids(_progression_state, _pvp_mode)
    var deck_max := ProgressionSystem.get_deck_max_size(_pvp_mode)
    var deck_problem := _progression_system.get_deck_problem(deck_card_ids, _pvp_mode)
    _deck_total_label.text = "Velikost balíku: %s/%s" % [deck_card_ids.size(), deck_max]
    _deck_total_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45) if not deck_problem.is_empty() else Color(0.96, 0.88, 0.73, 1))
    _fill_button.disabled = _is_deck_locked() or deck_card_ids.size() >= (ProgressionSystem.PVP_DECK_SIZE if _pvp_mode else ProgressionSystem.DECK_MIN_SIZE)
    _fill_button.tooltip_text = "Dorovná balík na %s karet podle křivky ceny." % (ProgressionSystem.PVP_DECK_SIZE if _pvp_mode else ProgressionSystem.DECK_MIN_SIZE)
    _deck_title.text = "Balík pro hru ve dvou" if _pvp_mode else "Balík pro trénink"
    _mode_button.text = "Přepnout na trénink" if _pvp_mode else "Přepnout na hru ve dvou"
    _refresh_run_label()
    var locked := _is_deck_locked()
    if locked:
        _deck_note.text = "Během výpravy balík upravit nejde (mění ho odměny)."
    elif _pvp_mode:
        _deck_note.text = "Ve hře ve dvou máš všechny karty. Přesně %s karet, nejvýš %s kopie. Změny se ukládají hned." % [
            ProgressionSystem.PVP_DECK_SIZE, ProgressionSystem.PVP_MAX_COPIES,
        ]
        if not deck_problem.is_empty():
            _deck_note.text += " " + deck_problem
    else:
        _deck_note.text = "%s až %s karet, nejvýš %s kopie stejné karty. Změny se ukládají hned." % [
            ProgressionSystem.DECK_MIN_SIZE, ProgressionSystem.DECK_MAX_SIZE, ProgressionSystem.MAX_COPIES,
        ]
    _refresh_curve(deck_card_ids)
    _refresh_filters()
    _refresh_deck_list(deck_card_ids)
    _refresh_collection_list(deck_card_ids, locked)


func _toggle_pvp_mode() -> void:
    _pvp_mode = not _pvp_mode
    _refresh_ui()


func _is_deck_locked() -> bool:
    if _pvp_mode:
        return false  # výprava mění jen tréninkový balík
    var run_session = _get_run_session()
    return run_session != null and run_session.is_active()


func _refresh_collection_list(deck_card_ids: Array[StringName], locked: bool) -> void:
    for child in _collection_list.get_children():
        child.queue_free()
    if not _pvp_mode:
        _build_shop(_collection_list)
    var ids := _progression_system.get_collection_card_ids(_progression_state, _pvp_mode)
    ids.sort_custom(_compare_cards)
    for card_id in ids:
        if not _passes_filter(card_id):
            continue
        var limit := _progression_system.get_card_copy_limit(card_id, _pvp_mode)
        var row := _build_card_row(_collection_list, card_id, "%s/%s" % [deck_card_ids.count(card_id), limit])
        var reason := "Během výpravy nejde." if locked else _progression_system.get_add_block_reason(_progression_state, card_id, _pvp_mode)
        var add_button := _make_small_button("+", reason.is_empty(), reason if not reason.is_empty() else "Přidat do balíku")
        add_button.pressed.connect(_change_deck.bind(card_id, true))
        row.add_child(add_button)
        if reason.is_empty():
            _connect_row_click(row, card_id, true)


const COST_BUCKET_LABELS := ["≤1", "2", "3", "4", "5+"]
const CURVE_BAR_MAX_HEIGHT := 56.0


func _passes_filter(card_id: StringName) -> bool:
    var card_definition := _card_library.get(card_id) as CardDefinition
    if card_definition == null:
        return _cost_filter < 0 and _type_filter < 0
    if _cost_filter >= 0 and ProgressionSystem._cost_bucket(card_definition.cost) != _cost_filter:
        return false
    return _type_filter < 0 or card_definition.card_type == _type_filter


func _refresh_filters() -> void:
    for child in _filter_row.get_children():
        child.queue_free()
    _add_filter_button("Vše", _cost_filter < 0 and _type_filter < 0, _set_filters.bind(-1, -1))
    for bucket in COST_BUCKET_LABELS.size():
        _add_filter_button(COST_BUCKET_LABELS[bucket], _cost_filter == bucket, _set_filters.bind(-1 if _cost_filter == bucket else bucket, _type_filter))
    for pair in [[CardGameConstants.CardType.CAT, "Kočky"], [CardGameConstants.CardType.TRICK, "Triky"], [CardGameConstants.CardType.ITEM, "Předměty"]]:
        _add_filter_button(pair[1], _type_filter == pair[0], _set_filters.bind(_cost_filter, -1 if _type_filter == pair[0] else pair[0]))


func _add_filter_button(text: String, selected: bool, callback: Callable) -> void:
    var button := _make_small_button(text, true, "Filtr kolekce (cena v Tunách / typ). Druhý klik filtr zruší.")
    button.add_theme_font_size_override("font_size", 15)
    button.custom_minimum_size = Vector2(maxi(44, text.length() * 10 + 24), 34)
    if selected:
        button.add_theme_stylebox_override("normal", _button_hover_style)
        button.add_theme_color_override("font_color", Color(1.0, 0.86, 0.5, 1))
    button.pressed.connect(callback)
    _filter_row.add_child(button)


func _set_filters(cost_bucket: int, card_type: int) -> void:
    _cost_filter = cost_bucket
    _type_filter = card_type
    _refresh_ui()


func _refresh_curve(deck_card_ids: Array[StringName]) -> void:
    for child in _curve_row.get_children():
        child.queue_free()
    var counts := [0, 0, 0, 0, 0]
    var type_counts := {}
    for card_id in deck_card_ids:
        var card_definition := _card_library.get(card_id) as CardDefinition
        if card_definition == null:
            continue
        counts[ProgressionSystem._cost_bucket(card_definition.cost)] += 1
        type_counts[card_definition.card_type] = int(type_counts.get(card_definition.card_type, 0)) + 1
    var peak := maxi(1, counts.max())
    for bucket in counts.size():
        var column := VBoxContainer.new()
        column.custom_minimum_size = Vector2(44, 0)
        column.alignment = BoxContainer.ALIGNMENT_END
        column.add_theme_constant_override("separation", 2)
        column.tooltip_text = "%s karet za %s Tun" % [counts[bucket], COST_BUCKET_LABELS[bucket]]
        _curve_row.add_child(column)
        var count_label := Label.new()
        _style_label(count_label, 14, Color(0.95, 0.88, 0.74, 1))
        count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        count_label.text = str(counts[bucket])
        column.add_child(count_label)
        var bar_slot := Control.new()
        bar_slot.custom_minimum_size = Vector2(44, CURVE_BAR_MAX_HEIGHT)
        column.add_child(bar_slot)
        var bar := ColorRect.new()
        var height := CURVE_BAR_MAX_HEIGHT * float(counts[bucket]) / float(peak)
        bar.color = Color(0.86, 0.62, 0.3, 0.95)
        bar.position = Vector2(8, CURVE_BAR_MAX_HEIGHT - height)
        bar.size = Vector2(28, height)
        bar_slot.add_child(bar)
        var cost_label := Label.new()
        _style_label(cost_label, 13, Color(0.8, 0.72, 0.58, 1))
        cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        cost_label.text = COST_BUCKET_LABELS[bucket]
        column.add_child(cost_label)
    _type_summary.text = "Kočky %s · Triky %s · Předměty %s  (cena v Tunách)" % [
        type_counts.get(CardGameConstants.CardType.CAT, 0),
        type_counts.get(CardGameConstants.CardType.TRICK, 0),
        type_counts.get(CardGameConstants.CardType.ITEM, 0),
    ]


# Obchod (E3): nabídky nad kolekcí, nové po každém zápase (seed = počet odehraných).
func _build_shop(parent: Container) -> void:
    var box := VBoxContainer.new()
    box.name = "ShopBox"
    box.add_theme_constant_override("separation", 8)
    parent.add_child(box)
    var scales := _progression_system.get_scales(_progression_state)
    var head_row := HBoxContainer.new()
    head_row.add_theme_constant_override("separation", 8)
    box.add_child(head_row)
    var coin := TextureRect.new()
    coin.texture = load("res://assets/card_game/ui/sheet/icon_scales.png")
    coin.custom_minimum_size = Vector2(30, 30)
    coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    head_row.add_child(coin)
    var head := Label.new()
    _style_label(head, 17, Color(0.96, 0.82, 0.52, 1), true)
    head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    head.text = "Obchod · rybí šupiny: %s · nové nabídky po každém zápase" % scales
    head_row.add_child(head)
    var played := _progression_system.get_win_count(_progression_state) + _progression_system.get_loss_count(_progression_state)
    var offers := _progression_system.roll_shop_offers(_progression_state, played)
    if offers.is_empty():
        head.text += " · máš všechny karty"
    for card_id in offers:
        var price := _progression_system.get_card_price(card_id)
        var row := _build_card_row(box, card_id, "")
        var enough := scales >= price
        var button := _make_small_button("Koupit %s" % price, enough, "Koupit do kolekce" if enough else "Chybí šupiny (%s/%s)." % [scales, price])
        button.custom_minimum_size = Vector2(120, 40)
        button.add_theme_font_size_override("font_size", 16)
        button.pressed.connect(_buy_card.bind(card_id))
        row.add_child(button)


func _buy_card(card_id: StringName) -> void:
    var reason := _progression_system.buy_card(_progression_state, card_id)
    if reason.is_empty():
        _progression_system.save_state(_progression_state)
    _refresh_ui()


func _compare_cards(a: StringName, b: StringName) -> bool:
    var da := _card_library.get(a) as CardDefinition
    var db := _card_library.get(b) as CardDefinition
    if da == null or db == null:
        return String(a) < String(b)
    if da.cost != db.cost:
        return da.cost < db.cost
    return da.display_name < db.display_name


func _change_deck(card_id: StringName, add: bool) -> void:
    if _is_deck_locked():
        return
    if add:
        _progression_state = _progression_system.add_card_to_deck(_progression_state, card_id, _pvp_mode)
    else:
        _progression_state = _progression_system.remove_card_from_deck(_progression_state, card_id, _pvp_mode)
    _progression_system.save_state(_progression_state)
    _refresh_ui()


# Klik na řádek = totéž co +/− (rychlejší stavění).
func _connect_row_click(row: Control, card_id: StringName, add: bool) -> void:
    row.gui_input.connect(func(event: InputEvent):
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _change_deck.call_deferred(card_id, add))


func _fill_deck() -> void:
    if _is_deck_locked():
        return
    _progression_state = _progression_system.fill_deck(_progression_state, _pvp_mode)
    _progression_system.save_state(_progression_state)
    _refresh_ui()


func _make_small_button(text: String, enabled: bool, tooltip: String) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(44, 40)
    button.disabled = not enabled
    button.tooltip_text = tooltip
    button.add_theme_font_size_override("font_size", 22)
    button.add_theme_color_override("font_color", Color(0.96, 0.88, 0.73, 1))
    button.add_theme_color_override("font_disabled_color", Color(0.55, 0.48, 0.38, 0.7))
    button.add_theme_stylebox_override("normal", _button_normal_style)
    button.add_theme_stylebox_override("hover", _button_hover_style)
    button.add_theme_stylebox_override("pressed", _button_pressed_style)
    button.add_theme_stylebox_override("disabled", _section_style)
    return button


# Řádek karty: náhled artu, jméno s počtem, staty a keyword.
func _build_card_row(parent: Container, card_id: StringName, count_text: String) -> HBoxContainer:
    var card_definition: CardDefinition = _card_library.get(card_id) as CardDefinition
    var card_name := String(card_id) if card_definition == null or card_definition.display_name.is_empty() else card_definition.display_name
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 12)
    parent.add_child(row)
    var thumb := TextureRect.new()
    thumb.custom_minimum_size = Vector2(72, 44)
    thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    thumb.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    if card_definition != null:
        thumb.texture = CardArtCache.get_cropped_aspect(card_definition.art_path, 72.0 / 44.0)
    row.add_child(thumb)
    var card_line := Label.new()
    _style_label(card_line, 17, Color(0.95, 0.88, 0.74, 1), false)
    card_line.text = "%s %s" % [count_text, card_name]
    card_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card_line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    card_line.clip_text = true
    row.add_child(card_line)
    if card_definition != null:
        var detail := Label.new()
        var keyword_text := ""
        if not card_definition.keywords.is_empty():
            keyword_text = "%s · " % CardGameConstants.keyword_label(card_definition.keywords[0])
        if card_definition.card_type == CardGameConstants.CardType.CAT:
            detail.text = "%scena %s · %s/%s" % [keyword_text, card_definition.cost, card_definition.attack, card_definition.life]
        else:
            var type_text := "Trik" if card_definition.card_type == CardGameConstants.CardType.TRICK else "Předmět"
            detail.text = "%s · cena %s" % [type_text, card_definition.cost]
        _style_label(detail, 14, Color(0.8, 0.72, 0.58, 1), false)
        detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        card_line.tooltip_text = card_definition.rules_text
        card_line.mouse_filter = Control.MOUSE_FILTER_PASS
        detail.tooltip_text = card_definition.rules_text
        detail.mouse_filter = Control.MOUSE_FILTER_PASS
        row.add_child(detail)
        row.mouse_filter = Control.MOUSE_FILTER_PASS
        row.mouse_entered.connect(_show_hover_preview.bind(card_definition))
        row.mouse_exited.connect(_hide_hover_preview)
    return row


func _build_hover_preview() -> void:
    _hover_preview = PREVIEW_SCENE.instantiate()
    _hover_preview.top_level = true
    _hover_preview.visible = false
    _hover_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_hover_preview)
    if _hover_preview.has_method("set_display_mode"):
        _hover_preview.set_display_mode(&"full")
    _hover_preview.size = PREVIEW_SIZE


# Náhled karty nad protějším panelem, ať nezakrývá řádek, na který hráč míří.
func _show_hover_preview(card_definition: CardDefinition) -> void:
    if _hover_preview == null or card_definition == null:
        return
    var instance := CardInstance.new()
    instance.definition = card_definition
    instance.current_attack = card_definition.attack
    instance.current_life = card_definition.life
    _hover_preview.set_card_instance(instance)
    var viewport_size := get_viewport_rect().size
    var mouse := get_global_mouse_position()
    var half := viewport_size.x * 0.5
    var x := half + 40.0 if mouse.x < half else half - PREVIEW_SIZE.x - 40.0
    var y := clampf(mouse.y - PREVIEW_SIZE.y * 0.5, 16.0, viewport_size.y - PREVIEW_SIZE.y - 16.0)
    _hover_preview.global_position = Vector2(x, y)
    _hover_preview.visible = true


func _hide_hover_preview() -> void:
    if _hover_preview != null:
        _hover_preview.visible = false


func _refresh_run_label() -> void:
    var run_session = _get_run_session()
    if run_session != null and run_session.is_active():
        var route_summary: String = run_session.get_run_roster_summary()
        var progress_text: String = run_session.get_run_progress_text()
        if route_summary.is_empty():
            _run_label.text = "Výprava: %s" % progress_text
        elif progress_text.is_empty():
            _run_label.text = "Výprava: %s" % route_summary
        else:
            _run_label.text = "Výprava: %s | %s" % [progress_text, route_summary]
        return

    _run_label.text = "Výprava: žádná"


func _refresh_deck_list(deck_card_ids: Array[StringName]) -> void:
    for child in _deck_list.get_children():
        child.queue_free()

    if deck_card_ids.is_empty():
        var empty_label := Label.new()
        _style_label(empty_label, 15, Color(0.88, 0.79, 0.64, 0.95), true)
        empty_label.text = "Balík je prázdný."
        _deck_list.add_child(empty_label)
        return

    var card_counts: Dictionary = {}
    var card_order: Array[StringName] = []
    for card_id in deck_card_ids:
        if not card_counts.has(card_id):
            card_order.append(card_id)
            card_counts[card_id] = 0
        card_counts[card_id] = int(card_counts.get(card_id, 0)) + 1

    var locked := _is_deck_locked()
    card_order.sort_custom(_compare_cards)
    for card_id in card_order:
        var row := _build_card_row(_deck_list, card_id, "%sx" % card_counts.get(card_id, 0))
        var can_remove := not locked and _progression_system.can_remove_from_deck(_progression_state, card_id, _pvp_mode)
        var tip := "Odebrat z balíku" if can_remove else ("Během výpravy nejde." if locked else "Balík má minimum %s karet." % ProgressionSystem.get_deck_min_size(_pvp_mode))
        var remove_button := _make_small_button("−", can_remove, tip)
        remove_button.pressed.connect(_change_deck.bind(card_id, false))
        row.add_child(remove_button)
        if can_remove:
            _connect_row_click(row, card_id, false)


func _on_reset_pressed() -> void:
    if not _reset_armed:
        _reset_armed = true
        _reset_button.text = "Opravdu? Klikni znovu"
        return
    _reset_progress()


func _reset_progress() -> void:
    _reset_armed = false
    if _reset_button != null:
        _reset_button.text = RESET_TEXT
    var run_session = _get_run_session()
    if run_session != null and run_session.is_active():
        run_session.end_run()
    _progression_state = _progression_system.reset_state()
    _refresh_ui()


func _return_to_selector() -> void:
    call_deferred("_deferred_return_to_selector")


func _deferred_return_to_selector() -> void:
    var encounter_select_scene := load(ENCOUNTER_SELECT_SCENE_PATH) as PackedScene
    if encounter_select_scene == null:
        push_error("Could not load encounter_select.tscn")
        return

    var select_scene := encounter_select_scene.instantiate() as Control
    if select_scene == null:
        push_error("Could not instantiate encounter_select.tscn")
        return

    var tree := get_tree()
    tree.root.add_child(select_scene)
    tree.current_scene = select_scene
    queue_free()


func _load_resources_by_id(directory_path: String) -> Dictionary:
    var library: Dictionary = {}
    # ResourceLoader.list_directory vidí i exportované soubory (*.tres.remap), DirAccess ne.
    for file_name in ResourceLoader.list_directory(directory_path):
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


func _make_stat_label(parent: Container, title_text: String) -> Label:
    var label := Label.new()
    _style_label(label, 16, Color(0.88, 0.79, 0.64, 0.95), false)
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
