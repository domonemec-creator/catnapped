extends RefCounted

# Rozvržení souboje v2 (UI rozbor 2026-10-21): uzly ze scény přeskládá za běhu,
# takže @onready reference v controlleru zůstanou platné.
#   [Levý sloupec: soupeř / hlášení / ty] [Stůl + ruka] [Pravý panel: náhled + tlačítka]

const RAIL_WIDTH := 270.0
const HERO_PORTRAIT_HEIGHT := 150.0


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
	rail.add_child(enemy_box)
	var portrait := enemy_header.get_node("EnemyPortrait") as Control
	_move(portrait, enemy_box)
	portrait.custom_minimum_size = Vector2(RAIL_WIDTH, HERO_PORTRAIT_HEIGHT)
	var portrait_art := portrait.get_node("PortraitArt") as Control
	portrait_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame := portrait.get_node("PortraitFrame") as TextureRect
	frame.texture = null
	set_portrait_border(frame, Color(0.85, 0.68, 0.36))
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
	name_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.6))
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
	rail.add_child(player_box)
	_move(player_stats, player_box)
	player_stats.custom_minimum_size = Vector2(RAIL_WIDTH, 96)
	var piles := HBoxContainer.new()
	piles.name = "Piles"
	piles.add_theme_constant_override("separation", 8)
	player_box.add_child(piles)
	for pile in [deck_panel, discard_panel]:
		_move(pile, piles)
		pile.custom_minimum_size = Vector2(0, 84)
		pile.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Ruka pod stolem, jen v šířce stolu.
	_move(hand_panel, board_column)
	hand_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	bottom_bar.visible = false

	_apply_selected_panel(battle)
	return hand_host


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
