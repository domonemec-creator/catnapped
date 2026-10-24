extends RefCounted

# Rozvržení souboje v2 (UI rozbor 2026-10-21): uzly ze scény přeskládá za běhu,
# takže @onready reference v controlleru zůstanou platné.
#   [Levý sloupec: soupeř / hlášení / ty] [Stůl + ruka] [Pravý panel: náhled + tlačítka]

const RAIL_WIDTH := 270.0
const HERO_PORTRAIT_HEIGHT := 150.0
# UX audit 2026-10-24: strany rozliší barva (soupeř karmínová, ty mosazná), ne jen poloha.
const ENEMY_ACCENT := Color(0.86, 0.3, 0.26)
const PLAYER_ACCENT := Color(0.92, 0.74, 0.36)


# Vrátí kontejner, do kterého patří řada soupeřových karet (ruby).
static func apply(battle: Control) -> Container:
	var top_row := battle.get_node("Margin/Layout/TopRow") as HBoxContainer
	var board_column := battle.get_node("Margin/Layout/TopRow/BoardColumn") as VBoxContainer
	var enemy_header := board_column.get_node("EnemyHeader") as HBoxContainer
	var combat_info := board_column.get_node("CombatInfoPanel") as PanelContainer
	var bottom_bar := battle.get_node("Margin/Layout/BottomBar") as HBoxContainer
	var hand_panel := bottom_bar.get_node("HandPanel") as PanelContainer
	var player_stats := bottom_bar.get_node("PlayerStats") as PanelContainer
	var deck_panel := bottom_bar.get_node("DeckPanel") as PanelContainer
	var discard_panel := bottom_bar.get_node("DiscardPanel") as PanelContainer

	# Levý sloupec.
	var rail := VBoxContainer.new()
	rail.name = "HeroRail"
	rail.custom_minimum_size = Vector2(RAIL_WIDTH, 0)
	rail.clip_contents = true
	rail.add_theme_constant_override("separation", 10)
	top_row.add_child(rail)
	top_row.move_child(rail, 0)

	# Soupeř: portrét přes celou šířku, pod ním jméno, životy a ruka.
	var enemy_box := VBoxContainer.new()
	enemy_box.name = "EnemyHero"
	enemy_box.add_theme_constant_override("separation", 4)
	rail.add_child(_side_panel(enemy_box, ENEMY_ACCENT))
	var portrait := enemy_header.get_node("EnemyPortrait") as Control
	_move(portrait, enemy_box)
	portrait.custom_minimum_size = Vector2(RAIL_WIDTH, HERO_PORTRAIT_HEIGHT)
	var portrait_art := portrait.get_node("PortraitArt") as Control
	portrait_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame := portrait.get_node("PortraitFrame") as TextureRect
	frame.texture = null
	set_portrait_border(frame, ENEMY_ACCENT.darkened(0.3))
	_add_side_tag(portrait, "SOUPEŘ", ENEMY_ACCENT)
	var name_plate := enemy_header.get_node("EnemyNamePlate") as Control
	_move(name_plate, enemy_box)
	name_plate.custom_minimum_size = Vector2(RAIL_WIDTH, 40)
	(name_plate.get_node("NameBanner") as CanvasItem).visible = false
	var name_label := name_plate.get_node("EnemyName") as Label
	name_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var title_font := FontVariation.new()
	title_font.base_font = load("res://assets/fonts/Cinzel-Variable.ttf")
	title_font.variation_opentype = {2003265652: 700}  # wght
	name_label.add_theme_font_override("font", title_font)
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.7))
	var enemy_stats := enemy_header.get_node("EnemyStatsPanel") as Control
	var enemy_row := HBoxContainer.new()
	enemy_row.name = "EnemyStatsRow"
	enemy_row.add_theme_constant_override("separation", 8)
	enemy_box.add_child(enemy_row)
	_move(enemy_stats, enemy_row)
	enemy_stats.custom_minimum_size = Vector2(0, 70)
	enemy_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Ruby soupeřových karet vlastní řádek (vedle životů roztahovaly sloupec).
	var hand_host := HBoxContainer.new()
	hand_host.name = "EnemyHandHost"
	hand_host.alignment = BoxContainer.ALIGNMENT_CENTER
	enemy_box.add_child(hand_host)
	enemy_header.visible = false

	# Hlášení a záznam tahu uprostřed sloupce (dřív pruh přes celou šířku).
	_move(combat_info, rail)
	combat_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	combat_info.custom_minimum_size = Vector2(RAIL_WIDTH, 0)
	# Čitelnost (rozbor: 12–13 px bylo moc malé).
	var info := combat_info.get_node("MarginContainer/InfoVBox")
	(info.get_node("StatusTitle") as Label).add_theme_font_size_override("font_size", 16)
	var status := info.get_node("StatusLabel") as Label
	status.add_theme_font_size_override("font_size", 18)
	# Bez zalamování by dlouhá hláška roztáhla celý sloupec a zúžila stůl.
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.x = 0
	(info.get_node("BattleFeedTitle") as Label).add_theme_font_size_override("font_size", 15)
	var feed := info.get_node("BattleFeed") as RichTextLabel
	feed.add_theme_font_size_override("normal_font_size", 15)
	feed.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Ty: životy a Tuna, pod tím balík a odhazování vedle sebe.
	var player_box := VBoxContainer.new()
	player_box.name = "PlayerHero"
	player_box.add_theme_constant_override("separation", 8)
	rail.add_child(_side_panel(player_box, PLAYER_ACCENT))
	var player_tag := _make_tag("TY", PLAYER_ACCENT)
	player_tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	player_box.add_child(player_tag)
	_move(player_stats, player_box)
	player_stats.custom_minimum_size = Vector2(0, 96)
	var piles := HBoxContainer.new()
	piles.name = "Piles"
	piles.add_theme_constant_override("separation", 8)
	player_box.add_child(piles)
	for pile in [deck_panel, discard_panel]:
		_move(pile, piles)
		pile.custom_minimum_size = Vector2(0, 84)
		pile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_pile_icon(deck_panel.get_node("MarginContainer/VBox/DeckCount") as Label, "icon_deck")
	_add_pile_icon(discard_panel.get_node("MarginContainer/VBox/DiscardCount") as Label, "icon_discard")

	# Ruka pod stolem, jen v šířce stolu.
	_move(hand_panel, board_column)
	hand_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	bottom_bar.visible = false

	_add_board_side_tint(board_column.get_node("BoardPanel") as Control)
	_apply_selected_panel(battle)
	return hand_host


