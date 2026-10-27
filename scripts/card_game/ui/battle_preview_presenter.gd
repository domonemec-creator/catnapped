class_name BattlePreviewPresenter
extends RefCounted

const CardEffect = preload("res://scripts/card_game/data/card_effect.gd")
const CardGameConstants = preload("res://scripts/card_game/data/card_game_constants.gd")
const LaneSlotView = preload("res://scripts/card_game/ui/lane_slot_view.gd")

var _selected_card_view
var _selected_card_title: Label
var _selected_card_meta: Label
var _selected_card_detail: RichTextLabel
var _selected_card_hint: Label
var _combat_info_panel: PanelContainer
var _status_label: Label
var _battle_feed_title: Label
var _combat_info_panel_base_style: StyleBoxFlat

var _battle_rules
var _card_library: Dictionary = {}
var _player_id := 0
var _info_zone_none: StringName = &""
var _info_zone_deck: StringName = &"deck"
var _info_zone_discard: StringName = &"discard"

var _get_valid_table_power_lanes: Callable
var _table_power_requires_lane_selection: Callable
var _card_requires_board_target: Callable
var _get_valid_card_target_lanes: Callable
var _card_display_name_from_id: Callable


func setup(config: Dictionary) -> void:
	_selected_card_view = config.get("selected_card_view")
	_selected_card_title = config.get("selected_card_title") as Label
	_selected_card_meta = config.get("selected_card_meta") as Label
	_selected_card_detail = config.get("selected_card_detail") as RichTextLabel
	_selected_card_hint = config.get("selected_card_hint") as Label
	_combat_info_panel = config.get("combat_info_panel") as PanelContainer
	_status_label = config.get("status_label") as Label
	_battle_feed_title = config.get("battle_feed_title") as Label
	_battle_rules = config.get("battle_rules")
	_player_id = int(config.get("player_id", 0))
	_info_zone_none = config.get("info_zone_none", &"")
	_info_zone_deck = config.get("info_zone_deck", &"deck")
	_info_zone_discard = config.get("info_zone_discard", &"discard")
	_get_valid_table_power_lanes = config.get("get_valid_table_power_lanes", Callable())
	_table_power_requires_lane_selection = config.get("table_power_requires_lane_selection", Callable())
	_card_requires_board_target = config.get("card_requires_board_target", Callable())
	_get_valid_card_target_lanes = config.get("get_valid_card_target_lanes", Callable())
	_card_display_name_from_id = config.get("card_display_name_from_id", Callable())


func set_card_library(card_library: Dictionary) -> void:
	_card_library = card_library.duplicate()


func set_combat_info_panel_base_style(style: StyleBoxFlat) -> void:
	_combat_info_panel_base_style = style


