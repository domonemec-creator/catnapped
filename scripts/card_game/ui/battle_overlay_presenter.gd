class_name BattleOverlayPresenter
extends RefCounted

var _style_box_builder: Callable
var _tutorial_dismiss_pressed: Callable
var _progression_system

var _post_match_overlay: Control
var _post_match_backdrop_art: TextureRect
var _post_match_result_emblem: TextureRect
var _post_match_result_title: Label
var _post_match_result_summary: Label
var _post_match_threat_badge: TextureRect
var _post_match_threat_summary: Label
var _post_match_deck_shift_title: Label
var _post_match_deck_shift_detail: Label
var _post_match_record_label: Label
var _post_match_reward_buttons: VBoxContainer
var _post_match_reward_add_button: Button
var _post_match_reward_remove_button: Button
var _post_match_reward_upgrade_button: Button
var _post_match_rematch_button: Button
var _post_match_choose_encounter_button: Button

var _tutorial_overlay: Control
var _reward_offers: Array[Dictionary] = []
var _result_mode := ""
var _result_title := ""
var _run_completion_pending := false


func setup(config: Dictionary) -> void:
	_style_box_builder = config.get("style_box_builder", Callable())
	_tutorial_dismiss_pressed = config.get("tutorial_dismiss_pressed", Callable())
	_progression_system = config.get("progression_system")
	_post_match_overlay = config.get("post_match_overlay") as Control
	_post_match_backdrop_art = config.get("post_match_backdrop_art") as TextureRect
	_post_match_result_emblem = config.get("post_match_result_emblem") as TextureRect
	_post_match_result_title = config.get("post_match_result_title") as Label
	_post_match_result_summary = config.get("post_match_result_summary") as Label
	_post_match_threat_badge = config.get("post_match_threat_badge") as TextureRect
	_post_match_threat_summary = config.get("post_match_threat_summary") as Label
	_post_match_deck_shift_title = config.get("post_match_deck_shift_title") as Label
	_post_match_deck_shift_detail = config.get("post_match_deck_shift_detail") as Label
	_post_match_record_label = config.get("post_match_record_label") as Label
	_post_match_reward_buttons = config.get("post_match_reward_buttons") as VBoxContainer
	_post_match_reward_add_button = config.get("post_match_reward_add_button") as Button
	_post_match_reward_remove_button = config.get("post_match_reward_remove_button") as Button
	_post_match_reward_upgrade_button = config.get("post_match_reward_upgrade_button") as Button
	_post_match_rematch_button = config.get("post_match_rematch_button") as Button
	_post_match_choose_encounter_button = config.get("post_match_choose_encounter_button") as Button


func ensure_tutorial_overlay(parent: Control) -> void:
	if _tutorial_overlay != null:
		return

	var overlay := Control.new()
	overlay.name = "TutorialOverlay"
	overlay.visible = false
	overlay.z_index = 18
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.01, 0.68)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	panel.add_theme_stylebox_override("panel", _build_style_box(
		Color(0.11, 0.08, 0.06, 0.98),
		Color(0.93, 0.72, 0.34, 0.98),
		18,
		2
	))
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var title := Label.new()
	title.text = "Jak to hrát"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.98, 0.92, 0.82, 1.0))
	content.add_child(title)

	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text = "1. Vylož kočku z ruky na volnou lajnu.\n2. Připravenou kočkou útoč do nepřátelské lajny nebo přímo.\n3. Sraz soupeři životy na nulu dřív, než to udělá on."
	body.add_theme_font_size_override("font_size", 18)
	body.add_theme_color_override("font_color", Color(0.95, 0.9, 0.84, 1.0))
	content.add_child(body)

	var button := Button.new()
	button.text = "Rozumím"
	button.custom_minimum_size = Vector2(0, 44)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.13, 0.09, 0.04, 1.0))
	button.add_theme_stylebox_override("normal", _build_style_box(
		Color(0.89, 0.62, 0.2, 1.0),
		Color(0.97, 0.78, 0.4, 1.0),
		12,
		2
	))
	button.add_theme_stylebox_override("hover", _build_style_box(
		Color(0.94, 0.68, 0.24, 1.0),
		Color(1.0, 0.82, 0.46, 1.0),
		12,
		2
	))
	button.add_theme_stylebox_override("pressed", _build_style_box(
		Color(0.84, 0.58, 0.18, 1.0),
		Color(0.95, 0.76, 0.38, 1.0),
		12,
		2
	))
	if _tutorial_dismiss_pressed.is_valid():
		button.pressed.connect(_tutorial_dismiss_pressed)
	content.add_child(button)

	parent.add_child(overlay)
	_tutorial_overlay = overlay


