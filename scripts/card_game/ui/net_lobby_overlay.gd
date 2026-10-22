extends Control

# „Hra ve dvou“ (D4): hostování nebo připojení přes přímou IP (LAN / Radmin VPN).
# Hraje se s balíkem z obrazovky Balík a postup. Po domluvě obou stran otevře souboj.

signal closed

const BATTLE_SCENE_PATH := "res://scenes/card_game/battle_scene.tscn"
const KEY_LAST_ADDRESS := "net_last_address"
const PREFS_PATH := "user://net_prefs.cfg"

var _status: Label
var _name_edit: LineEdit
var _address_edit: LineEdit
var _host_button: Button
var _join_button: Button
var _cancel_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(660, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.075, 0.055, 0.98)
	style.border_color = Color(0.72, 0.54, 0.28, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Hra ve dvou"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	vbox.add_child(title)

	var intro := Label.new()
	intro.text = "Oba musíte být ve stejné síti (doma, nebo v Radmin VPN). Jeden hostuje a nadiktuje svou IP, druhý se připojí. Hraje se s balíkem z Balík a postup."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_font_size_override("font_size", 16)
	vbox.add_child(intro)

	_name_edit = _add_field(vbox, "Tvoje jméno", _default_name())
	_name_edit.max_length = 20

	_host_button = _make_button("Hostovat hru", true)
	_host_button.pressed.connect(_on_host_pressed)
	vbox.add_child(_host_button)

	_address_edit = _add_field(vbox, "IP hostitele", _load_last_address())
	_address_edit.placeholder_text = "např. 26.12.34.56"
	_join_button = _make_button("Připojit se", false)
	_join_button.pressed.connect(_on_join_pressed)
	vbox.add_child(_join_button)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 17)
	_status.add_theme_color_override("font_color", Color(0.98, 0.86, 0.6))
	vbox.add_child(_status)

	_cancel_button = _make_button("Zavřít", false)
	_cancel_button.pressed.connect(_close)
	vbox.add_child(_cancel_button)

	var manager := _manager()
	manager.match_ready.connect(_on_match_ready)
	manager.join_failed.connect(_on_join_failed)
	manager.join_succeeded.connect(_on_join_succeeded)
	manager.session_disconnected.connect(_on_join_failed)


func _exit_tree() -> void:
	var manager := _manager()
	if manager == null:
		return
	for pair in [[manager.match_ready, _on_match_ready], [manager.join_failed, _on_join_failed], [manager.join_succeeded, _on_join_succeeded], [manager.session_disconnected, _on_join_failed]]:
		if pair[0].is_connected(pair[1]):
			pair[0].disconnect(pair[1])


func _on_host_pressed() -> void:
	if not _deck_ready():
		return
	var manager := _manager()
	var result: Error = manager.host_session(manager.DEFAULT_PORT, _player_name(), _player_deck())
	if result != OK:
		_status.text = "Hostování selhalo (port %s je asi obsazený)." % manager.DEFAULT_PORT
		return
	var addresses: Array[String] = manager.get_local_ipv4_addresses()
	var address_text := ", ".join(addresses) if not addresses.is_empty() else "nenašel jsem žádnou"
	_status.text = "Čekám na soupeře… Nadiktuj mu svou IP: %s (Radmin začíná 26.). Port %s. Windows se může zeptat na firewall: povol." % [address_text, manager.DEFAULT_PORT]
	_set_busy(true)


func _on_join_pressed() -> void:
	var address := _address_edit.text.strip_edges()
	if not address.is_valid_ip_address():
		_status.text = "Tohle není platná IP adresa."
		return
	if not _deck_ready():
		return
	_save_last_address(address)
	var manager := _manager()
	var result: Error = manager.join_session(address, manager.DEFAULT_PORT, _player_name(), _player_deck())
	if result != OK:
		_status.text = "Připojení nejde spustit (%s)." % result
		return
	_status.text = "Připojuju se k %s…" % address
	_set_busy(true)


func _on_join_succeeded() -> void:
	_status.text = "Spojeno. Domlouvám souboj…"


func _on_join_failed(message: String) -> void:
	_status.text = message
	_set_busy(false)


func _on_match_ready() -> void:
	var battle := (load(BATTLE_SCENE_PATH) as PackedScene).instantiate()
	var tree := get_tree()
	var menu := tree.current_scene
	tree.root.add_child(battle)
	tree.current_scene = battle
	if menu != null:
		menu.queue_free()


func _close() -> void:
	var manager := _manager()
	if manager.is_session_active() and not manager.is_in_match():
		manager.disconnect_session(true)
	closed.emit()
	queue_free()


func _set_busy(busy: bool) -> void:
	_host_button.disabled = busy
	_join_button.disabled = busy
	_cancel_button.text = "Zrušit" if busy else "Zavřít"


func _player_name() -> String:
	var value := _name_edit.text.strip_edges()
	return value if not value.is_empty() else _default_name()


func _player_deck() -> Array[StringName]:
	var progression := ProgressionSystem.new()
	return progression.get_deck_card_ids(progression.load_state(), true)


# Neplatný balík (ne přesně 30 karet) zastaví hostování i připojení s vysvětlením.
func _deck_ready() -> bool:
	var problem := ProgressionSystem.new().get_deck_problem(_player_deck(), true)
	if problem.is_empty():
		return true
	_status.text = "%s Uprav ho v „Balík a postup“ (tlačítko Doplnit)." % problem
	return false


func _default_name() -> String:
	var user := OS.get_environment("USERNAME")
	return user if not user.is_empty() else "Hráč"


func _load_last_address() -> String:
	var config := ConfigFile.new()
	if config.load(PREFS_PATH) != OK:
		return ""
	return str(config.get_value("net", KEY_LAST_ADDRESS, ""))


func _save_last_address(address: String) -> void:
	var config := ConfigFile.new()
	config.load(PREFS_PATH)
	config.set_value("net", KEY_LAST_ADDRESS, address)
	config.save(PREFS_PATH)


func _add_field(parent: Container, label_text: String, value: String) -> LineEdit:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(150, 0)
	label.add_theme_font_size_override("font_size", 17)
	row.add_child(label)
	var edit := LineEdit.new()
	edit.text = value
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.custom_minimum_size = Vector2(0, 40)
	edit.add_theme_font_size_override("font_size", 18)
	row.add_child(edit)
	return edit


func _make_button(text: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 48)
	button.add_theme_font_size_override("font_size", 19)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.85, 0.6, 0.25) if primary else Color(0.24, 0.19, 0.13)
	style.border_color = Color(0.72, 0.54, 0.28)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = style.bg_color.lightened(0.12)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", style)
	if primary:
		button.add_theme_color_override("font_color", Color(0.13, 0.09, 0.04))
		button.add_theme_color_override("font_hover_color", Color(0.1, 0.07, 0.03))
	return button


func _manager() -> Node:
	return get_node_or_null("/root/MultiplayerManager")