func refresh_selected_panel(state: Dictionary) -> void:
	if _selected_card_view == null:
		return
	_selected_card_view.set_selected(false)
	_selected_card_view.set_playable(false)

	var player_state = state.get("player_state")
	var enemy_state = state.get("enemy_state")
	var selected_table_power = state.get("selected_table_power")
	var selected_card = state.get("selected_card")
	var selected_attacker = state.get("selected_attacker")
	var selected_info_zone: StringName = state.get("selected_info_zone", _info_zone_none)

	if selected_table_power != null:
		_selected_card_view.set_card_instance(null)
		set_selected_panel_copy(
			selected_table_power.display_name,
			build_table_power_meta(selected_table_power, player_state),
			build_table_power_detail(selected_table_power, player_state),
			build_table_power_preview_hint(selected_table_power, player_state)
		)
		return

	if selected_card != null:
		_selected_card_view.set_card_instance(selected_card)
		_selected_card_view.set_selected(true)
		set_selected_panel_copy(
			selected_card.definition.display_name,
			build_card_meta(selected_card),
			"",  # pravidla jsou na kartě nahoře, box už je neopakuje
			build_card_preview_hint(selected_card, player_state, enemy_state)
		)
		return

	if selected_attacker != null:
		_selected_card_view.set_card_instance(selected_attacker)
		_selected_card_view.set_selected(true)
		set_selected_panel_copy(
			"Útočník: %s" % selected_attacker.definition.display_name,
			build_attacker_meta(selected_attacker),
			"",  # pravidla jsou na kartě nahoře, box už je neopakuje
			build_attack_preview_hint(selected_attacker, enemy_state)
		)
		return

	if selected_info_zone != _info_zone_none:
		_selected_card_view.set_card_instance(null)
		set_selected_panel_copy(
			build_info_zone_title(selected_info_zone),
			build_info_zone_meta(selected_info_zone, player_state),
			build_info_zone_detail(selected_info_zone, player_state),
			build_info_zone_hint(selected_info_zone)
		)
		return

	# Tah soupeře: ukaž velkou kartu, kterou právě zahrál (myš má přednost).
	var last_played = state.get("enemy_last_played")
	if bool(state.get("enemy_turn", false)) and last_played != null and last_played.definition != null and state.get("hover_card") == null:
		_selected_card_view.set_card_instance(last_played)
		set_selected_panel_copy(
			"Soupeř zahrál: %s" % last_played.definition.display_name,
			build_card_meta(last_played),
			"",
			"Tuhle kartu soupeř právě zahrál. Až dohraje, jsi na řadě ty."
		)
		return

	# Náhled pod myší (jen když nic není vybrané): hlavně soupeřovy kočky, které nejde kliknout.
	var hover_card = state.get("hover_card")
	if hover_card != null and hover_card.definition != null:
		_selected_card_view.set_card_instance(hover_card)
		var owner_text := "Tvoje kočka" if hover_card.owner_id == _player_id else "Soupeřova kočka"
		set_selected_panel_copy(
			hover_card.definition.display_name,
			build_card_meta(hover_card),
			"",  # pravidla jsou na kartě nahoře, box už je neopakuje
			"%s. Klikni pro výběr." % owner_text if hover_card.owner_id == _player_id else "%s. Útočí %s, vydrží %s zranění." % [owner_text, hover_card.current_attack, hover_card.current_life]
		)
		return

	_selected_card_view.set_card_instance(null)
	if _selected_card_view.has_method("set_empty_guide"):
		_selected_card_view.set_empty_guide(build_next_step_guide(player_state, enemy_state, bool(state.get("enemy_turn", false))))
	set_selected_panel_copy(
		"Co teď?",
		"NIC VYBRÁNO",
		"Klikni na kartu v ruce nebo na svou kočku na stole a uvidíš, co umí.",
		build_simple_idle_hint(player_state, enemy_state)
	)
	# Varování před smrtícím útokem soupeře zůstává vidět; jinak stačí průvodce.
	_set_info_panel_visible(not build_enemy_lethal_warning(player_state, enemy_state).is_empty())


# Průvodce pro hráče, který karetní hry nezná: podle stavu řekne konkrétní další krok.
func build_next_step_guide(player_state, enemy_state, enemy_turn: bool) -> String:
	if player_state == null or enemy_state == null:
		return ""
	if enemy_turn:
		return "[center][b]Soupeř je na tahu[/b]