# Panel strany: tmavé pozadí s tenkým barevným okrajem (soupeř nahoře, ty dole).
static func _side_panel(content: Control, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = content.name + "Panel"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r * 0.14, accent.g * 0.1, accent.b * 0.08, 0.82)
	style.border_color = Color(accent, 0.75)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(4)
	panel.add_theme_stylebox_override("panel", style)
	panel.set_meta("accent", accent)
	panel.add_child(content)
	return panel


# Kdo je na tahu: jeho panel svítí plnou barvou, druhý je ztlumený.
static func set_turn_highlight(battle: Control, player_active: bool, enemy_active: bool) -> void:
	var rail := battle.get_node_or_null("Margin/Layout/TopRow/HeroRail")
	if rail == null:
		return
	var pairs := [[rail.get_node_or_null("EnemyHeroPanel"), enemy_active], [rail.get_node_or_null("PlayerHeroPanel"), player_active]]
	for pair in pairs:
		var panel := pair[0] as PanelContainer
		if panel == null:
			continue
		var accent: Color = panel.get_meta("accent", PLAYER_ACCENT)
		var style := (panel.get_theme_stylebox("panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
		var lit: bool = pair[1]
		style.border_color = accent.lightened(0.15) if lit else Color(accent.darkened(0.35), 0.6)
		style.set_border_width_all(3 if lit else 1)
		style.shadow_color = Color(accent, 0.45) if lit else Color(0, 0, 0, 0)
		style.shadow_size = 10 if lit else 0
		panel.add_theme_stylebox_override("panel", style)
	var portrait_frame := rail.get_node_or_null("EnemyHeroPanel/EnemyHero/EnemyPortrait/PortraitFrame") as TextureRect
	if portrait_frame != null:
		set_portrait_border(portrait_frame, ENEMY_ACCENT.lightened(0.1) if enemy_active else ENEMY_ACCENT.darkened(0.3))


static func _make_tag(text: String, accent: Color) -> PanelContainer:
	var tag := PanelContainer.new()
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r * 0.35, accent.g * 0.22, accent.b * 0.16, 0.95)
	style.border_color = accent
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	tag.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.88))
	tag.add_child(label)
	return tag


