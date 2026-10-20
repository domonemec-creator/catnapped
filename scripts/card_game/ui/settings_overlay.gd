extends Control

# Overlay „Nastavení a titulky“: hlasitost hudby a efektů (ukládá Sfx) + titulky assetů.
# Titulky jsou povinné kvůli licenci CC BY (ikony game-icons.net).

const CREDITS_BBCODE := """[center][b]Catnapped![/b]
Hra: Mark (LE Artist) · vývoj s pomocí Claude

[b]Hudba[/b] (CC0)
RandomMind – „The Old Tower Inn“, „The Bard's Tale“ (opengameart.org)

[b]Zvuky[/b] (CC0)
Kenney – Casino Audio, Impact Sounds, Interface Sounds, RPG Audio (kenney.nl)

[b]Ikony klíčových slov[/b] (CC BY 3.0)
Icons by Lorc and Delapouite from game-icons.net

[b]Písmo[/b] (SIL Open Font License)
Alegreya – Juan Pablo del Peral, Huerta Tipográfica

Ilustrace koček a rámů: Mark (LE Artist)[/center]"""

signal closed


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
	panel.custom_minimum_size = Vector2(620, 0)
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
	title.text = "Nastavení"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	vbox.add_child(title)

	var sfx := get_node_or_null("/root/Sfx")
	vbox.add_child(_make_slider_row("Hudba", sfx.music_volume if sfx != null else 0.45, func(v: float) -> void:
		if sfx != null:
			sfx.set_music_volume(v)
	))
	vbox.add_child(_make_slider_row("Efekty", sfx.sfx_volume if sfx != null else 0.8, func(v: float) -> void:
		if sfx != null:
			sfx.set_sfx_volume(v)
			sfx.play(&"card_place")
	))

	var credits := RichTextLabel.new()
	credits.bbcode_enabled = true
	credits.fit_content = true
	credits.scroll_active = false
	credits.text = CREDITS_BBCODE
	credits.add_theme_font_size_override("normal_font_size", 15)
	credits.add_theme_font_size_override("bold_font_size", 16)
	credits.add_theme_color_override("default_color", Color(0.88, 0.82, 0.7))
	vbox.add_child(credits)

	var close_button := Button.new()
	close_button.text = "Zavřít"
	close_button.custom_minimum_size = Vector2(0, 46)
	close_button.add_theme_font_size_override("font_size", 20)
	close_button.pressed.connect(_close)
	vbox.add_child(close_button)


func _make_slider_row(label_text: String, value: float, on_change: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(90, 0)
	label.add_theme_font_size_override("font_size", 20)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size = Vector2(0, 28)
	slider.value_changed.connect(on_change)
	row.add_child(slider)
	return row


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()


func _close() -> void:
	closed.emit()
	queue_free()