func sync_tutorial_visibility(progression_state: Dictionary) -> void:
	if _tutorial_overlay == null or _progression_system == null:
		return
	_tutorial_overlay.visible = not _progression_system.has_seen_battle_tutorial(progression_state)


func dismiss_tutorial_overlay(progression_state: Dictionary, save_progress: bool = true) -> Dictionary:
	if _tutorial_overlay == null or _progression_system == null:
		return progression_state
	_tutorial_overlay.visible = false
	if not save_progress or _progression_system.has_seen_battle_tutorial(progression_state):
		return progression_state
	var next_state: Dictionary = _progression_system.mark_battle_tutorial_seen(progression_state)
	_progression_system.save_state(next_state)
	return next_state


func hide_post_match_overlay() -> void:
	if _post_match_overlay != null:
		_post_match_overlay.visible = false
	_reward_offers.clear()
	_result_mode = ""
	_result_title = ""
	_run_completion_pending = false


func set_reward_offers(reward_offers: Array[Dictionary]) -> void:
	_reward_offers = reward_offers.duplicate(true)


func get_reward_offers() -> Array[Dictionary]:
	return _reward_offers.duplicate(true)


func clear_reward_offers() -> void:
	_reward_offers.clear()


func get_result_mode() -> String:
	return _result_mode


func is_run_completion_pending() -> bool:
	return _run_completion_pending


func show_post_match_overlay(config: Dictionary) -> void:
	_result_mode = str(config.get("result_mode", ""))
	_result_title = str(config.get("result_title", ""))
	_run_completion_pending = _result_mode == "run_complete"

	var progression_system = config.get("progression_system", _progression_system)
	var progression_state: Dictionary = config.get("progression_state", {})
	var run_session = config.get("run_session")
	var previous_threat := int(config.get("previous_threat", 0))
	var next_threat := int(config.get("next_threat", previous_threat))
	var deck_messages: Array[String] = config.get("deck_messages", [])

	if _post_match_overlay != null:
		_post_match_overlay.visible = true
	if _post_match_backdrop_art != null:
		_post_match_backdrop_art.texture = config.get("backdrop_texture") as Texture2D
	if _post_match_threat_badge != null:
		_post_match_threat_badge.texture = config.get("threat_badge_texture") as Texture2D
	if _post_match_result_title != null:
		_post_match_result_title.text = _result_title
	if _post_match_result_summary != null:
		_post_match_result_summary.text = str(config.get("result_summary", ""))
	if _post_match_threat_summary != null:
		_post_match_threat_summary.text = build_post_match_threat_text(progression_system, previous_threat, next_threat)
	if _post_match_deck_shift_detail != null:
		_post_match_deck_shift_detail.text = build_post_match_deck_shift_text(deck_messages, previous_threat, next_threat)
	if _post_match_record_label != null and progression_system != null:
		var record_text := "Výhry %s   Prohry %s" % [
			progression_system.get_win_count(progression_state),
			progression_system.get_loss_count(progression_state),
		]
		if run_session != null and run_session.is_active():
			var run_progress: String = run_session.get_run_progress_text()
			if not run_progress.is_empty():
				record_text += "   %s" % run_progress
		_post_match_record_label.text = record_text

	if _post_match_result_emblem != null:
		match _result_mode:
			"win", "run_complete":
				_post_match_result_emblem.texture = config.get("victory_emblem_texture") as Texture2D
			"loss":
				_post_match_result_emblem.texture = config.get("defeat_emblem_texture") as Texture2D
			_:
				_post_match_result_emblem.texture = null
		_post_match_result_emblem.visible = _post_match_result_emblem.texture != null

	update_post_match_actions(run_session)