Sleduj, co dělá. Až skončí, jsi zase na řadě ty.[/center]"

	var lines: Array[String] = ["[center][b]Co můžeš udělat teď[/b][/center]", ""]
	var free_lanes := 0
	for slot in player_state.board:
		if slot != null and slot.occupant == null:
			free_lanes += 1
	var playable := 0
	for card in player_state.hand:
		if card != null and card.definition != null and card.definition.cost <= player_state.tuna_current:
			playable += 1
	var ready_attackers := 0
	for slot in player_state.board:
		if slot == null or slot.occupant == null:
			continue
		var cat = slot.occupant
		if cat.can_attack and not cat.has_attacked and _battle_rules != null and not _battle_rules.get_valid_attack_lanes(cat, enemy_state).is_empty():
			ready_attackers += 1

	var step := 1
	if playable > 0 and free_lanes > 0:
		lines.append("[color=#8fe39a][b]%s. Vylož kočku[/b][/color]
Přetáhni kartu z ruky dolů. Máš [b]%s Tuny[/b] (cena v modrém kolečku)." % [step, player_state.tuna_current])
		lines.append("")
		step += 1
	if ready_attackers > 0:
		lines.append("[color=#f2b25c][b]%s. Zaútoč[/b][/color]
Klikni na kočku se zeleným rámečkem, pak na lajnu nad ní. Prázdná = zásah do soupeře, kočka vrací úder." % step)
		lines.append("")
		step += 1
	if player_state.tuna_current >= 3 and not player_state.table_power_used_this_turn and not player_state.deck.is_empty() and player_state.table_power_id != StringName():
		lines.append("[color=#9fc7f0][b]%s. Objednej rundu[/b][/color]\nZa 3 Tuny lízneš kartu (tlačítko dole, 1× za tah)." % step)
		lines.append("")
		step += 1
	if step == 1:
		lines.append("[color=#e8d8b0][b]Hotovo pro tohle kolo[/b][/color]
Už nemůžeš nic vyložit ani zaútočit. Klikni na [b]Konec tahu[/b].")
	else:
		lines.append("[color=#bfae8a]Až budeš hotový, klikni na [b]Konec tahu[/b].[/color]")
	lines.append("")
	if player_state.deck.is_empty():
		lines.append("[color=#e06a5a][b]Prázdný balík![/b] Každé další líznutí tě stojí životy (Hlad). Dotlač to rychle.[/color]")
		lines.append("")
	lines.append("[font_size=13][color=#9c8f78]Kolečka: [color=#7fa8e6]modré[/color] cena · [color=#e0a050]oranžové[/color] útok · [color=#e06a5a]červené[/color] životy[/color][/font_size]")
	return "
".join(lines)


func refresh_combat_info_panel(state: Dictionary) -> void:
	var battle_state = state.get("battle_state")
	if _combat_info_panel == null or _combat_info_panel_base_style == null or battle_state == null:
		return

	var panel_style := _combat_info_panel_base_style.duplicate() as StyleBoxFlat
	var status_color := Color(0.97, 0.93, 0.86, 1.0)
	var feed_title_color := Color(0.95, 0.84, 0.62, 1.0)

	if battle_state.battle_over:
		panel_style.bg_color = Color(0.17, 0.12, 0.08, 0.96)
		panel_style.border_color = Color(0.92, 0.72, 0.32, 0.98)
		status_color = Color(1.0, 0.95, 0.84, 1.0)
		feed_title_color = Color(0.98, 0.83, 0.45, 1.0)
	elif state.get("selected_attacker") != null or state.get("selected_card") != null or state.get("selected_table_power") != null or state.get("selected_info_zone", _info_zone_none) != _info_zone_none:
		panel_style.bg_color = Color(0.18, 0.12, 0.07, 0.96)
		panel_style.border_color = Color(0.95, 0.73, 0.35, 0.97)
		status_color = Color(1.0, 0.92, 0.82, 1.0)
		feed_title_color = Color(0.98, 0.8, 0.46, 1.0)
	else:
		if battle_state.active_player_id == _player_id:
			panel_style.bg_color = Color(0.10, 0.13, 0.09, 0.96)
			panel_style.border_color = Color(0.58, 0.82, 0.48, 0.95)
			status_color = Color(0.92, 0.98, 0.92, 1.0)
			feed_title_color = Color(0.76, 0.95, 0.76, 1.0)
		else:
			panel_style.bg_color = Color(0.17, 0.09, 0.08, 0.96)
			panel_style.border_color = Color(0.84, 0.42, 0.32, 0.95)
			status_color = Color(0.99, 0.91, 0.88, 1.0)
			feed_title_color = Color(0.97, 0.74, 0.66, 1.0)

	# Jednotné tmavé pozadí, stav tahu nese hlavně barva rámečku; vnitřní okraj, ať text nelepí na hranu.
	panel_style.bg_color = Color(panel_style.bg_color.r * 0.7, panel_style.bg_color.g * 0.7, panel_style.bg_color.b * 0.7, 0.86)
	panel_style.content_margin_left = 16.0
	panel_style.content_margin_right = 16.0
	panel_style.content_margin_top = 8.0
	panel_style.content_margin_bottom = 8.0
	panel_style.set_corner_radius_all(12)
	_combat_info_panel.add_theme_stylebox_override("panel", panel_style)
	if _status_label != null:
		_status_label.add_theme_color_override("font_color", status_color)
	if _battle_feed_title != null:
		_battle_feed_title.add_theme_color_override("font_color", feed_title_color)


func build_simple_idle_hint(player_state, enemy_state) -> String:
	var warning := build_enemy_lethal_warning(player_state, enemy_state)
	if not warning.is_empty():
		return "%s\nZavři otevřenou lajnu nebo přidej blok." % warning
	return "Vylož kočku nebo zaútoč připravenou kočkou."


func build_card_meta(card_instance, player_state = null) -> String:
	if card_instance == null or card_instance.definition == null:
		return "NEZNÁMO"

	var parts: Array[String] = [card_type_label(card_instance.definition.card_type), "Cena %s Tuna" % card_instance.definition.cost]
	if card_instance.definition.card_type == CardGameConstants.CardType.TRICK and player_state != null:
		parts.append("Rez. %s" % player_state.saved_tuna_current)
	if card_instance.definition.card_type == CardGameConstants.CardType.CAT:
		parts.append("%s ÚTK / %s ŽIV" % [card_instance.current_attack, card_instance.current_life])
	return " | ".join(parts)


func build_attacker_meta(card_instance) -> String:
	if card_instance == null or card_instance.definition == null:
		return "ÚTOČNÍK"

	return "ÚTOČNÍK | %s ÚTK / %s ŽIV | Lajna %s" % [
		card_instance.current_attack,
		card_instance.current_life,
		card_instance.lane_index + 1
	]


func build_attack_preview_hint(card_instance, enemy_state) -> String:
	if card_instance == null or enemy_state == null:
		return "Není vybraný útočník."

	var preview_lines := build_attack_preview_lines(card_instance, enemy_state)
	if preview_lines.is_empty():
		return "Není platná nepřátelská lajna."
	return "Klikni na nepřátelskou lajnu.\n%s" % "\n".join(preview_lines)


func build_table_power_meta(power_definition, player_state) -> String:
	if power_definition == null:
		return "SÍLA STOLU"

	var parts: Array[String] = ["SÍLA STOLU", "Cena %s Tuny" % power_definition.cost]
	if player_state != null:
		if player_state.table_power_used_this_turn:
			parts.append("VYUŽITO")
		elif player_state.tuna_current < power_definition.cost:
			parts.append("MÁLO TUNY")
		else:
			parts.append("PŘIPRAVENO")
	return " | ".join(parts)


func build_table_power_preview_hint(power_definition, player_state) -> String:
	if power_definition == null:
		return "Není vybraná Síla stolu."
	if player_state == null:
		return "Chybí stav hráče."
	if player_state.table_power_used_this_turn:
		return "Tohle jsi už tenhle tah použil."
	if player_state.tuna_current < power_definition.cost:
		return "Nemáš dost Tuny."
	if _table_power_requires_lane_selection.is_valid() and _table_power_requires_lane_selection.call(power_definition):
		var valid_lanes: Array = _get_valid_table_power_lanes.call(power_definition, player_state)
		if valid_lanes.is_empty():
			return "Není platná lajna na tvé straně."
		var lines: Array[String] = []
		for lane_index in valid_lanes:
			lines.append("Ty %s: vyvolá %s." % [lane_index + 1, build_table_power_lane_preview(power_definition)])
		return "Klikni na svou lajnu.\n%s" % "\n".join(lines)
	return "Použij Sílu stolu."


func build_card_preview_hint(card_instance, player_state, enemy_state) -> String:
	if card_instance == null or card_instance.definition == null:
		return "Výběr z ruky zrušen."

	if player_state != null:
		var available_tuna: int = int(player_state.tuna_current)
		if card_instance.definition.card_type == CardGameConstants.CardType.TRICK:
			available_tuna += player_state.saved_tuna_current
		if available_tuna < card_instance.definition.cost:
			if card_instance.definition.card_type == CardGameConstants.CardType.TRICK:
				return "Nemáš dost Tuny. Běžná %s + rezerva %s." % [player_state.tuna_current, player_state.saved_tuna_current]
			return "Nemáš dost Tuny."

	if card_instance.definition.card_type == CardGameConstants.CardType.CAT:
		var valid_play_lanes: Array = _battle_rules.get_valid_play_lanes(card_instance, player_state)
		if valid_play_lanes.is_empty():
			return "Na tvé straně není volná lajna."
		var lines: Array[String] = []
		for lane_index in valid_play_lanes:
			lines.append("Ty %s: vyložit %s." % [lane_index + 1, card_instance.definition.display_name])
		return "Klikni na volnou lajnu.\n%s" % "\n".join(lines)

	if _card_requires_board_target.is_valid() and not _card_requires_board_target.call(card_instance):
		return build_instant_card_preview_hint(card_instance)

	var target_lines := build_target_preview_lines(card_instance, player_state, enemy_state)
	if target_lines.is_empty():
		return "Na stole není platný cíl."
	return "Klikni na cíl.\n%s" % "\n".join(target_lines)


func build_instant_card_preview_hint(card_instance) -> String:
	if card_instance == null or card_instance.definition == null:
		return "Tahle karta se vyřeší hned."

	var effect_lines: Array[String] = []
	for effect in card_instance.definition.effects:
		var typed_effect: CardEffect = effect
		if typed_effect == null:
			continue
		match typed_effect.action:
			&"draw_cards":
				effect_lines.append("Lízneš %s kart%s." % [typed_effect.value, "u" if typed_effect.value == 1 else "y"])
			&"heal_life":
				effect_lines.append("Vyléčí %s životů." % typed_effect.value)
			&"deal_damage":
				effect_lines.append("Udělí %s zranění." % typed_effect.value)

	if effect_lines.is_empty():
		return "Tahle karta se vyřeší hned."
	return "Tahle karta se vyřeší hned.\n%s" % "\n".join(effect_lines)


func build_target_preview_lines(card_instance, player_state, enemy_state) -> Array[String]:
	var lines: Array[String] = []
	if card_instance == null or player_state == null or enemy_state == null or not _get_valid_card_target_lanes.is_valid():
		return lines

	for lane_index in _get_valid_card_target_lanes.call(card_instance, player_state, enemy_state, player_state.player_id):
		var slot = player_state.board[lane_index]
		if slot == null or slot.occupant == null:
			continue
		lines.append("Ty %s: %s" % [lane_index + 1, describe_target_preview(card_instance, slot.occupant)])

	for lane_index in _get_valid_card_target_lanes.call(card_instance, player_state, enemy_state, enemy_state.player_id):
		var slot = enemy_state.board[lane_index]
		if slot == null or slot.occupant == null:
			continue
		lines.append("Soupeř %s: %s" % [lane_index + 1, describe_target_preview(card_instance, slot.occupant)])

	return lines


func describe_target_preview(card_instance, target_card) -> String:
	if card_instance == null or target_card == null:
		return "bez efektu"

	var parts: Array[String] = []
	for effect in card_instance.definition.effects:
		var typed_effect: CardEffect = effect
		if typed_effect == null:
			continue
		match typed_effect.action:
			&"modify_attack":
				parts.append("%s ÚTK -> %s" % [format_signed_number(typed_effect.value), target_card.current_attack + typed_effect.value])
			&"modify_life":
				var next_life := maxi(0, target_card.current_life + typed_effect.value)
				parts.append("%s ŽIV -> %s" % [format_signed_number(typed_effect.value), next_life])
			&"deal_damage":
				var remaining_life := maxi(0, target_card.current_life - typed_effect.value)
				parts.append("KO" if remaining_life <= 0 else "zbyde %s ŽIV" % remaining_life)
			&"ready_attack":
				parts.append("připraví útok")
			&"return_to_hand":
				parts.append("vrátí do ruky")
			&"steal_item":
				parts.append("ukradne předmět")
			&"destroy_item":
				parts.append("zničí předmět")
			&"grant_keyword":
				parts.append("+%s" % CardGameConstants.keyword_label(typed_effect.keyword_arg))

	if parts.is_empty():
		return "bez efektu"
	return ", ".join(parts)


func build_target_preview_banner(card_instance, target_card) -> Dictionary:
	var preview := {
		"text": "CÍL",
		"tone": LaneSlotView.EVENT_ACTION,
	}
	if card_instance == null or target_card == null or card_instance.definition == null:
		return preview

	var parts: Array[String] = []
	var tone := LaneSlotView.EVENT_ACTION
	for effect in card_instance.definition.effects:
		var typed_effect: CardEffect = effect
		if typed_effect == null:
			continue
		match typed_effect.action:
			&"modify_attack":
				parts.append("%s ÚTK" % format_signed_number(typed_effect.value))
				tone = LaneSlotView.EVENT_SUPPORT if typed_effect.value >= 0 else LaneSlotView.EVENT_DAMAGE
			&"modify_life":
				parts.append("%s ŽIV" % format_signed_number(typed_effect.value))
				tone = LaneSlotView.EVENT_SUPPORT if typed_effect.value >= 0 else LaneSlotView.EVENT_DAMAGE
			&"deal_damage":
				var remaining_life := maxi(0, target_card.current_life - typed_effect.value)
				parts.append("KO" if remaining_life <= 0 else "-%s ŽIV" % typed_effect.value)
				tone = LaneSlotView.EVENT_KO if remaining_life <= 0 else LaneSlotView.EVENT_DAMAGE
			&"ready_attack":
				parts.append("PŘIPRAVÍ")
				tone = LaneSlotView.EVENT_SUPPORT
			&"return_to_hand":
				parts.append("VRÁTÍ")
				tone = LaneSlotView.EVENT_ACTION
			&"steal_item":
				parts.append("UKRADNE")
				tone = LaneSlotView.EVENT_ACTION
			&"destroy_item":
				parts.append("ZNIČÍ")
				tone = LaneSlotView.EVENT_DAMAGE
			&"grant_keyword":
				parts.append("+%s" % CardGameConstants.keyword_label(typed_effect.keyword_arg).to_upper())
				tone = LaneSlotView.EVENT_SUPPORT

	if parts.is_empty():
		return preview

	if parts.size() > 2:
		parts.resize(2)
	preview["text"] = ", ".join(parts)
	preview["tone"] = tone
	return preview


func build_attack_preview_lines(attacker, defender_state) -> Array[String]:
	var lines: Array[String] = []
	if attacker == null or defender_state == null:
		return lines

	for lane_index in _battle_rules.get_valid_attack_lanes(attacker, defender_state):
		lines.append("Soupeř %s: %s" % [lane_index + 1, describe_attack_preview(attacker, defender_state, lane_index)])
	return lines


func describe_attack_preview(attacker, defender_state, lane_index: int) -> String:
	if attacker == null or defender_state == null:
		return "bez cíle"

	var target_card = _battle_rules.get_lane_defender(attacker, defender_state, lane_index)
	if target_card != null:
		var remaining_life := maxi(0, target_card.current_life - attacker.current_attack)
		var outcome := "%s padne." % target_card.definition.display_name if remaining_life <= 0 else "%s zbyde %s ŽIV." % [target_card.definition.display_name, remaining_life]
		return outcome + _retaliation_sentence(attacker, target_card, remaining_life)

	var guard_target = _battle_rules.find_guard_for_direct_damage(defender_state, lane_index)
	if guard_target != null:
		var guard_life := maxi(0, guard_target.current_life - attacker.current_attack)
		var guard_outcome := "%s zachytí zásah a padne." % guard_target.definition.display_name if guard_life <= 0 else "%s zachytí zásah, zbyde %s ŽIV." % [guard_target.definition.display_name, guard_life]
		return guard_outcome + _retaliation_sentence(attacker, guard_target, guard_life)

	return "přímý zásah za %s." % attacker.current_attack


func build_attack_preview_banner(attacker, defender_state, lane_index: int) -> Dictionary:
	var preview := {
		"text": "ÚTOK",
		"tone": LaneSlotView.EVENT_ACTION,
	}
	if attacker == null or defender_state == null:
		return preview

	var target_card = _battle_rules.get_lane_defender(attacker, defender_state, lane_index)
	if target_card != null:
		var remaining_life := maxi(0, target_card.current_life - attacker.current_attack)
		preview["text"] = ("KO" if remaining_life <= 0 else "ZBYDE %s" % remaining_life) + _retaliation_suffix(attacker, target_card, remaining_life)
		preview["tone"] = LaneSlotView.EVENT_KO if remaining_life <= 0 else LaneSlotView.EVENT_DAMAGE
		return preview

	var guard_target = _battle_rules.find_guard_for_direct_damage(defender_state, lane_index)
	if guard_target != null:
		var guard_life := maxi(0, guard_target.current_life - attacker.current_attack)
		preview["text"] = ("OCHRANA KO" if guard_life <= 0 else "OCHRANA %s" % guard_life) + _retaliation_suffix(attacker, guard_target, guard_life)
		preview["tone"] = LaneSlotView.EVENT_BLOCK
		return preview

	preview["text"] = "PŘÍMO %s" % attacker.current_attack
	preview["tone"] = LaneSlotView.EVENT_DIRECT
	return preview


func _retaliation_sentence(attacker, defender_card, defender_life_after: int) -> String:
	var suffix := _retaliation_suffix(attacker, defender_card, defender_life_after)
	if suffix.is_empty():
		return ""
	var strike: int = defender_card.current_attack
	if attacker.current_life - strike <= 0:
		return " Odveta %s: tvá kočka padne." % strike
	return " Odveta: tvá kočka dostane %s." % strike


# Odveta (D-014): Mark nechápal, proč jeho kočka dostala -4. Náhled ji ukáže předem.
func _retaliation_suffix(attacker, defender_card, defender_life_after: int) -> String:
	if not CardGameConstants.combat_retaliation or defender_card == null:
		return ""
	if CardGameConstants.attacker_first_strike and defender_life_after <= 0:
		return ""
	var strike: int = defender_card.current_attack
	if strike <= 0:
		return ""
	if attacker.current_life - strike <= 0:
		return "
ODVETA -%s · TVÁ PADNE" % strike
	return "
ODVETA -%s" % strike


func build_enemy_lethal_warning(player_state, enemy_state) -> String:
	if player_state == null or enemy_state == null or player_state.life <= 0:
		return ""

	var direct_damage := 0
	var threat_lines: Array[String] = []
	for slot in enemy_state.board:
		if slot == null or slot.occupant == null:
			continue
		var attacker = slot.occupant
		var direct_lane := find_direct_attack_lane(attacker, player_state)
		if direct_lane < 0:
			continue
		direct_damage += attacker.current_attack
		threat_lines.append("%s přes lajnu %s" % [attacker.definition.display_name, direct_lane + 1])

	if direct_damage < player_state.life:
		return ""

	var threat_count := threat_lines.size()
	if threat_count <= 1:
		return "SMRTÍCÍ HROZBA: hrozí %s přímého zranění." % direct_damage
	return "SMRTÍCÍ HROZBA: hrozí %s přímého zranění z %s lajn." % [direct_damage, threat_count]


func find_direct_attack_lane(attacker, defender_state) -> int:
	if attacker == null or defender_state == null or attacker.lane_index < 0:
		return -1

	var lane_indexes: Array[int] = [attacker.lane_index]
	if attacker.has_keyword(CardGameConstants.KEYWORD_POUNCE):
		if attacker.lane_index > 0:
			lane_indexes.append(attacker.lane_index - 1)
		if attacker.lane_index < defender_state.board.size() - 1:
			lane_indexes.append(attacker.lane_index + 1)

	for lane_index in lane_indexes:
		var slot = defender_state.board[lane_index]
		if slot != null and slot.occupant != null:
			continue
		if _battle_rules.find_guard_for_direct_damage(defender_state, lane_index) != null:
			continue
		return lane_index

	return -1


func collect_enemy_direct_threats(player_state, enemy_state) -> Array[Dictionary]:
	var threats: Array[Dictionary] = []
	if player_state == null or enemy_state == null:
		return threats

	for slot in enemy_state.board:
		if slot == null or slot.occupant == null:
			continue
		var attacker = slot.occupant
		var direct_lane := find_direct_attack_lane(attacker, player_state)
		if direct_lane < 0:
			continue
		threats.append({
			"attacker_lane": attacker.lane_index,
			"target_lane": direct_lane,
			"damage": attacker.current_attack,
		})
	return threats


func build_info_zone_title(zone_id: StringName) -> String:
	match zone_id:
		_info_zone_deck:
			return "Balík"
		_info_zone_discard:
			return "Odhazování"
	return "Náhled"


func build_info_zone_meta(zone_id: StringName, player_state) -> String:
	if player_state == null:
		return "CHYBÍ DATA"

	var cards = get_info_zone_cards(zone_id, player_state)
	var type_count := count_unique_card_names(cards)
	match zone_id:
		_info_zone_deck:
			return "BALÍK | %s karet | %s typů" % [cards.size(), type_count]
		_info_zone_discard:
			return "ODHAZOVÁNÍ | %s karet | %s typů" % [cards.size(), type_count]
	return "NÁHLED"


func build_info_zone_detail(zone_id: StringName, player_state) -> String:
	if player_state == null:
		return "Chybí stav hráče."

	var cards = get_info_zone_cards(zone_id, player_state)
	if cards.is_empty():
		return "Prázdno."
	return build_card_stack_summary(cards)


func build_info_zone_hint(zone_id: StringName) -> String:
	match zone_id:
		_info_zone_deck:
			return "Klikni znovu na Balík pro zavření."
		_info_zone_discard:
			return "Klikni znovu na Odhazování pro zavření."
	return "Klikni znovu pro zavření."


func get_info_zone_cards(zone_id: StringName, player_state) -> Array:
	match zone_id:
		_info_zone_deck:
			return player_state.deck
		_info_zone_discard:
			return player_state.discard
	return []


func count_unique_card_names(cards: Array) -> int:
	return count_cards_by_name(cards).size()


func build_card_stack_summary(cards: Array) -> String:
	var counts := count_cards_by_name(cards)
	var names := counts.keys()
	names.sort()

	var lines: Array[String] = []
	for card_name_value in names:
		var card_name: String = str(card_name_value)
		lines.append("%sx %s" % [counts[card_name], card_name])
	return "\n".join(lines)


func count_cards_by_name(cards: Array) -> Dictionary:
	var counts: Dictionary = {}
	for card in cards:
		if card == null or card.definition == null:
			continue
		var card_name: String = str(card.definition.display_name)
		counts[card_name] = int(counts.get(card_name, 0)) + 1
	return counts


func build_table_power_lane_preview(power_definition) -> String:
	if power_definition == null:
		return "token"

	for effect in power_definition.effects:
		var typed_effect: CardEffect = effect
		if typed_effect != null and typed_effect.action == &"summon_token":
			return card_display_name_from_id(StringName(typed_effect.keyword_arg))
	return power_definition.display_name


func format_signed_number(value: int) -> String:
	return "%s%s" % ["+" if value >= 0 else "", value]


func card_type_label(card_type: int) -> String:
	match card_type:
		CardGameConstants.CardType.TRICK:
			return "TRIK"
		CardGameConstants.CardType.ITEM:
			return "PŘEDMĚT"
		_:
			return "KOČKA"


func build_card_detail(card_definition) -> String:
	if not card_definition.rules_text.is_empty():
		if card_definition.keywords.is_empty():
			return card_definition.rules_text
		var detail_lines: Array[String] = [card_definition.rules_text]
		for keyword in card_definition.keywords:
			detail_lines.append("%s: %s" % [CardGameConstants.keyword_label(keyword), CardGameConstants.keyword_summary(keyword)])
		return "\n".join(detail_lines)

	if card_definition.keywords.is_empty():
		return "Bez dalších efektů."

	var lines: Array[String] = []
	for keyword in card_definition.keywords:
		lines.append("%s: %s" % [CardGameConstants.keyword_label(keyword), CardGameConstants.keyword_summary(keyword)])
	return "\n".join(lines)


func build_table_power_detail(power_definition, player_state) -> String:
	if power_definition == null:
		return "Žádná Síla stolu."

	var lines: Array[String] = [power_definition.rules_text]
	lines.append("Cena: %s Tuna" % power_definition.cost)
	if player_state != null:
		if player_state.table_power_used_this_turn:
			lines.append("Stav: už využito v tomto kole.")
		elif player_state.tuna_current < power_definition.cost:
			lines.append("Stav: málo Tuny.")
		elif _table_power_requires_lane_selection.is_valid() and _table_power_requires_lane_selection.call(power_definition):
			lines.append("Platné lajny: %s" % format_lane_names(_get_valid_table_power_lanes.call(power_definition, player_state)))
	return "\n".join(lines)


func format_lane_names(lane_indexes: Array) -> String:
	if lane_indexes.is_empty():
		return "žádná"

	var lane_names: Array[String] = []
	for lane_index in lane_indexes:
		lane_names.append("Lajna %s" % (lane_index + 1))
	return ", ".join(lane_names)


func card_display_name_from_id(card_id: StringName) -> String:
	if _card_display_name_from_id.is_valid():
		return str(_card_display_name_from_id.call(card_id))
	var card_definition = _card_library.get(card_id)
	if card_definition == null or card_definition.display_name.is_empty():
		return String(card_id)
	return card_definition.display_name


func set_selected_panel_copy(title: String, meta: String, detail: String, hint: String) -> void:
	if _selected_card_title != null:
		_selected_card_title.text = title
	if _selected_card_meta != null:
		_selected_card_meta.text = meta
	if _selected_card_detail != null:
		# U karet jsou pravidla na kartě; box pak ukáže, co dělat dál (SelectedHint je malý a často skrytý).
		_selected_card_detail.text = detail if not detail.is_empty() else hint
	if _selected_card_hint != null:
		_selected_card_hint.text = hint
	_set_info_panel_visible(true)


# Info box pod kartou (meta/detail/hint). V klidu ho schová průvodce „Co teď?“, aby se texty neopakovaly.
func _set_info_panel_visible(visible: bool) -> void:
	if _selected_card_meta == null:
		return
	var info_panel := _selected_card_meta.get_parent().get_parent().get_parent() as Control
	if info_panel != null:
		info_panel.visible = visible
	if _selected_card_title != null:
		_selected_card_title.visible = visible