# Štítek v levém horním rohu portrétu.
static func _add_side_tag(host: Control, text: String, accent: Color) -> void:
	var tag := _make_tag(text, accent)
	tag.position = Vector2(8, 8)
	host.add_child(tag)


# Stůl: soupeřova polovina do karmínova, tvoje do teplé mosazi, střed neutrální.
static func _add_board_side_tint(board_panel: Control) -> void:
	if board_panel == null:
		return
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.46, 0.54, 1.0])
	gradient.colors = PackedColorArray([
		Color(ENEMY_ACCENT, 0.2), Color(ENEMY_ACCENT, 0.0),
		Color(PLAYER_ACCENT, 0.0), Color(PLAYER_ACCENT, 0.14),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	texture.width = 4
	texture.height = 256
	var tint := TextureRect.new()
	tint.name = "SideTint"
	tint.texture = texture
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tint.stretch_mode = TextureRect.STRETCH_SCALE
	board_panel.add_child(tint)
	# Hned za malovaný rám, pod lajny.
	var frame_art := board_panel.get_node_or_null("FrameArt")
	board_panel.move_child(tint, frame_art.get_index() + 1 if frame_art != null else 0)


# Malovaná ikona hromádky (UI arch) vlevo od počtu karet.
static func _add_pile_icon(count_label: Label, icon_name: String) -> void:
	if count_label == null:
		return
	var icon := TextureRect.new()
	icon.texture = load("res://assets/card_game/ui/sheet/%s.png" % icon_name)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.anchor_top = 0.5
	icon.anchor_bottom = 0.5
	icon.offset_left = 4.0
	icon.offset_right = 44.0
	icon.offset_top = -20.0
	icon.offset_bottom = 20.0
	count_label.add_child(icon)


# Pravý panel: velký náhled karty, bez zdvojeného jména a řádku statistik (vše je na kartě).
static func _apply_selected_panel(battle: Control) -> void:
	var content := battle.get_node("Margin/Layout/TopRow/SelectedPanel/Content") as Control
	(content.get_node("TitleBanner") as Control).visible = false
	var top_zone := content.get_node("TopZone") as Control
	top_zone.anchor_bottom = 0.66
	var bottom_zone := content.get_node("BottomZone") as Control
	bottom_zone.anchor_top = 0.68
	top_zone.get_node("SelectedCardView").set_display_mode(&"large")
	var info := bottom_zone.get_node("InfoPanel/MarginContainer/InfoVBox")
	(info.get_node("SelectedMeta") as Control).visible = false
	var detail := info.get_node("SelectedDetail") as RichTextLabel
	detail.add_theme_font_size_override("normal_font_size", 16)
	detail.add_theme_font_size_override("bold_font_size", 16)
	(info.get_node("SelectedHint") as Label).add_theme_font_size_override("font_size", 14)


# Rám portrétu: TextureRect bez textury, okraj kreslí StyleBox přes výchozí panel.
static func set_portrait_border(frame: TextureRect, color: Color) -> void:
	var border := frame.get_node_or_null("Border") as Panel
	if border == null:
		frame.texture = null
		border = Panel.new()
		border.name = "Border"
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		frame.add_child(border)
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = color
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	border.add_theme_stylebox_override("panel", style)


static func _move(node: Node, new_parent: Node) -> void:
	node.get_parent().remove_child(node)
	new_parent.add_child(node)