func update_post_match_actions(run_session) -> void:
	var show_reward_draft: bool = _result_mode == "win" and run_session != null and run_session.is_active() and not _reward_offers.is_empty()
	if _post_match_reward_buttons != null:
		_post_match_reward_buttons.visible = show_reward_draft
	if _post_match_rematch_button != null:
		_post_match_rematch_button.visible = not show_reward_draft
	if _post_match_choose_encounter_button != null:
		_post_match_choose_encounter_button.visible = not show_reward_draft

	if show_reward_draft:
		if _post_match_deck_shift_title != null:
			_post_match_deck_shift_title.text = "Vyber odměnu"
		if _post_match_deck_shift_detail != null:
			_post_match_deck_shift_detail.text = "Vyber 1 odměnu. Tvůj balík zůstává i do dalších soubojů."
		refresh_reward_buttons()
		if _post_match_rematch_button != null:
			_post_match_rematch_button.text = "Zopakovat souboj"
		if _post_match_choose_encounter_button != null:
			_post_match_choose_encounter_button.text = "Další souboj" if run_session.has_next_encounter() else "Ukončit run"
		return

	if _post_match_deck_shift_title != null:
		_post_match_deck_shift_title.text = "Další směna"
	if run_session != null and run_session.is_active():
		if _run_completion_pending:
			if _post_match_deck_shift_title != null:
				_post_match_deck_shift_title.text = "Výprava hotová"
			if _post_match_rematch_button != null:
				_post_match_rematch_button.visible = false
			if _post_match_choose_encounter_button != null:
				_post_match_choose_encounter_button.visible = true
				_post_match_choose_encounter_button.text = "Zpět na výběr"
			return
		if _result_mode in ["loss", "draw"]:
			if _post_match_deck_shift_title != null:
				_post_match_deck_shift_title.text = "Výprava skončila"
			if _post_match_deck_shift_detail != null:
				_post_match_deck_shift_detail.text = "Tenhle souboj jsi nevyhrál. Výprava končí a vrátíš se na výběr."
			if _post_match_rematch_button != null:
				_post_match_rematch_button.visible = false
			if _post_match_choose_encounter_button != null:
				_post_match_choose_encounter_button.visible = true
				_post_match_choose_encounter_button.text = "Konec výpravy"
			return
		if _post_match_rematch_button != null:
			_post_match_rematch_button.text = "Zopakovat souboj"
		if _post_match_choose_encounter_button != null:
			_post_match_choose_encounter_button.text = "Další souboj" if run_session.has_next_encounter() else "Ukončit run"
		return

	if _post_match_rematch_button != null:
		_post_match_rematch_button.text = "Odveta"
	if _post_match_choose_encounter_button != null:
		_post_match_choose_encounter_button.text = "Vybrat souboj"


func refresh_reward_buttons() -> void:
	if _post_match_reward_add_button == null or _post_match_reward_remove_button == null or _post_match_reward_upgrade_button == null:
		return
	if _reward_offers.size() < 3:
		_post_match_reward_add_button.text = "Přidat kartu"
		_post_match_reward_remove_button.text = "Odebrat kartu"
		_post_match_reward_upgrade_button.text = "Vylepšit kartu"
		return

	_post_match_reward_add_button.text = str(_reward_offers[0].get("label", "Přidat kartu"))
	_post_match_reward_remove_button.text = str(_reward_offers[1].get("label", "Odebrat kartu"))
	_post_match_reward_upgrade_button.text = str(_reward_offers[2].get("label", "Vylepšit kartu"))


func build_post_match_threat_text(progression_system, previous_threat: int, next_threat: int) -> String:
	if progression_system == null:
		return ""
	var previous_label: String = progression_system.get_threat_label(previous_threat)
	var next_label: String = progression_system.get_threat_label(next_threat)
	if previous_threat == next_threat:
		return "Hrozba zůstává na %s (%s)." % [next_threat, next_label]
	return "Hrozba %s (%s) -> %s (%s)." % [previous_threat, previous_label, next_threat, next_label]


func build_post_match_deck_shift_text(deck_messages: Array[String], previous_threat: int, next_threat: int) -> String:
	if not deck_messages.is_empty():
		return "\n".join(deck_messages)
	if previous_threat == next_threat:
		return "Balík beze změn. Příští odveta použije stejnou sestavu."
	return "Hrozba se změnila, ale tahle úroveň drží stejný balík."


func _build_style_box(background_color: Color, border_color: Color, corner_radius: int, border_width: int) -> StyleBoxFlat:
	if _style_box_builder.is_valid():
		return _style_box_builder.call(background_color, border_color, corner_radius, border_width) as StyleBoxFlat
	return StyleBoxFlat.new()

