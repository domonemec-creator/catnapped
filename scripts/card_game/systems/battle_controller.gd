class_name BattleController
extends Control

const AiController = preload("res://scripts/card_game/systems/ai_controller.gd")
const BattleRules = preload("res://scripts/card_game/systems/battle_rules.gd")
const BattleState = preload("res://scripts/card_game/runtime/battle_state.gd")
const CardEffect = preload("res://scripts/card_game/data/card_effect.gd")
const CardGameConstants = preload("res://scripts/card_game/data/card_game_constants.gd")
const CardInstance = preload("res://scripts/card_game/runtime/card_instance.gd")
const CardView = preload("res://scripts/card_game/ui/card_view.gd")
const BattleFx = preload("res://scripts/card_game/ui/battle_fx.gd")
const BattleLayout = preload("res://scripts/card_game/ui/battle_layout.gd")
const CardArtCache = preload("res://scripts/card_game/ui/card_art_cache.gd")
const BattleOverlayPresenter = preload("res://scripts/card_game/ui/battle_overlay_presenter.gd")
const BattlePreviewPresenter = preload("res://scripts/card_game/ui/battle_preview_presenter.gd")
const DeckDefinition = preload("res://scripts/card_game/data/deck_definition.gd")
const DeckSystem = preload("res://scripts/card_game/systems/deck_system.gd")
const EncounterDefinition = preload("res://scripts/card_game/data/encounter_definition.gd")
const LaneSlotState = preload("res://scripts/card_game/runtime/lane_slot_state.gd")
const LaneSlotView = preload("res://scripts/card_game/ui/lane_slot_view.gd")
const PlayerBattleState = preload("res://scripts/card_game/runtime/player_battle_state.gd")
const SelectedCardPreview = preload("res://scripts/card_game/ui/selected_card_preview.gd")
const TablePowerDefinition = preload("res://scripts/card_game/data/table_power_definition.gd")

const PLAYER_ID := 0
const ENEMY_ID := 1
const LANE_COUNT := 3
const STARTING_LIFE := 10
# Locked start economy (2026-06-17): 3 Tuna / 3 cards, ramp +1 Tuna/turn to 7.
# Chosen over the old 1 Tuna / 4 cards to fit short, tempo-driven matches with
# turn-1 lane pressure. Same as the prior tested values — only de-debugged.
const STARTING_TUNA := 3
const MAX_TUNA := 7
const STARTING_HAND := 3
const PLAYER_DECK_ID := &"starter_player"
# D-020: Tuna na konci zápasu nemá k čemu sloužit → „Objednat rundu“ (3 Tuny: lízni kartu).
const PLAYER_TABLE_POWER_ID := &"order_round"
const ENCOUNTER_PATH := "res://data/encounters/smug_tabby.tres"
const DEFAULT_ENCOUNTER_ID := &"smug_tabby"
const ENCOUNTER_SELECT_SCENE_PATH := "res://scenes/card_game/encounter_select.tscn"
const TIER_EXTRA_CARD_FROM := 2
# Karta v ruce na výšku (layout v2).
const HAND_CARD_SIZE := Vector2(136, 188)
const CARD_VIEW_SCENE := preload("res://scenes/card_game/card_view.tscn")
const POSTMATCH_VICTORY_EMBLEM_PATH := "res://assets/card_game/ui/postmatch_victory_emblem.png"
const POSTMATCH_DEFEAT_EMBLEM_PATH := "res://assets/card_game/ui/postmatch_defeat_emblem.png"
const POSTMATCH_THREAT_BADGE_PATH := "res://assets/card_game/ui/postmatch_threat_badge.png"
const DEFAULT_POSTMATCH_BACKDROP_PATH := "res://assets/card_game/ui/postmatch_smug_tabby.png"
const POSTMATCH_PANEL_FRAME_PATH := "res://assets/card_game/ui/postmatch_panel_frame.png"
# Enemy portrait frame doubles as a turn indicator: green = player's turn,
# red = enemy's turn, gold = battle over. Transparent-center frames overlay the art.
const PORTRAIT_FRAME_GOLD_PATH := "res://assets/card_game/ui/portrait_frame_gold.png"
const PORTRAIT_FRAME_GREEN_PATH := "res://assets/card_game/ui/portrait_frame_green.png"
const PORTRAIT_FRAME_RED_PATH := "res://assets/card_game/ui/portrait_frame_red.png"
const INFO_ZONE_NONE := &""
const INFO_ZONE_DECK := &"deck"
const INFO_ZONE_DISCARD := &"discard"

@onready var enemy_portrait_art: TextureRect = $Margin/Layout/TopRow/BoardColumn/EnemyHeader/EnemyPortrait/PortraitArt
@onready var enemy_portrait_frame: TextureRect = $Margin/Layout/TopRow/BoardColumn/EnemyHeader/EnemyPortrait/PortraitFrame
@onready var enemy_name_label: Label = $Margin/Layout/TopRow/BoardColumn/EnemyHeader/EnemyNamePlate/EnemyName
@onready var enemy_life_label: Label = $Margin/Layout/TopRow/BoardColumn/EnemyHeader/EnemyStatsPanel/MarginContainer/VBox/EnemyLife
@onready var enemy_tuna_label: Label = $Margin/Layout/TopRow/BoardColumn/EnemyHeader/EnemyStatsPanel/MarginContainer/VBox/EnemyTuna
@onready var combat_info_panel: PanelContainer = $Margin/Layout/TopRow/BoardColumn/CombatInfoPanel
@onready var player_life_label: Label = $Margin/Layout/BottomBar/PlayerStats/MarginContainer/VBox/PlayerLife
@onready var player_tuna_label: Label = $Margin/Layout/BottomBar/PlayerStats/MarginContainer/VBox/PlayerTuna
@onready var deck_panel: PanelContainer = $Margin/Layout/BottomBar/DeckPanel
@onready var deck_count_label: Label = $Margin/Layout/BottomBar/DeckPanel/MarginContainer/VBox/DeckCount
@onready var discard_panel: PanelContainer = $Margin/Layout/BottomBar/DiscardPanel
@onready var discard_count_label: Label = $Margin/Layout/BottomBar/DiscardPanel/MarginContainer/VBox/DiscardCount
@onready var hand_count_label: Label = $Margin/Layout/BottomBar/HandPanel/MarginContainer/VBox/HandHeader/HandCount
@onready var hand_row: HBoxContainer = $Margin/Layout/BottomBar/HandPanel/MarginContainer/VBox/HandCards
@onready var selected_card_view: SelectedCardPreview = $Margin/Layout/TopRow/SelectedPanel/Content/TopZone/SelectedCardView
@onready var selected_card_title: Label = $Margin/Layout/TopRow/SelectedPanel/Content/TitleBanner/SelectedTitle
@onready var selected_card_meta: Label = $Margin/Layout/TopRow/SelectedPanel/Content/BottomZone/InfoPanel/MarginContainer/InfoVBox/SelectedMeta
@onready var selected_card_detail: RichTextLabel = $Margin/Layout/TopRow/SelectedPanel/Content/BottomZone/InfoPanel/MarginContainer/InfoVBox/SelectedDetail
@onready var selected_card_hint: Label = $Margin/Layout/TopRow/SelectedPanel/Content/BottomZone/InfoPanel/MarginContainer/InfoVBox/SelectedHint
@onready var table_power_button: Button = $Margin/Layout/TopRow/SelectedPanel/Content/BottomZone/TablePowerButton
@onready var status_label: Label = $Margin/Layout/TopRow/BoardColumn/CombatInfoPanel/MarginContainer/InfoVBox/StatusLabel
@onready var battle_feed_title: Label = $Margin/Layout/TopRow/BoardColumn/CombatInfoPanel/MarginContainer/InfoVBox/BattleFeedTitle
@onready var battle_feed_label: RichTextLabel = $Margin/Layout/TopRow/BoardColumn/CombatInfoPanel/MarginContainer/InfoVBox/BattleFeed
@onready var end_turn_button: Button = $Margin/Layout/TopRow/SelectedPanel/Content/BottomZone/EndTurnButton
@onready var post_match_overlay: Control = $PostMatchOverlay
@onready var post_match_backdrop_art: TextureRect = $PostMatchOverlay/BackdropArt
@onready var post_match_panel_frame: TextureRect = $PostMatchOverlay/Center/Panel/FrameArt
@onready var post_match_result_emblem: TextureRect = $PostMatchOverlay/Center/Panel/MarginContainer/VBox/ResultEmblem
@onready var post_match_result_title: Label = $PostMatchOverlay/Center/Panel/MarginContainer/VBox/ResultTitle
@onready var post_match_result_summary: Label = $PostMatchOverlay/Center/Panel/MarginContainer/VBox/ResultSummary
@onready var post_match_threat_badge: TextureRect = $PostMatchOverlay/Center/Panel/MarginContainer/VBox/ThreatRow/ThreatBadge
@onready var post_match_threat_summary: Label = $PostMatchOverlay/Center/Panel/MarginContainer/VBox/ThreatRow/ThreatSummary
@onready var post_match_deck_shift_title: Label = $PostMatchOverlay/Center/Panel/MarginContainer/VBox/DeckShiftTitle
@onready var post_match_deck_shift_detail: Label = $PostMatchOverlay/Center/Panel/MarginContainer/VBox/DeckShiftDetail
@onready var post_match_record_label: Label = $PostMatchOverlay/Center/Panel/MarginContainer/VBox/RecordLabel
@onready var post_match_reward_buttons: BoxContainer = $PostMatchOverlay/Center/Panel/MarginContainer/VBox/RewardButtons
@onready var post_match_reward_add_button: Button = $PostMatchOverlay/Center/Panel/MarginContainer/VBox/RewardButtons/RewardAddButton
@onready var post_match_reward_remove_button: Button = $PostMatchOverlay/Center/Panel/MarginContainer/VBox/RewardButtons/RewardRemoveButton
@onready var post_match_reward_upgrade_button: Button = $PostMatchOverlay/Center/Panel/MarginContainer/VBox/RewardButtons/RewardUpgradeButton
@onready var post_match_rematch_button: Button = $PostMatchOverlay/Center/Panel/MarginContainer/VBox/Buttons/RematchButton
@onready var post_match_choose_encounter_button: Button = $PostMatchOverlay/Center/Panel/MarginContainer/VBox/Buttons/ChooseEncounterButton

var _enemy_lanes: Array[LaneSlotView] = []
var _player_lanes: Array[LaneSlotView] = []
# Tempo a efekty: v okně se tah soupeře přehrává po krocích s animacemi, headless (verifiery) synchronně.
var _pace_actions := false
var _enemy_turn_running := false
var _hover_card: CardInstance
var _enemy_hand_host: Container
var _enemy_hand_row: HBoxContainer
# instance_id karet, které už hráč v ruce viděl (nové dostanou animaci líznutí).
var _seen_hand_ids: Dictionary = {}
const ENEMY_ACTION_DELAY := 0.75
var _card_library: Dictionary = {}
var _deck_library: Dictionary = {}
var _table_power_library: Dictionary = {}
var _encounter_library: Dictionary = {}
# Which encounter to start. Empty = default (smug_tabby). Set before _ready()
# (e.g. by a future run system or a capture tool) to start a different NPC.
var startup_encounter_id: StringName = &""
var _encounter: EncounterDefinition
var _battle_state: BattleState
var _selected_card: CardInstance
var _selected_attacker: CardInstance
var _selected_table_power: TablePowerDefinition
var _selected_info_zone: StringName = INFO_ZONE_NONE
var _next_instance_id: int = 1
var _current_reward_offers: Array[Dictionary] = []

var _deck_system := DeckSystem.new()
var _battle_rules := BattleRules.new()
var _ai_controller := AiController.new()
var _overlay_presenter := BattleOverlayPresenter.new()
var _preview_presenter := BattlePreviewPresenter.new()
var _progression_system := ProgressionSystem.new()
var _progression_state: Dictionary = {}
var _player_lane_feedback: Array[Dictionary] = []
var _enemy_lane_feedback: Array[Dictionary] = []
var _battle_feed_lines: Array[String] = []
# Záznam celého zápasu pro zpětnou analýzu lidských testů (user://match_logs/), jen v okně.
var _match_log: Array[String] = []
var _match_log_saved := false
var _last_logged_status_text: String = ""
var _postmatch_victory_emblem_texture: Texture2D
var _postmatch_defeat_emblem_texture: Texture2D
var _postmatch_threat_badge_texture: Texture2D
var _postmatch_smug_tabby_art_texture: Texture2D
var _encounter_backdrop_texture: Texture2D
var _postmatch_panel_frame_texture: Texture2D
var _portrait_frame_gold_texture: Texture2D
var _portrait_frame_green_texture: Texture2D
var _portrait_frame_red_texture: Texture2D
var _combat_info_panel_base_style: StyleBoxFlat


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pace_actions = BattleFx.is_enabled()
	_enemy_hand_host = BattleLayout.apply(self)
	_attach_stat_icon(player_life_label, &"life", Color(0.95, 0.42, 0.38))
	_attach_stat_icon(player_tuna_label, &"tuna", Color(0.55, 0.78, 1.0))
	_attach_stat_icon(enemy_life_label, &"life", Color(0.95, 0.42, 0.38))
	_attach_stat_icon(enemy_tuna_label, &"tuna", Color(0.55, 0.78, 1.0))
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_postmatch_victory_emblem_texture = _load_texture(POSTMATCH_VICTORY_EMBLEM_PATH)
	_postmatch_defeat_emblem_texture = _load_texture(POSTMATCH_DEFEAT_EMBLEM_PATH)
	_postmatch_threat_badge_texture = _load_texture(POSTMATCH_THREAT_BADGE_PATH)
	_postmatch_smug_tabby_art_texture = _load_texture(DEFAULT_POSTMATCH_BACKDROP_PATH)
	_postmatch_panel_frame_texture = _load_texture(POSTMATCH_PANEL_FRAME_PATH)
	post_match_panel_frame.texture = _postmatch_panel_frame_texture
	_portrait_frame_gold_texture = _load_texture(PORTRAIT_FRAME_GOLD_PATH)
	_portrait_frame_green_texture = _load_texture(PORTRAIT_FRAME_GREEN_PATH)
	_portrait_frame_red_texture = _load_texture(PORTRAIT_FRAME_RED_PATH)
	var info_panel_style := combat_info_panel.get_theme_stylebox("panel")
	if info_panel_style is StyleBoxFlat:
		_combat_info_panel_base_style = (info_panel_style as StyleBoxFlat).duplicate() as StyleBoxFlat
	_preview_presenter.set_combat_info_panel_base_style(_combat_info_panel_base_style)

	_overlay_presenter.setup({
		"style_box_builder": Callable(self, "_build_runtime_style_box"),
		"tutorial_dismiss_pressed": Callable(self, "_on_tutorial_dismiss_button_pressed"),
		"progression_system": _progression_system,
		"post_match_overlay": post_match_overlay,
		"post_match_backdrop_art": post_match_backdrop_art,
		"post_match_result_emblem": post_match_result_emblem,
		"post_match_result_title": post_match_result_title,
		"post_match_result_summary": post_match_result_summary,
		"post_match_threat_badge": post_match_threat_badge,
		"post_match_threat_summary": post_match_threat_summary,
		"post_match_deck_shift_title": post_match_deck_shift_title,
		"post_match_deck_shift_detail": post_match_deck_shift_detail,
		"post_match_record_label": post_match_record_label,
		"post_match_reward_buttons": post_match_reward_buttons,
		"post_match_reward_add_button": post_match_reward_add_button,
		"post_match_reward_remove_button": post_match_reward_remove_button,
		"post_match_reward_upgrade_button": post_match_reward_upgrade_button,
		"post_match_rematch_button": post_match_rematch_button,
		"post_match_choose_encounter_button": post_match_choose_encounter_button,
	})
	_preview_presenter.setup({
		"selected_card_view": selected_card_view,
		"selected_card_title": selected_card_title,
		"selected_card_meta": selected_card_meta,
		"selected_card_detail": selected_card_detail,
		"selected_card_hint": selected_card_hint,
		"combat_info_panel": combat_info_panel,
		"status_label": status_label,
		"battle_feed_title": battle_feed_title,
		"battle_rules": _battle_rules,
		"player_id": PLAYER_ID,
		"info_zone_none": INFO_ZONE_NONE,
		"info_zone_deck": INFO_ZONE_DECK,
		"info_zone_discard": INFO_ZONE_DISCARD,
		"get_valid_table_power_lanes": Callable(self, "_get_valid_table_power_lanes"),
		"table_power_requires_lane_selection": Callable(self, "_table_power_requires_lane_selection"),
		"card_requires_board_target": Callable(self, "_card_requires_board_target"),
		"get_valid_card_target_lanes": Callable(self, "_get_valid_card_target_lanes"),
		"card_display_name_from_id": Callable(self, "_card_display_name_from_id"),
	})

	_enemy_lanes = [
		$Margin/Layout/TopRow/BoardColumn/BoardPanel/MarginContainer/VBox/Lanes/Lane0/EnemyLane,
		$Margin/Layout/TopRow/BoardColumn/BoardPanel/MarginContainer/VBox/Lanes/Lane1/EnemyLane,
		$Margin/Layout/TopRow/BoardColumn/BoardPanel/MarginContainer/VBox/Lanes/Lane2/EnemyLane,
	]
	_player_lanes = [
		$Margin/Layout/TopRow/BoardColumn/BoardPanel/MarginContainer/VBox/Lanes/Lane0/PlayerLane,
		$Margin/Layout/TopRow/BoardColumn/BoardPanel/MarginContainer/VBox/Lanes/Lane1/PlayerLane,
		$Margin/Layout/TopRow/BoardColumn/BoardPanel/MarginContainer/VBox/Lanes/Lane2/PlayerLane,
	]

	for lane_index in range(LANE_COUNT):
		_enemy_lanes[lane_index].configure(lane_index, ENEMY_ID, "Soupeř %s" % (lane_index + 1), "Přímý zásah")
		_player_lanes[lane_index].configure(lane_index, PLAYER_ID, "Ty %s" % (lane_index + 1), "Vylož kočku")
		_enemy_lanes[lane_index].slot_pressed.connect(_on_lane_pressed)
		_player_lanes[lane_index].slot_pressed.connect(_on_lane_pressed)
		_enemy_lanes[lane_index].card_dropped.connect(_on_lane_card_dropped)
		_enemy_lanes[lane_index].card_hovered.connect(_on_card_hovered)
		_player_lanes[lane_index].card_hovered.connect(_on_card_hovered)
		_player_lanes[lane_index].card_dropped.connect(_on_lane_card_dropped)

	selected_card_view.set_interactive(false)
	table_power_button.pressed.connect(_on_table_power_button_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	post_match_reward_add_button.pressed.connect(_on_reward_button_pressed.bind(0))
	post_match_reward_remove_button.pressed.connect(_on_reward_button_pressed.bind(1))
	post_match_reward_upgrade_button.pressed.connect(_on_reward_button_pressed.bind(2))
	post_match_rematch_button.pressed.connect(_on_rematch_button_pressed)
	post_match_choose_encounter_button.pressed.connect(_on_choose_encounter_button_pressed)
	_make_children_click_through(deck_panel)
	_make_children_click_through(discard_panel)
	deck_panel.gui_input.connect(_on_info_panel_gui_input.bind(INFO_ZONE_DECK))
	discard_panel.gui_input.connect(_on_info_panel_gui_input.bind(INFO_ZONE_DISCARD))
	_overlay_presenter.ensure_tutorial_overlay(self)

	_load_libraries()
	_setup_battle()
	_refresh_ui()
	_maybe_show_tutorial_overlay()


func _load_libraries() -> void:
	_card_library = _load_resources_by_id("res://data/cards")
	_deck_library = _load_resources_by_id("res://data/decks")
	_table_power_library = _load_resources_by_id("res://data/table_powers")
	_encounter_library = _load_resources_by_id("res://data/encounters")
	_preview_presenter.set_card_library(_card_library)
	var encounter_id: StringName = startup_encounter_id if startup_encounter_id != &"" else DEFAULT_ENCOUNTER_ID
	var run_session = _get_run_session()
	if run_session != null and run_session.is_active():
		var run_encounter_id = run_session.get_current_encounter_id()
		if run_encounter_id != StringName():
			encounter_id = run_encounter_id
	_encounter = _encounter_library.get(encounter_id) as EncounterDefinition
	if _encounter == null:
		_encounter = load(ENCOUNTER_PATH) as EncounterDefinition
	_encounter_backdrop_texture = _load_texture(_get_encounter_portrait_path())
	_progression_state = _progression_system.load_state()


func _create_tutorial_overlay() -> void:
	_overlay_presenter.ensure_tutorial_overlay(self)


func _maybe_show_tutorial_overlay() -> void:
	_overlay_presenter.sync_tutorial_visibility(_progression_state)


func _dismiss_tutorial_overlay(save_progress: bool = true) -> void:
	_progression_state = _overlay_presenter.dismiss_tutorial_overlay(_progression_state, save_progress)


func _on_tutorial_dismiss_button_pressed() -> void:
	_dismiss_tutorial_overlay(true)


func _on_info_panel_gui_input(event: InputEvent, zone_id: StringName) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	_selected_card = null
	_selected_attacker = null
	_selected_table_power = null
	_selected_info_zone = INFO_ZONE_NONE if _selected_info_zone == zone_id else zone_id
	_refresh_ui()


func _get_current_threat() -> int:
	return _progression_system.get_threat_level(_progression_state) + _get_threat_bonus()


# Stupeň obtížnosti soupeře (D-022): v runu krok - 1, v tréninku pořadí v žebříčku.
# Hrozba sama balík mění jen málo (sim), proto stupeň přidává životy a od 3. stupně kartu do ruky.
func _get_difficulty_tier() -> int:
	var run_session = _get_run_session()
	if run_session != null and run_session.is_active():
		return clampi(run_session.get_current_step_number() - 1, 0, ProgressionSystem.TRAINING_ORDER.size() - 1)
	if _encounter != null and CardGameConstants.training_ladder:
		return maxi(0, ProgressionSystem.TRAINING_ORDER.find(_encounter.id))
	return 0


# Hrozba navíc: v runu +1 za každý další krok (D-021), v tréninku podle pořadí soupeře (D-022).
func _get_threat_bonus() -> int:
	var run_session = _get_run_session()
	if run_session != null and run_session.is_active():
		return maxi(0, run_session.get_current_step_number() - 1)
	if _encounter != null and CardGameConstants.training_ladder:
		return _progression_system.get_training_threat_bonus(_encounter.id)
	return 0


# Výhra mimo run posune žebříček tréninku; vrátí jméno nově odemčeného soupeře.
func _record_training_win(state: Dictionary) -> String:
	var run_session = _get_run_session()
	if _encounter == null or (run_session != null and run_session.is_active()):
		return ""
	var unlocked_id := _progression_system.mark_training_win(state, _encounter.id)
	if unlocked_id == StringName():
		return ""
	var unlocked := load("res://data/encounters/%s.tres" % String(unlocked_id)) as EncounterDefinition
	return unlocked.display_name if unlocked != null else String(unlocked_id)


func _build_enemy_header_name(display_name: String) -> String:
	# Hrozbu v hlavičce nahradil žebříček (UI rozbor 2026-10-21); zůstává v tooltipu.
	enemy_name_label.tooltip_text = "Hrozba %s" % _get_current_threat()
	return display_name


func _build_opening_status() -> String:
	# Hrozbu v UI nahradil žebříček tréninku (D-022), interně dál volí sestavu balíku.
	return "Tvůj tah. Vylož kartu na lajnu."


func _get_enemy_deck_id() -> StringName:
	if _encounter == null:
		return StringName()
	return _encounter.deck_id


func _hide_post_match_overlay() -> void:
	_overlay_presenter.hide_post_match_overlay()
	_current_reward_offers.clear()


func _show_post_match_overlay(result_mode: String, result_title: String, result_summary: String, previous_threat: int, next_threat: int, deck_messages: Array[String]) -> void:
	_overlay_presenter.show_post_match_overlay({
		"result_mode": result_mode,
		"result_title": result_title,
		"result_summary": result_summary,
		"previous_threat": previous_threat,
		"next_threat": next_threat,
		"deck_messages": deck_messages,
		"progression_system": _progression_system,
		"progression_state": _progression_state,
		"run_session": _get_run_session(),
		"backdrop_texture": _get_post_match_backdrop_texture(),
		"threat_badge_texture": _postmatch_threat_badge_texture,
		"victory_emblem_texture": _postmatch_victory_emblem_texture,
		"defeat_emblem_texture": _postmatch_defeat_emblem_texture,
	})
	_current_reward_offers = _overlay_presenter.get_reward_offers()


func _card_display_name_from_id(card_id: StringName) -> String:
	var card_definition: CardDefinition = _card_library.get(card_id) as CardDefinition
	if card_definition == null or card_definition.display_name.is_empty():
		return String(card_id)
	return card_definition.display_name


func _build_reward_resolution_text(reward_offer: Dictionary) -> String:
	match str(reward_offer.get("kind", "")):
		"add":
			return "Do finálního balíku přidáno %s." % _card_display_name_from_id(StringName(reward_offer.get("card_id", StringName())))
		"remove":
			return "Z finálního balíku odebráno %s." % _card_display_name_from_id(StringName(reward_offer.get("card_id", StringName())))
		"upgrade":
			return "Finální vylepšení: %s -> %s." % [
				_card_display_name_from_id(StringName(reward_offer.get("from_card_id", StringName()))),
				_card_display_name_from_id(StringName(reward_offer.get("to_card_id", StringName()))),
			]
	return ""


func _show_run_completion_overlay(reward_offer: Dictionary) -> void:
	var run_session = _get_run_session()
	var completion_messages: Array[String] = []
	var reward_text := _build_reward_resolution_text(reward_offer)
	if not reward_text.is_empty():
		completion_messages.append(reward_text)
	if run_session != null:
		completion_messages.append("Balík je uložený. Finální velikost: %s karet." % run_session.get_player_deck_card_ids().size())

	var current_threat := _get_current_threat()
	_show_post_match_overlay(
		"run_complete",
		"Výprava dokončena",
		"Poslední soupeř padl. Tuhle výpravu jsi dotáhl do konce.",
		current_threat,
		current_threat,
		completion_messages
	)
	if not post_match_record_label.text.is_empty():
		post_match_record_label.text += "   HOTOVO"
	status_label.text = "Výprava dokončena. Poslední odměna je uložena."


func _get_encounter_portrait_path() -> String:
	if _encounter != null and not _encounter.portrait_path.is_empty():
		return _encounter.portrait_path
	return DEFAULT_POSTMATCH_BACKDROP_PATH


func _get_post_match_backdrop_texture() -> Texture2D:
	if _encounter_backdrop_texture != null:
		return _encounter_backdrop_texture
	return _postmatch_smug_tabby_art_texture


func _load_texture(resource_path: String) -> Texture2D:
	if resource_path.is_empty():
		return null
	var texture := load(resource_path) as Texture2D
	if texture == null:
		push_warning("Could not load texture from %s." % resource_path)
		return null
	return texture


func _clear_selection_state() -> void:
	_selected_card = null
	_selected_attacker = null
	_selected_table_power = null
	_selected_info_zone = INFO_ZONE_NONE


func _build_empty_lane_feedback() -> Array[Dictionary]:
	var lane_feedback: Array[Dictionary] = []
	for _lane_index in range(LANE_COUNT):
		lane_feedback.append({"text": "", "tone": LaneSlotView.EVENT_NEUTRAL})
	return lane_feedback


func _reset_lane_feedback() -> void:
	_player_lane_feedback = _build_empty_lane_feedback()
	_enemy_lane_feedback = _build_empty_lane_feedback()


func _clear_lane_feedback() -> void:
	if _player_lane_feedback.size() != LANE_COUNT or _enemy_lane_feedback.size() != LANE_COUNT:
		_reset_lane_feedback()
		return

	for lane_index in range(LANE_COUNT):
		_player_lane_feedback[lane_index] = {"text": "", "tone": LaneSlotView.EVENT_NEUTRAL}
		_enemy_lane_feedback[lane_index] = {"text": "", "tone": LaneSlotView.EVENT_NEUTRAL}


func _get_lane_feedback(owner_id: int) -> Array[Dictionary]:
	return _player_lane_feedback if owner_id == PLAYER_ID else _enemy_lane_feedback


func _set_lane_feedback(owner_id: int, lane_index: int, text: String, tone: StringName = LaneSlotView.EVENT_NEUTRAL) -> void:
	var lane_feedback := _get_lane_feedback(owner_id)
	if lane_index < 0 or lane_index >= lane_feedback.size():
		return
	lane_feedback[lane_index] = {"text": text, "tone": tone}


func _set_lane_feedback_for_card(card_instance: CardInstance, text: String, tone: StringName) -> void:
	if card_instance == null or card_instance.lane_index < 0:
		return
	_set_lane_feedback(card_instance.owner_id, card_instance.lane_index, text, tone)


func _format_signed_stat_delta(value: int, stat_name: String) -> String:
	var prefix := "+" if value >= 0 else ""
	return "%s%s %s" % [prefix, value, stat_name]


func _reset_battle_feed() -> void:
	_battle_feed_lines.clear()
	_last_logged_status_text = ""
	if battle_feed_label != null:
		battle_feed_label.text = "Zatím bez akce."


func _should_log_status(message: String) -> bool:
	var trimmed := message.strip_edges()
	var lowered := trimmed.to_lower()
	if trimmed.is_empty():
		return false
	if trimmed.begins_with("Hrozba "):
		return false
	if lowered.find("vybráno") >= 0 or lowered.find("útočník:") >= 0:
		return false
	if lowered.find("výběr") >= 0 and lowered.find("zrušen") >= 0:
		return false
	if lowered.find("klikni") >= 0:
		return false
	if lowered.find("přetáhni kartu") >= 0:
		return false
	if lowered.find("jsi na tahu") >= 0:
		return false
	return true


func _sync_battle_feed() -> void:
	if battle_feed_label == null or status_label == null:
		return

	var status_text := status_label.text.strip_edges()
	if status_text.is_empty() or status_text == _last_logged_status_text:
		return

	_last_logged_status_text = status_text
	if not _should_log_status(status_text):
		return

	_battle_feed_lines.append(status_text)
	_log_match_line(status_text)
	while _battle_feed_lines.size() > 4:
		_battle_feed_lines.remove_at(0)
	battle_feed_label.text = "\n".join(_battle_feed_lines)


# Nedohraný zápas (zavření okna, odchod do menu) se uloží taky, ať jde lidský test zpětně projít.
func _exit_tree() -> void:
	if not _match_log.is_empty() and not _match_log_saved:
		_log_board_snapshot("Zápas přerušen")
		_save_match_log("nedohrano")


func _log_match_line(text: String) -> void:
	if not _pace_actions or _battle_state == null:
		return
	var p: PlayerBattleState = _battle_state.get_player_state(PLAYER_ID)
	var e: PlayerBattleState = _battle_state.get_player_state(ENEMY_ID)
	if p == null or e == null:
		return
	_match_log.append("[kolo %s | hráč %s ŽIV, ruka %s, Tuna %s/%s | soupeř %s ŽIV, ruka %s] %s" % [_battle_state.turn_number, p.life, p.hand.size(), p.tuna_current, p.tuna_max, e.life, e.hand.size(), text])


func _log_board_snapshot(label: String) -> void:
	if not _pace_actions or _battle_state == null:
		return
	var parts: Array[String] = []
	for owner in [ENEMY_ID, PLAYER_ID]:
		var state: PlayerBattleState = _battle_state.get_player_state(owner)
		var lanes: Array[String] = []
		for slot in state.board:
			lanes.append("-" if slot.occupant == null else "%s %s/%s" % [slot.occupant.definition.display_name, slot.occupant.current_attack, slot.occupant.current_life])
		parts.append(("Soupeř: " if owner == ENEMY_ID else "Hráč: ") + " | ".join(lanes))
	_log_match_line("%s — %s" % [label, " || ".join(parts)])


func _save_match_log(result: String) -> void:
	if not _pace_actions or _match_log_saved:
		return
	_match_log_saved = true
	DirAccess.make_dir_recursive_absolute("user://match_logs")
	var enemy_id := String(_encounter.id) if _encounter != null else "unknown"
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var file := FileAccess.open("user://match_logs/%s_%s_%s.txt" % [stamp, enemy_id, result], FileAccess.WRITE)
	if file == null:
		return
	file.store_line("Catnapped! záznam zápasu | soupeř %s | výsledek %s | kol %s | odveta=%s ruka=%s" % [enemy_id, result, _battle_state.turn_number, CardGameConstants.combat_retaliation, CardGameConstants.starting_hand])
	for line in _match_log:
		file.store_line(line)


func _get_table_power_definition(player_state: PlayerBattleState) -> TablePowerDefinition:
	if player_state == null or player_state.table_power_id == StringName():
		return null
	return _table_power_library.get(player_state.table_power_id) as TablePowerDefinition


func _table_power_requires_lane_selection(power_definition: TablePowerDefinition) -> bool:
	if power_definition == null:
		return false

	for effect in power_definition.effects:
		var typed_effect: CardEffect = effect
		if typed_effect != null and typed_effect.action == &"summon_token":
			return true

	return false


func _can_use_table_power(player_state: PlayerBattleState, power_definition: TablePowerDefinition) -> bool:
	if player_state == null or power_definition == null:
		return false
	if player_state.table_power_used_this_turn:
		return false
	if player_state.tuna_current < power_definition.cost:
		return false
	if _table_power_requires_lane_selection(power_definition):
		return not _get_valid_table_power_lanes(power_definition, player_state).is_empty()
	# Líznutí z prázdného balíku by spustilo Hlad (sebepoškození); takovou sílu nepustit.
	for effect in power_definition.effects:
		if effect != null and effect.action == &"draw_cards" and player_state.deck.is_empty():
			return false
	return true


func _get_valid_table_power_lanes(power_definition: TablePowerDefinition, player_state: PlayerBattleState) -> Array[int]:
	var valid_lanes: Array[int] = []
	if player_state == null or power_definition == null:
		return valid_lanes

	if not _table_power_requires_lane_selection(power_definition):
		return valid_lanes

	for slot in player_state.board:
		if slot != null and slot.is_empty():
			valid_lanes.append(slot.lane_index)

	return valid_lanes


func _create_card_instance(card_id: StringName, owner_id: int) -> CardInstance:
	var card_definition := _card_library.get(card_id) as CardDefinition
	if card_definition == null:
		push_warning("Missing card definition for token %s." % card_id)
		return null

	var instance := CardInstance.new()
	instance.instance_id = _next_instance_id
	_next_instance_id += 1
	instance.definition = card_definition
	instance.owner_id = owner_id
	instance.current_attack = card_definition.attack
	instance.current_life = card_definition.life
	instance.can_attack = false
	instance.has_attacked = false
	return instance


func _reset_card_instance_runtime_state(card_instance: CardInstance) -> void:
	if card_instance == null or card_instance.definition == null:
		return
	card_instance.current_attack = card_instance.definition.attack
	card_instance.current_life = card_instance.definition.life
	card_instance.lane_index = -1
	card_instance.can_attack = false
	card_instance.has_attacked = false
	card_instance.entered_this_turn = false
	card_instance.immediate_entry_attack_granted = false
	card_instance.attached_item_instance_id = -1
	card_instance.attached_item = null
	card_instance.temporary_attack_bonus = 0
	card_instance.temporary_life_bonus = 0
	card_instance.temporary_keywords.clear()
	card_instance.granted_keywords.clear()


func _clear_end_of_turn_modifiers(player_state: PlayerBattleState) -> void:
	if player_state == null:
		return
	player_state.immediate_entry_attack_used_this_turn = false
	for slot in player_state.board:
		if slot == null or slot.occupant == null:
			continue
		var occupant := slot.occupant
		occupant.entered_this_turn = false
		occupant.immediate_entry_attack_granted = false
		if occupant.temporary_attack_bonus != 0:
			occupant.current_attack = maxi(0, occupant.current_attack - occupant.temporary_attack_bonus)
			occupant.temporary_attack_bonus = 0
		if occupant.temporary_life_bonus != 0:
			_adjust_card_life(occupant, -occupant.temporary_life_bonus)
			occupant.temporary_life_bonus = 0
	_resolve_deaths(player_state)
	_check_battle_end()


func _card_requires_board_target(card_instance: CardInstance) -> bool:
	if card_instance == null or card_instance.definition == null:
		return false
	if card_instance.definition.card_type == CardGameConstants.CardType.CAT:
		return false

	for effect in card_instance.definition.effects:
		var typed_effect: CardEffect = effect
		if typed_effect == null:
			continue
		if typed_effect.target_mode == CardGameConstants.TARGET_ALLY_CAT:
			return true
		if typed_effect.target_mode == CardGameConstants.TARGET_ENEMY_CAT:
			return true
		if typed_effect.target_mode == CardGameConstants.TARGET_ANY_CAT:
			return true

	return false


func _card_targets_friendly_lane(card_instance: CardInstance) -> bool:
	if card_instance == null:
		return false
	for effect in card_instance.definition.effects:
		var typed_effect: CardEffect = effect
		if typed_effect == null:
			continue
		if typed_effect.target_mode == CardGameConstants.TARGET_ALLY_CAT:
			return true
		if typed_effect.target_mode == CardGameConstants.TARGET_ANY_CAT:
			return true
	return false


func _card_targets_enemy_lane(card_instance: CardInstance) -> bool:
	if card_instance == null:
		return false
	for effect in card_instance.definition.effects:
		var typed_effect: CardEffect = effect
		if typed_effect == null:
			continue
		if typed_effect.target_mode == CardGameConstants.TARGET_ENEMY_CAT:
			return true
		if typed_effect.target_mode == CardGameConstants.TARGET_ANY_CAT:
			return true
	return false


func _get_valid_card_target_lanes(card_instance: CardInstance, friendly_state: PlayerBattleState, enemy_state: PlayerBattleState, target_owner_id: int) -> Array[int]:
	return _battle_rules.get_valid_card_target_lanes(card_instance, friendly_state, enemy_state, target_owner_id)


func _is_valid_card_target(card_instance: CardInstance, target_card: CardInstance, target_owner_id: int, friendly_state: PlayerBattleState, enemy_state: PlayerBattleState) -> bool:
	return _battle_rules.is_valid_card_target(card_instance, target_card, target_owner_id, friendly_state, enemy_state)


func _can_play_card_from_hand(card_instance: CardInstance, player_state: PlayerBattleState, enemy_state: PlayerBattleState) -> bool:
	if card_instance == null or player_state == null or enemy_state == null:
		return false
	if not _battle_rules.can_pay_card_cost(card_instance, player_state):
		return false

	match card_instance.definition.card_type:
		CardGameConstants.CardType.CAT:
			return not _battle_rules.get_valid_play_lanes(card_instance, player_state).is_empty()
		CardGameConstants.CardType.TRICK, CardGameConstants.CardType.ITEM:
			if not _card_requires_board_target(card_instance):
				return true
			var valid_friendly_targets := _get_valid_card_target_lanes(card_instance, player_state, enemy_state, player_state.player_id)
			var valid_enemy_targets := _get_valid_card_target_lanes(card_instance, player_state, enemy_state, enemy_state.player_id)
			return not valid_friendly_targets.is_empty() or not valid_enemy_targets.is_empty()

	return false


func _build_card_selection_message(card_instance: CardInstance, player_state: PlayerBattleState, enemy_state: PlayerBattleState) -> String:
	if card_instance == null or card_instance.definition == null:
		return "Výběr z ruky zrušen."

	var display_name := card_instance.definition.display_name
	if not _battle_rules.can_pay_card_cost(card_instance, player_state):
		return "%s vybraná, ale nemáš dost Tuny." % display_name
	match card_instance.definition.card_type:
		CardGameConstants.CardType.CAT:
			if _battle_rules.get_valid_play_lanes(card_instance, player_state).is_empty():
				return "%s vybraná, ale není volná lajna." % display_name
			return "%s vybraná. Klikni na volnou lajnu." % display_name
		CardGameConstants.CardType.TRICK, CardGameConstants.CardType.ITEM:
			if not _card_requires_board_target(card_instance):
				return "%s vybraná. Efekt se spustí hned." % display_name

			var valid_friendly_targets := _get_valid_card_target_lanes(card_instance, player_state, enemy_state, player_state.player_id)
			var valid_enemy_targets := _get_valid_card_target_lanes(card_instance, player_state, enemy_state, enemy_state.player_id)
			if valid_friendly_targets.is_empty() and valid_enemy_targets.is_empty():
				return "%s vybraná, ale na stole není cíl." % display_name
			if not valid_friendly_targets.is_empty() and not valid_enemy_targets.is_empty():
				return "%s vybraná. Klikni na kočku." % display_name
			if not valid_friendly_targets.is_empty():
				return "%s vybraná. Klikni na svou kočku." % display_name
			return "%s vybraná. Klikni na nepřátelskou kočku." % display_name

	return "Vybráno: %s." % display_name


func _resolve_instant_card_effects(card_instance: CardInstance, owner_state: PlayerBattleState, opposing_state: PlayerBattleState, target_card: CardInstance) -> Array[String]:
	var summaries: Array[String] = []
	for effect in card_instance.definition.effects:
		var typed_effect: CardEffect = effect
		if typed_effect == null:
			continue

		match typed_effect.action:
			&"modify_attack":
				if target_card == null:
					continue
				target_card.current_attack += typed_effect.value
				_set_lane_feedback_for_card(target_card, _format_signed_stat_delta(typed_effect.value, "ÚTK"), LaneSlotView.EVENT_SUPPORT if typed_effect.value >= 0 else LaneSlotView.EVENT_DAMAGE)
				if typed_effect.value_2 > 0:
					target_card.temporary_attack_bonus += typed_effect.value
					summaries.append("%s získa +%s útoku do konce kola." % [target_card.definition.display_name, typed_effect.value])
				else:
					summaries.append("%s získa +%s útoku." % [target_card.definition.display_name, typed_effect.value])
			&"modify_life":
				if target_card == null:
					continue
				_adjust_card_life(target_card, typed_effect.value)
				_set_lane_feedback_for_card(target_card, _format_signed_stat_delta(typed_effect.value, "ŽIV"), LaneSlotView.EVENT_SUPPORT if typed_effect.value >= 0 else LaneSlotView.EVENT_DAMAGE)
				if typed_effect.value_2 > 0:
					target_card.temporary_life_bonus += typed_effect.value
					summaries.append("%s získa +%s životů do konce kola." % [target_card.definition.display_name, typed_effect.value])
				else:
					summaries.append("%s získa +%s životů." % [target_card.definition.display_name, typed_effect.value])
			&"deal_damage":
				if target_card == null:
					continue
				_adjust_card_life(target_card, -typed_effect.value)
				_set_lane_feedback_for_card(target_card, "-%s ŽIV" % typed_effect.value, LaneSlotView.EVENT_DAMAGE)
				summaries.append("%s dostane %s zranění." % [target_card.definition.display_name, typed_effect.value])
			&"ready_attack":
				if target_card == null:
					continue
				if target_card.entered_this_turn and not target_card.immediate_entry_attack_granted:
					summaries.append("%s tenhle tah ještě nezaútočí." % target_card.definition.display_name)
					continue
				target_card.can_attack = true
				target_card.has_attacked = false
				_set_lane_feedback_for_card(target_card, "ZNOVU PŘIPR.", LaneSlotView.EVENT_SUPPORT)
				summaries.append("%s může znovu útočit." % target_card.definition.display_name)
			&"return_to_hand":
				if target_card == null:
					continue
				var target_owner_state := owner_state if target_card.owner_id == owner_state.player_id else opposing_state
				if target_owner_state == null:
					continue
				var returned_name := target_card.definition.display_name
				_return_card_to_hand(target_owner_state, target_card)
				summaries.append("%s se vrací do ruky." % returned_name)
			&"draw_cards":
				if typed_effect.target_mode == CardGameConstants.TARGET_SELF_OWNER:
					_deck_system.draw_cards(owner_state, typed_effect.value)
					summaries.append("%s táhne %s kart%s." % [owner_state.display_name, typed_effect.value, "u" if typed_effect.value == 1 else "y"])
			&"heal_life":
				if typed_effect.target_mode == CardGameConstants.TARGET_SELF_OWNER:
					_adjust_player_life(owner_state, typed_effect.value)
					summaries.append("%s vyléčí %s životů." % [owner_state.display_name, typed_effect.value])
			&"steal_item":
				if target_card == null or target_card.attached_item == null:
					continue
				var steal_host := _find_item_steal_host(owner_state)
				if steal_host == null:
					continue
				var stolen_item := target_card.attached_item
				_modify_host_by_item(stolen_item, target_card, -1)
				target_card.attached_item = null
				target_card.attached_item_instance_id = -1
				_modify_host_by_item(stolen_item, steal_host, 1)
				steal_host.attached_item = stolen_item
				steal_host.attached_item_instance_id = stolen_item.instance_id
				stolen_item.owner_id = owner_state.player_id
				_set_lane_feedback_for_card(target_card, "PŘEDMĚT PRYČ", LaneSlotView.EVENT_DAMAGE)
				_set_lane_feedback_for_card(steal_host, "PŘEDMĚT UKRADEN", LaneSlotView.EVENT_SUPPORT)
				summaries.append("%s ukradne %s pro %s." % [owner_state.display_name, stolen_item.definition.display_name, steal_host.definition.display_name])
			&"destroy_item":
				if target_card == null or target_card.attached_item == null:
					continue
				var wrecked_item := target_card.attached_item
				_modify_host_by_item(wrecked_item, target_card, -1)
				target_card.attached_item = null
				target_card.attached_item_instance_id = -1
				opposing_state.discard.append(wrecked_item)
				_set_lane_feedback_for_card(target_card, "PŘEDMĚT PRYČ", LaneSlotView.EVENT_DAMAGE)
				summaries.append("%s strhne %s z %s." % [owner_state.display_name, wrecked_item.definition.display_name, target_card.definition.display_name])
			&"grant_keyword":
				if target_card == null or typed_effect.keyword_arg == StringName():
					continue
				if not target_card.granted_keywords.has(typed_effect.keyword_arg):
					target_card.granted_keywords.append(typed_effect.keyword_arg)
				_set_lane_feedback_for_card(target_card, "+%s" % CardGameConstants.keyword_label(typed_effect.keyword_arg).to_upper(), LaneSlotView.EVENT_SUPPORT)
				summaries.append("%s získá %s." % [target_card.definition.display_name, CardGameConstants.keyword_label(typed_effect.keyword_arg)])

	return summaries


func _modify_host_by_item(item: CardInstance, host: CardInstance, sign: int) -> void:
	if item == null or item.definition == null or host == null:
		return
	for effect in item.definition.effects:
		var typed_effect: CardEffect = effect
		if typed_effect == null:
			continue
		match typed_effect.action:
			&"modify_attack":
				host.current_attack = maxi(0, host.current_attack + sign * typed_effect.value)
			&"modify_life":
				_adjust_card_life(host, sign * typed_effect.value)
			&"grant_keyword":
				if typed_effect.keyword_arg == StringName():
					continue
				if sign > 0:
					if not host.granted_keywords.has(typed_effect.keyword_arg):
						host.granted_keywords.append(typed_effect.keyword_arg)
				else:
					host.granted_keywords.erase(typed_effect.keyword_arg)


func _find_item_steal_host(owner_state: PlayerBattleState) -> CardInstance:
	if owner_state == null:
		return null
	for slot in owner_state.board:
		if slot != null and slot.occupant != null and slot.occupant.attached_item == null:
			return slot.occupant
	return null


func _return_card_to_hand(owner_state: PlayerBattleState, target_card: CardInstance) -> void:
	if owner_state == null or target_card == null or target_card.lane_index < 0:
		return
	var lane_index := target_card.lane_index
	if lane_index >= 0 and lane_index < owner_state.board.size():
		owner_state.board[lane_index].occupant = null
		_set_lane_feedback(owner_state.player_id, lane_index, "VRÁCENO", LaneSlotView.EVENT_SUPPORT)
	if target_card.attached_item != null:
		owner_state.discard.append(target_card.attached_item)
	_reset_card_instance_runtime_state(target_card)
	owner_state.hand.append(target_card)


func _play_targeted_card(owner_state: PlayerBattleState, opposing_state: PlayerBattleState, card_instance: CardInstance, target_card: CardInstance) -> String:
	if owner_state == null or opposing_state == null or card_instance == null:
		return ""

	_clear_lane_feedback()
	_spend_card_cost(card_instance, owner_state)
	owner_state.hand.erase(card_instance)

	var lines: Array[String] = ["%s hraje %s." % [owner_state.display_name, card_instance.definition.display_name]]
	var is_item := card_instance.definition.card_type == CardGameConstants.CardType.ITEM
	if is_item and target_card != null:
		# Equip persistently: the item lives on the cat so it can later be stolen or destroyed.
		target_card.attached_item = card_instance
		target_card.attached_item_instance_id = card_instance.instance_id
	lines.append_array(_resolve_instant_card_effects(card_instance, owner_state, opposing_state, target_card))
	if not (is_item and target_card != null):
		owner_state.discard.append(card_instance)

	_resolve_deaths(owner_state)
	_resolve_deaths(opposing_state)
	_check_battle_end()
	return " ".join(lines)


func _activate_table_power(user_state: PlayerBattleState, opposing_state: PlayerBattleState, power_definition: TablePowerDefinition, lane_index: int = -1) -> String:
	if user_state == null or power_definition == null:
		return "Žádná Síla stolu."
	if not _can_use_table_power(user_state, power_definition):
		return "%s teď nejde použít." % power_definition.display_name
	if _table_power_requires_lane_selection(power_definition) and not _get_valid_table_power_lanes(power_definition, user_state).has(lane_index):
		return "Sem %s nejde." % power_definition.display_name

	_clear_lane_feedback()
	user_state.tuna_current -= power_definition.cost
	user_state.table_power_used_this_turn = true

	var lines: Array[String] = ["%s použije %s." % [user_state.display_name, power_definition.display_name]]
	for effect in power_definition.effects:
		var typed_effect: CardEffect = effect
		if typed_effect == null:
			continue
		var effect_summary := _resolve_table_power_effect(user_state, opposing_state, typed_effect, lane_index)
		if not effect_summary.is_empty():
			lines.append(effect_summary)

	_check_battle_end()
	return " ".join(lines)


func _resolve_table_power_effect(user_state: PlayerBattleState, opposing_state: PlayerBattleState, effect: CardEffect, lane_index: int) -> String:
	match effect.action:
		&"summon_token":
			if effect.target_mode != CardGameConstants.TARGET_SELF_OWNER:
				return ""
			var slot: LaneSlotState = user_state.board[lane_index]
			if slot == null or not slot.is_empty():
				return ""
			var token_instance := _create_card_instance(effect.keyword_arg, user_state.player_id)
			if token_instance == null:
				return ""
			token_instance.lane_index = lane_index
			token_instance.entered_this_turn = true
			token_instance.immediate_entry_attack_granted = false
			token_instance.has_attacked = false
			token_instance.can_attack = false
			slot.occupant = token_instance
			_set_lane_feedback(user_state.player_id, lane_index, "VYVOLÁNO", LaneSlotView.EVENT_SUPPORT)
			return "%s jde do lajny %s." % [token_instance.definition.display_name, lane_index + 1]
		&"reveal_random_hand_card":
			var target_state := opposing_state if effect.target_mode == CardGameConstants.TARGET_ENEMY_PLAYER else user_state
			if target_state == null or target_state.hand.is_empty():
				return "Není co odhalit."
			var reveal_index := randi() % target_state.hand.size()
			var revealed_card: CardInstance = target_state.hand[reveal_index]
			return "Odhalí %s." % revealed_card.definition.display_name
		&"heal_life":
			if effect.target_mode == CardGameConstants.TARGET_SELF_OWNER:
				_adjust_player_life(user_state, effect.value)
				return "Vyléčí %s životů." % effect.value
		&"draw_cards":
			if effect.target_mode == CardGameConstants.TARGET_SELF_OWNER:
				_draw_or_starve(user_state, effect.value)
				_play_sfx(&"card_draw")
				return "Objednává rundu a líže %s kartu." % effect.value

	return ""


func _setup_battle() -> void:
	_hide_post_match_overlay()
	_reset_battle_feed()
	_reset_lane_feedback()
	_battle_state = BattleState.new()
	_battle_state.turn_number = 1
	_battle_state.active_player_id = PLAYER_ID
	_battle_state.priority_player_id = PLAYER_ID

	var player_state := PlayerBattleState.new()
	player_state.initialize(PLAYER_ID, "Hráč", STARTING_LIFE, STARTING_TUNA, PLAYER_TABLE_POWER_ID, LANE_COUNT)
	# The player's first turn is the opening setup (no _start_turn call), so their next
	# _start_turn (turn 2) should ramp normally. The enemy keeps has_started_turn = false
	# so its first turn opens on STARTING_TUNA instead of an unfair +1.
	player_state.has_started_turn = true

	var enemy_state := PlayerBattleState.new()
	var enemy_name := "Soupeř"
	var enemy_life := STARTING_LIFE
	var enemy_power_id := StringName()
	var enemy_deck_id := StringName()
	if _encounter != null:
		enemy_name = _encounter.npc_name
		enemy_life = _encounter.starting_life + ProgressionSystem.get_training_life_bonus(_get_difficulty_tier())
		enemy_power_id = _encounter.table_power_id
		enemy_deck_id = _encounter.deck_id
	enemy_state.initialize(ENEMY_ID, enemy_name, enemy_life, STARTING_TUNA, enemy_power_id, LANE_COUNT)

	_next_instance_id = _assign_deck_to_player(player_state, PLAYER_DECK_ID, _next_instance_id)
	_next_instance_id = _assign_deck_to_player(enemy_state, enemy_deck_id, _next_instance_id)

	_battle_state.player_states = [player_state, enemy_state]

	_deck_system.draw_cards(player_state, CardGameConstants.starting_hand)
	_deck_system.draw_cards(enemy_state, CardGameConstants.starting_hand + (1 if _get_difficulty_tier() >= TIER_EXTRA_CARD_FROM else 0))

	enemy_name_label.text = _build_enemy_header_name(enemy_state.display_name)
	# Portrét v levém sloupci: výřez na hlavu podle poměru stran rámu.
	var portrait_path := _get_encounter_portrait_path()
	var portrait_full := CardArtCache.get_full(portrait_path)
	var portrait_top := 0.06 if portrait_full != null and portrait_full.get_height() > portrait_full.get_width() else 0.0
	enemy_portrait_art.texture = CardArtCache.get_cropped_aspect(portrait_path, BattleLayout.RAIL_WIDTH / BattleLayout.HERO_PORTRAIT_HEIGHT, portrait_top)
	status_label.text = _build_opening_status()


func _assign_deck_to_player(player_state: PlayerBattleState, deck_id: StringName, next_instance_id: int) -> int:
	var deck_definition: DeckDefinition = _deck_library.get(deck_id)
	if deck_definition == null:
		push_warning("Missing deck %s." % deck_id)
		return next_instance_id

	var result: Dictionary = {}
	if player_state.player_id == ENEMY_ID:
		# Hrozba včetně bonusu runu (D-021) / tréninku (D-022).
		var threat_deck_cards := _progression_system.build_enemy_deck_card_ids(deck_definition, _get_current_threat())
		result = _deck_system.build_runtime_deck_from_card_ids(threat_deck_cards, _card_library, player_state.player_id, next_instance_id)
	else:
		var run_session = _get_run_session()
		if run_session != null and run_session.is_active():
			var run_deck_card_ids: Array[StringName] = run_session.get_player_deck_card_ids()
			if not run_deck_card_ids.is_empty():
				result = _deck_system.build_runtime_deck_from_card_ids(run_deck_card_ids, _card_library, player_state.player_id, next_instance_id)
			else:
				result = _deck_system.build_runtime_deck(deck_definition, _card_library, player_state.player_id, next_instance_id)
		else:
			var saved_deck_card_ids: Array[StringName] = _progression_system.get_player_deck_card_ids(_progression_state)
			if not saved_deck_card_ids.is_empty():
				result = _deck_system.build_runtime_deck_from_card_ids(saved_deck_card_ids, _card_library, player_state.player_id, next_instance_id)
			else:
				result = _deck_system.build_runtime_deck(deck_definition, _card_library, player_state.player_id, next_instance_id)
	player_state.deck = result["cards"]
	return int(result["next_instance_id"])


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


func _on_lane_pressed(lane_index: int, owner_id: int) -> void:
	if _battle_state == null or _battle_state.battle_over or _battle_state.active_player_id != PLAYER_ID:
		return

	if owner_id == PLAYER_ID:
		_handle_player_lane_pressed(lane_index)
	else:
		_handle_enemy_lane_pressed(lane_index)

	_refresh_ui()


func _handle_player_lane_pressed(lane_index: int) -> void:
	var player_state: PlayerBattleState = _battle_state.get_player_state(PLAYER_ID)
	if player_state == null:
		return

	if _selected_table_power != null:
		_selected_info_zone = INFO_ZONE_NONE
		var enemy_state := _battle_state.get_enemy_state(PLAYER_ID)
		var valid_power_lanes := _get_valid_table_power_lanes(_selected_table_power, player_state)
		if valid_power_lanes.has(lane_index):
			status_label.text = _activate_table_power(player_state, enemy_state, _selected_table_power, lane_index)
			_selected_table_power = null
			return
		status_label.text = "Sem %s nejde." % _selected_table_power.display_name
		return

	if _selected_card != null:
		_selected_info_zone = INFO_ZONE_NONE
		var enemy_state := _battle_state.get_enemy_state(PLAYER_ID)
		if _selected_card.definition.card_type == CardGameConstants.CardType.CAT:
			var valid_play_lanes: Array[int] = _battle_rules.get_valid_play_lanes(_selected_card, player_state)
			if valid_play_lanes.has(lane_index):
				_play_card_to_lane(player_state, lane_index, _selected_card)
				_selected_card = null
				_selected_attacker = null
				return
			# Důvod, ne jen „nejde“ (lidský test).
			if player_state.board[lane_index].occupant != null:
				status_label.text = "Lajna %s je obsazená. Vylož %s na volné místo." % [lane_index + 1, _selected_card.definition.display_name]
			elif _selected_card.definition.cost > player_state.tuna_current:
				status_label.text = "%s stojí %s Tuny, máš jen %s." % [_selected_card.definition.display_name, _selected_card.definition.cost, player_state.tuna_current]
			else:
				status_label.text = "Sem %s nejde." % _selected_card.definition.display_name
			return

		var slot: LaneSlotState = player_state.board[lane_index]
		if slot != null and slot.occupant != null and _is_valid_card_target(_selected_card, slot.occupant, player_state.player_id, player_state, enemy_state):
			status_label.text = _play_targeted_card(player_state, enemy_state, _selected_card, slot.occupant)
			_clear_selection_state()
			return

		status_label.text = "Tohle není cíl pro %s." % _selected_card.definition.display_name
		return

	var slot: LaneSlotState = player_state.board[lane_index]
	if slot == null or slot.occupant == null:
		_selected_attacker = null
		status_label.text = "Prázdno. Vyber kartu nebo připravenou kočku."
		return

	if not slot.occupant.can_attack or slot.occupant.has_attacked:
		_selected_attacker = null
		# Lidský test: hráč 8× zkoušel útočit čerstvou kočkou. Hláška musí říct proč.
		var cat_name := slot.occupant.definition.display_name
		if slot.occupant.has_attacked:
			status_label.text = "%s už v tomhle kole útočila. Další útok příští kolo." % cat_name
		elif slot.occupant.entered_this_turn:
			status_label.text = "%s je na stole nová. Útočí až příští kolo (hned jen kočky s Rychlými tlapami)." % cat_name
		else:
			status_label.text = "%s teď nemůže útočit." % cat_name
		_play_sfx(&"ui_click")
		return

	_selected_table_power = null
	_selected_info_zone = INFO_ZONE_NONE
	_selected_attacker = null if _selected_attacker == slot.occupant else slot.occupant
	if _selected_attacker == null:
		status_label.text = "Výběr útoku zrušen."
	else:
		status_label.text = "%s vybraná. Klikni na nepřátelskou lajnu." % _selected_attacker.definition.display_name


func _handle_enemy_lane_pressed(lane_index: int) -> void:
	var player_state: PlayerBattleState = _battle_state.get_player_state(PLAYER_ID)
	var enemy_state: PlayerBattleState = _battle_state.get_enemy_state(PLAYER_ID)
	if player_state == null or enemy_state == null:
		return

	if _selected_card != null:
		if _selected_card.definition.card_type == CardGameConstants.CardType.CAT:
			status_label.text = "Kočky hrají jen na svou stranu."
			return

		var slot: LaneSlotState = enemy_state.board[lane_index]
		if slot != null and slot.occupant != null and _is_valid_card_target(_selected_card, slot.occupant, enemy_state.player_id, player_state, enemy_state):
			status_label.text = _play_targeted_card(player_state, enemy_state, _selected_card, slot.occupant)
			_clear_selection_state()
			return

		status_label.text = "Tohle není cíl pro %s." % _selected_card.definition.display_name
		return

	if _selected_attacker == null:
		return

	var summary := _perform_attack(player_state, enemy_state, _selected_attacker, lane_index)
	if not summary.is_empty():
		status_label.text = summary
	_selected_attacker = null


func _play_card_to_lane(player_state: PlayerBattleState, lane_index: int, card_instance: CardInstance) -> void:
	var slot: LaneSlotState = player_state.board[lane_index]
	if slot == null or not slot.is_empty():
		return

	_clear_lane_feedback()
	slot.occupant = card_instance
	card_instance.lane_index = lane_index
	card_instance.has_attacked = false
	card_instance.entered_this_turn = true
	card_instance.immediate_entry_attack_granted = false
	card_instance.can_attack = false
	if card_instance.has_keyword(CardGameConstants.KEYWORD_QUICK_PAWS) and not player_state.immediate_entry_attack_used_this_turn:
		card_instance.can_attack = true
		card_instance.immediate_entry_attack_granted = true
		player_state.immediate_entry_attack_used_this_turn = true
	_spend_card_cost(card_instance, player_state)
	player_state.hand.erase(card_instance)
	_play_sfx(&"card_place")
	_queue_lane_fx(player_state.player_id, lane_index, &"fx_enter")
	_resolve_triggered_effects(card_instance, player_state, CardGameConstants.TRIGGER_BATTLECRY)
	if card_instance.can_attack and not card_instance.has_attacked:
		status_label.text = "%s jde do lajny %s a může hned útočit." % [card_instance.definition.display_name, lane_index + 1]
	else:
		status_label.text = "%s jde do lajny %s." % [card_instance.definition.display_name, lane_index + 1]
	_check_battle_end()


func _perform_attack(attacker_owner_state: PlayerBattleState, defender_state: PlayerBattleState, attacker: CardInstance, target_lane: int) -> String:
	if attacker == null or _battle_state == null or _battle_state.battle_over:
		return ""

	var valid_attack_lanes: Array[int] = _battle_rules.get_valid_attack_lanes(attacker, defender_state)
	if not valid_attack_lanes.has(target_lane):
		return "Sem %s neútočí." % attacker.definition.display_name

	_clear_lane_feedback()
	attacker.has_attacked = true
	_set_lane_feedback(attacker.owner_id, attacker.lane_index, "ÚTOK %s" % attacker.current_attack, LaneSlotView.EVENT_ACTION)
	var target_slot: LaneSlotState = defender_state.board[target_lane]
	var summary := ""
	_play_sfx(&"attack")
	_queue_lane_fx(attacker.owner_id, attacker.lane_index, &"fx_attack")

	var defender_card: CardInstance = null
	if target_slot.occupant != null:
		defender_card = target_slot.occupant
		_adjust_card_life(target_slot.occupant, -attacker.current_attack)
		_queue_lane_fx(defender_state.player_id, target_lane, &"fx_hit", [attacker.current_attack])
		_play_sfx(&"ko" if target_slot.occupant.current_life <= 0 else &"hit")
		_set_lane_feedback(defender_state.player_id, target_lane, "-%s ŽIV" % attacker.current_attack, LaneSlotView.EVENT_DAMAGE)
		if target_slot.occupant.current_life <= 0:
			summary = "%s zasáhne %s za %s zranění a vyřadí ji." % [attacker.definition.display_name, target_slot.occupant.definition.display_name, attacker.current_attack]
		else:
			summary = "%s zasáhne %s za %s zranění. Zbývá %s životů." % [attacker.definition.display_name, target_slot.occupant.definition.display_name, attacker.current_attack, target_slot.occupant.current_life]
	else:
		var guard_target: CardInstance = _battle_rules.find_guard_for_direct_damage(defender_state, target_lane)
		if guard_target != null:
			defender_card = guard_target
			_set_lane_feedback(defender_state.player_id, target_lane, "ZASTAVENO", LaneSlotView.EVENT_BLOCK)
			_adjust_card_life(guard_target, -attacker.current_attack)
			_queue_lane_fx(defender_state.player_id, guard_target.lane_index, &"fx_block", [attacker.current_attack])
			_play_sfx(&"ko" if guard_target.current_life <= 0 else &"guard")
			_set_lane_feedback_for_card(guard_target, "OCHRANA -%s" % attacker.current_attack, LaneSlotView.EVENT_BLOCK)
			if guard_target.current_life <= 0:
				summary = "%s útočí do lajny %s, ale %s s Ochranou%s zásah zachytí a padne." % [attacker.definition.display_name, target_lane + 1, guard_target.definition.display_name, _guard_origin_text(guard_target, target_lane)]
			else:
				summary = "%s útočí do lajny %s, ale %s s Ochranou%s zásah zachytí. Zbývá %s životů." % [attacker.definition.display_name, target_lane + 1, guard_target.definition.display_name, _guard_origin_text(guard_target, target_lane), guard_target.current_life]
		else:
			_adjust_player_life(defender_state, -attacker.current_attack)
			_queue_lane_fx(defender_state.player_id, target_lane, &"fx_direct", [attacker.current_attack])
			_play_sfx(&"direct_hit")
			_set_lane_feedback(defender_state.player_id, target_lane, "PŘÍMO %s" % attacker.current_attack, LaneSlotView.EVENT_DIRECT)
			summary = "%s udělí %s přímého zranění. %s %s životů." % [attacker.definition.display_name, attacker.current_attack, "Tobě zbývá" if defender_state.player_id == PLAYER_ID else "Soupeři zbývá", defender_state.life]
			_resolve_triggered_effects(attacker, attacker_owner_state, CardGameConstants.TRIGGER_ON_DIRECT_DAMAGE)

	# Odveta: bránící kočka (i když sama padne) vrátí útočníkovi úder svým útokem.
	var retaliation_text := _apply_retaliation(attacker, defender_card)
	if not retaliation_text.is_empty():
		summary = "%s %s" % [summary, retaliation_text]

	_resolve_deaths(defender_state)
	_resolve_deaths(attacker_owner_state)
	_check_battle_end()
	return summary


# Ochrana kryje i sousední lajny; bez upozornění to v testu vypadalo jako chyba.
func _guard_origin_text(guard: CardInstance, target_lane: int) -> String:
	if guard == null or guard.lane_index == target_lane:
		return ""
	return " (přiskočí ze sousední lajny %s)" % (guard.lane_index + 1)


func _apply_retaliation(attacker: CardInstance, defender_card: CardInstance) -> String:
	if not CardGameConstants.combat_retaliation or attacker == null or defender_card == null:
		return ""
	var strike := defender_card.current_attack
	if strike <= 0:
		return ""
	_adjust_card_life(attacker, -strike)
	# Feedback útočníka zůstává „ÚTOK N“ (co udělal); odvetu ukáže plovoucí číslo a souhrn.
	_queue_lane_fx(attacker.owner_id, attacker.lane_index, &"fx_hit", [strike])
	if attacker.current_life <= 0:
		return "%s vrací úder za %s a útočník padne." % [defender_card.definition.display_name, strike]
	return "%s vrací úder za %s." % [defender_card.definition.display_name, strike]


func _resolve_deaths(owner_state: PlayerBattleState) -> void:
	var removed_card := true
	while removed_card:
		removed_card = false
		for slot in owner_state.board:
			if slot == null or slot.occupant == null:
				continue
			if slot.occupant.current_life > 0:
				continue
			_send_to_discard(owner_state, slot)
			removed_card = true
			break


func _adjust_card_life(card_instance: CardInstance, delta: int) -> void:
	if card_instance == null or delta == 0:
		return
	card_instance.current_life = maxi(0, card_instance.current_life + delta)


func _adjust_player_life(player_state: PlayerBattleState, delta: int) -> void:
	if player_state == null or delta == 0:
		return
	var life_ceiling := player_state.max_life if player_state.max_life > 0 else player_state.life
	life_ceiling = maxi(life_ceiling, player_state.life)
	player_state.life = clampi(player_state.life + delta, 0, life_ceiling)


func _send_to_discard(owner_state: PlayerBattleState, slot: LaneSlotState) -> void:
	var dead_card: CardInstance = slot.occupant
	slot.occupant = null
	if dead_card == null:
		return

	var former_lane_index := dead_card.lane_index
	dead_card.lane_index = -1
	_set_lane_feedback(owner_state.player_id, former_lane_index, "KO", LaneSlotView.EVENT_KO)
	_queue_lane_fx(owner_state.player_id, former_lane_index, &"fx_death", [CardArtCache.get_cropped(dead_card.definition.art_path)])
	if dead_card.attached_item != null:
		owner_state.discard.append(dead_card.attached_item)
		dead_card.attached_item = null
		dead_card.attached_item_instance_id = -1
	_resolve_triggered_effects(dead_card, owner_state, CardGameConstants.TRIGGER_LAST_BREATH, former_lane_index)
	owner_state.discard.append(dead_card)
	# Feast: any other cat that survives this death grows +1/+1. The dead cat is
	# already off the board, so it never feasts on its own death.
	_trigger_feast_for_death()


func _trigger_feast_for_death() -> void:
	if _battle_state == null:
		return
	for state in _battle_state.player_states:
		if state == null:
			continue
		for slot in state.board:
			if slot == null or slot.occupant == null:
				continue
			var cat := slot.occupant
			if not cat.has_keyword(CardGameConstants.KEYWORD_FEAST):
				continue
			cat.current_attack += 1
			cat.current_life += 1
			_set_lane_feedback_for_card(cat, "HOSTINA +1/+1", LaneSlotView.EVENT_SUPPORT)


# lane_override: lajna karty, která už ze stolu odešla (Poslední dech).
func _resolve_triggered_effects(card_instance: CardInstance, owner_state: PlayerBattleState, trigger: StringName, lane_override: int = -1) -> void:
	var lane_index := lane_override if lane_override >= 0 else card_instance.lane_index
	var opposing_state: PlayerBattleState = null
	if _battle_state != null:
		opposing_state = _battle_state.get_player_state(ENEMY_ID if owner_state.player_id == PLAYER_ID else PLAYER_ID)
	var damaged_opponent := false
	for effect in card_instance.definition.effects:
		var typed_effect: CardEffect = effect
		if typed_effect == null or typed_effect.trigger != trigger:
			continue

		match typed_effect.action:
			&"heal_life":
				if typed_effect.target_mode == CardGameConstants.TARGET_SELF_OWNER:
					_adjust_player_life(owner_state, typed_effect.value)
			&"draw_cards":
				if typed_effect.target_mode == CardGameConstants.TARGET_SELF_OWNER:
					_deck_system.draw_cards(owner_state, typed_effect.value)
			&"deal_damage":
				if opposing_state == null:
					continue
				if typed_effect.target_mode == CardGameConstants.TARGET_OPPOSITE_LANE and lane_index >= 0:
					var target: CardInstance = opposing_state.board[lane_index].occupant
					if target != null:
						_adjust_card_life(target, -typed_effect.value)
						_set_lane_feedback(opposing_state.player_id, lane_index, "-%s ŽIV" % typed_effect.value, LaneSlotView.EVENT_DAMAGE)
						_queue_lane_fx(opposing_state.player_id, lane_index, &"fx_hit", [typed_effect.value])
						damaged_opponent = true
				elif typed_effect.target_mode == CardGameConstants.TARGET_ENEMY_PLAYER:
					_adjust_player_life(opposing_state, -typed_effect.value)
					if lane_index >= 0:
						_queue_lane_fx(opposing_state.player_id, lane_index, &"fx_direct", [typed_effect.value])
			&"modify_attack", &"modify_life":
				if typed_effect.target_mode != CardGameConstants.TARGET_ADJACENT_LANE or lane_index < 0:
					continue
				for neighbor in [lane_index - 1, lane_index + 1]:
					if neighbor < 0 or neighbor >= owner_state.board.size():
						continue
					var ally: CardInstance = owner_state.board[neighbor].occupant
					if ally == null:
						continue
					if typed_effect.action == &"modify_attack":
						ally.current_attack += typed_effect.value
						_set_lane_feedback(owner_state.player_id, neighbor, "+%s ÚTK" % typed_effect.value, LaneSlotView.EVENT_SUPPORT)
					else:
						ally.current_life += typed_effect.value
						_set_lane_feedback(owner_state.player_id, neighbor, "+%s ŽIV" % typed_effect.value, LaneSlotView.EVENT_SUPPORT)
			&"summon_token":
				if lane_index < 0 or lane_index >= owner_state.board.size():
					continue
				var slot: LaneSlotState = owner_state.board[lane_index]
				if slot == null or not slot.is_empty():
					continue
				var token := _create_card_instance(typed_effect.keyword_arg, owner_state.player_id)
				if token == null:
					continue
				token.lane_index = lane_index
				token.entered_this_turn = true
				token.can_attack = false
				token.has_attacked = false
				slot.occupant = token
				_set_lane_feedback(owner_state.player_id, lane_index, "VYVOLÁNO", LaneSlotView.EVENT_SUPPORT)
				_queue_lane_fx(owner_state.player_id, lane_index, &"fx_enter")
	if damaged_opponent:
		_resolve_deaths(opposing_state)


func _check_battle_end() -> void:
	if _battle_state == null or _battle_state.battle_over:
		return

	var player_state: PlayerBattleState = _battle_state.get_player_state(PLAYER_ID)
	var enemy_state: PlayerBattleState = _battle_state.get_player_state(ENEMY_ID)
	var previous_threat := _get_current_threat()
	if player_state == null or enemy_state == null:
		return

	if player_state.life <= 0 and enemy_state.life <= 0:
		_battle_state.battle_over = true
		_battle_state.winner_player_id = -1
		_overlay_presenter.clear_reward_offers()
		status_label.text = "Remíza. Obě strany došly o všechny životy."
		_show_post_match_overlay("draw", "Remíza", "Obě strany se zhroutily zároveň. Dnes večer si stůl nevezme nikdo.", previous_threat, previous_threat, [])
		return

	if enemy_state.life <= 0:
		_battle_state.battle_over = true
		_battle_state.winner_player_id = PLAYER_ID
		var victory_state := _progression_system.apply_battle_result(_progression_state, PLAYER_ID, PLAYER_ID, ENEMY_ID)
		var victory_threat := _progression_system.get_threat_level(victory_state) + _get_threat_bonus()
		var unlocked_name := _record_training_win(victory_state)
		var victory_deck_messages := _progression_system.get_threat_transition_messages(_get_enemy_deck_id(), previous_threat, victory_threat)
		_progression_state = victory_state
		_progression_system.save_state(_progression_state)
		var run_session = _get_run_session()
		if run_session != null and run_session.is_active():
			_overlay_presenter.set_reward_offers(run_session.build_reward_offers(_card_library))
		else:
			_overlay_presenter.clear_reward_offers()
		enemy_name_label.text = _build_enemy_header_name(enemy_state.display_name)
		_play_sfx(&"victory")
		_save_match_log.call_deferred("vyhra")
		status_label.text = "Výhra. %s došel o všechny životy." % enemy_state.display_name
		var victory_text := "Soupeř %s je poražen. Stůl se pro příští odvetu uklidnil." % enemy_state.display_name
		if unlocked_name != "":
			victory_text += "\nV tréninku se odemkl další, silnější soupeř: %s." % unlocked_name
		_show_post_match_overlay("win", "Výhra", victory_text, previous_threat, victory_threat, victory_deck_messages)
		return

	if player_state.life <= 0:
		_battle_state.battle_over = true
		_battle_state.winner_player_id = ENEMY_ID
		_overlay_presenter.clear_reward_offers()
		var defeat_state := _progression_system.apply_battle_result(_progression_state, ENEMY_ID, PLAYER_ID, ENEMY_ID)
		var defeat_threat := _progression_system.get_threat_level(defeat_state) + _get_threat_bonus()
		var defeat_deck_messages := _progression_system.get_threat_transition_messages(_get_enemy_deck_id(), previous_threat, defeat_threat)
		_progression_state = defeat_state
		_progression_system.save_state(_progression_state)
		enemy_name_label.text = _build_enemy_header_name(enemy_state.display_name)
		_play_sfx(&"defeat")
		_save_match_log.call_deferred("prohra")
		status_label.text = "Prohra. Tvoje strana došla o všechny životy."
		_show_post_match_overlay("loss", "Prohra", "%s si stůl drží a příště se vrátí ještě horší." % enemy_state.display_name, previous_threat, defeat_threat, defeat_deck_messages)


func _on_end_turn_pressed() -> void:
	if _battle_state == null:
		return

	if _battle_state.battle_over:
		get_tree().reload_current_scene()
		return
	if _enemy_turn_running:
		return

	_clear_selection_state()
	_play_sfx(&"end_turn")

	var player_state: PlayerBattleState = _battle_state.get_player_state(PLAYER_ID)
	var enemy_state: PlayerBattleState = _battle_state.get_player_state(ENEMY_ID)
	if player_state == null or enemy_state == null:
		return

	_bank_unused_tuna(player_state)
	_clear_end_of_turn_modifiers(player_state)
	if _battle_state.battle_over:
		_refresh_ui()
		return

	_battle_state.active_player_id = ENEMY_ID
	_start_turn(enemy_state)
	_enemy_turn_running = true
	end_turn_button.disabled = true
	BattleFx.banner(self, "Tah soupeře", Color(0.95, 0.55, 0.45))
	await _run_enemy_stub_turn()
	_enemy_turn_running = false
	end_turn_button.disabled = false
	if _battle_state.battle_over:
		_refresh_ui()
		return

	_bank_unused_tuna(enemy_state)
	_clear_end_of_turn_modifiers(enemy_state)
	if _battle_state.battle_over:
		_refresh_ui()
		return

	_battle_state.active_player_id = PLAYER_ID
	_battle_state.turn_number += 1
	_start_turn(player_state)
	_log_board_snapshot("Začátek tvého tahu")
	BattleFx.banner(self, "Tvůj tah")
	_play_sfx(&"card_draw")
	status_label.text = "Jsi na tahu. Vylož, použij Sílu stolu nebo zaútoč."
	_refresh_ui()


func _on_rematch_button_pressed() -> void:
	get_tree().reload_current_scene()


func _on_choose_encounter_button_pressed() -> void:
	var run_session = _get_run_session()
	if run_session != null and run_session.is_active():
		if _should_end_run_from_postmatch():
			run_session.end_run()
			_return_to_encounter_select()
			return
		if run_session.has_next_encounter():
			run_session.advance_to_next_encounter()
			get_tree().reload_current_scene()
			return

		run_session.end_run()

	_return_to_encounter_select()


func _update_post_match_actions() -> void:
	_overlay_presenter.update_post_match_actions(_get_run_session())


func _refresh_reward_buttons() -> void:
	_overlay_presenter.refresh_reward_buttons()


func _on_reward_button_pressed(offer_index: int) -> void:
	var run_session = _get_run_session()
	if run_session == null or not run_session.is_active():
		_return_to_encounter_select()
		return
	var current_reward_offers := _overlay_presenter.get_reward_offers()
	if offer_index < 0 or offer_index >= current_reward_offers.size():
		return

	var reward_offer: Dictionary = current_reward_offers[offer_index]
	if not run_session.apply_reward_offer(reward_offer):
		push_warning("Could not apply reward offer %s." % offer_index)
		return

	_progression_state = _progression_system.set_player_deck_card_ids(_progression_state, run_session.get_player_deck_card_ids())
	_progression_system.save_state(_progression_state)
	run_session.clear_reward_offers()
	_overlay_presenter.clear_reward_offers()
	_current_reward_offers.clear()

	if run_session.has_next_encounter():
		run_session.advance_to_next_encounter()
		get_tree().reload_current_scene()
		return

	_show_run_completion_overlay(reward_offer)


func _return_to_encounter_select() -> void:
	var packed_scene := load(ENCOUNTER_SELECT_SCENE_PATH) as PackedScene
	if packed_scene == null:
		push_error("Could not load encounter_select.tscn")
		return

	var select_scene := packed_scene.instantiate()
	var tree := get_tree()
	tree.root.add_child(select_scene)
	tree.current_scene = select_scene
	queue_free()


func _get_run_session():
	return get_node("/root/RunSession")


func _should_end_run_from_postmatch() -> bool:
	return _overlay_presenter.get_result_mode() in ["loss", "draw", "run_complete"] or _overlay_presenter.is_run_completion_pending()


func _start_turn(player_state: PlayerBattleState) -> void:
	# The very first turn a player takes does not ramp Tuna (both open on STARTING_TUNA).
	# Only ramp from the second turn onward.
	if player_state.has_started_turn:
		player_state.tuna_max = mini(player_state.tuna_max + 1, MAX_TUNA)
	else:
		player_state.has_started_turn = true
	player_state.tuna_current = player_state.tuna_max
	player_state.table_power_used_this_turn = false
	player_state.immediate_entry_attack_used_this_turn = false
	_draw_or_starve(player_state, CardGameConstants.draw_per_turn)
	_refresh_attack_state_for_player(player_state)


# Hlad (D-017): líznutí z prázdného balíku bere životy 1, 2, 3…, aby zápas nikdy neuvízl v patu.
func _draw_or_starve(player_state: PlayerBattleState, amount: int) -> void:
	for _i in range(amount):
		if not player_state.deck.is_empty():
			_deck_system.draw_cards(player_state, 1)
			continue
		player_state.hunger_count += 1
		_adjust_player_life(player_state, -player_state.hunger_count)
		var lives_word := "život" if player_state.hunger_count == 1 else ("životy" if player_state.hunger_count < 5 else "životů")
		if player_state.player_id == PLAYER_ID:
			status_label.text = "Hlad! Máš prázdný balík a ztrácíš %s %s." % [player_state.hunger_count, lives_word]
		else:
			status_label.text = "Hlad! %s má prázdný balík a ztrácí %s %s." % [player_state.display_name, player_state.hunger_count, lives_word]
		_play_sfx(&"hit_heavy")
		_check_battle_end()


func _bank_unused_tuna(player_state: PlayerBattleState) -> void:
	if player_state == null or player_state.tuna_current <= 0:
		return
	player_state.saved_tuna_current = mini(CardGameConstants.SAVED_TUNA_CAP, player_state.saved_tuna_current + player_state.tuna_current)
	player_state.tuna_current = 0


func _spend_card_cost(card_instance: CardInstance, player_state: PlayerBattleState) -> Dictionary:
	var payment := _battle_rules.build_card_cost_payment(card_instance, player_state)
	if payment.is_empty():
		return payment
	player_state.saved_tuna_current = maxi(0, player_state.saved_tuna_current - int(payment.get("saved_spent", 0)))
	player_state.tuna_current = maxi(0, player_state.tuna_current - int(payment.get("normal_spent", 0)))
	return payment


func _format_tuna_label(player_state: PlayerBattleState) -> String:
	if player_state == null:
		return "Tuna 0/0 | Rez. 0"
	# Rezerva (Saved Tuna) jde utratit jen za Tricky; bez Triků v balíku je to šum (D-013).
	if not _player_has_tricks(player_state):
		return "Tuna %s/%s" % [player_state.tuna_current, player_state.tuna_max]
	return "Tuna %s/%s | Rez. %s" % [player_state.tuna_current, player_state.tuna_max, player_state.saved_tuna_current]


func _player_has_tricks(player_state: PlayerBattleState) -> bool:
	for pile in [player_state.hand, player_state.deck, player_state.discard]:
		for card in pile:
			if card != null and card.definition != null and card.definition.card_type == CardGameConstants.CardType.TRICK:
				return true
	return false


func _refresh_attack_state_for_player(player_state: PlayerBattleState) -> void:
	for slot in player_state.board:
		if slot == null or slot.occupant == null:
			continue
		slot.occupant.has_attacked = false
		slot.occupant.can_attack = true


func _run_enemy_stub_turn() -> void:
	var enemy_state: PlayerBattleState = _battle_state.get_player_state(ENEMY_ID)
	var player_state: PlayerBattleState = _battle_state.get_player_state(PLAYER_ID)
	if enemy_state == null or player_state == null:
		return

	var action_log: Array[String] = []
	if _pace_actions:
		status_label.text = "%s přemýšlí…" % enemy_state.display_name
		_refresh_ui()
		await _pace_pause(ENEMY_ACTION_DELAY)
	var play_iterations := 0
	while not _battle_state.battle_over and play_iterations < 10:
		var play_choice: Dictionary = _ai_controller.choose_play(enemy_state, player_state, _battle_rules)
		if play_choice.is_empty():
			break
		var played_card: CardInstance = play_choice["card"]
		var play_type := str(play_choice.get("play_type", "lane"))
		match play_type:
			"targeted":
				var target_owner_id := int(play_choice.get("target_owner_id", player_state.player_id))
				var target_lane := int(play_choice.get("lane_index", -1))
				var target_state := enemy_state if target_owner_id == enemy_state.player_id else player_state
				if target_lane < 0 or target_lane >= target_state.board.size():
					break
				var target_slot: LaneSlotState = target_state.board[target_lane]
				if target_slot == null or target_slot.occupant == null:
					break
				var support_summary := _play_targeted_card(enemy_state, player_state, played_card, target_slot.occupant)
				if not support_summary.is_empty():
					action_log.append(support_summary)
			"instant":
				var instant_summary := _play_targeted_card(enemy_state, player_state, played_card, null)
				if not instant_summary.is_empty():
					action_log.append(instant_summary)
			_:
				var played_lane: int = int(play_choice.get("lane_index", -1))
				if played_lane < 0:
					break
				_play_card_to_lane(enemy_state, played_lane, played_card)
				if played_card.can_attack and not played_card.has_attacked:
					action_log.append("%s vykládá %s do lajny %s a může hned útočit." % [enemy_state.display_name, played_card.definition.display_name, played_lane + 1])
				else:
					action_log.append("%s vykládá %s do lajny %s." % [enemy_state.display_name, played_card.definition.display_name, played_lane + 1])
		if _pace_actions and not action_log.is_empty():
			status_label.text = action_log[action_log.size() - 1]
			_refresh_ui()
			await _pace_pause(ENEMY_ACTION_DELAY)
		play_iterations += 1

	var enemy_power := _get_table_power_definition(enemy_state)
	var power_choice := _ai_controller.choose_table_power(enemy_state, player_state, enemy_power, _battle_rules)
	if not power_choice.is_empty():
		var power_lane := int(power_choice.get("lane_index", -1))
		var power_summary := _activate_table_power(enemy_state, player_state, enemy_power, power_lane)
		if not power_summary.is_empty():
			action_log.append(power_summary)

	var attack_iterations := 0
	while not _battle_state.battle_over and attack_iterations < 12:
		var attack_choice: Dictionary = _ai_controller.choose_attack_action(enemy_state, player_state, _battle_rules)
		if attack_choice.is_empty():
			break
		var attacking_card: CardInstance = attack_choice["attacker"]
		var target_lane: int = attack_choice["lane_index"]
		var attack_summary := _perform_attack(enemy_state, player_state, attacking_card, target_lane)
		if not attack_summary.is_empty():
			action_log.append(attack_summary)
			if _pace_actions:
				status_label.text = attack_summary
				_refresh_ui()
				await _pace_pause(ENEMY_ACTION_DELAY)
		attack_iterations += 1

	if action_log.is_empty():
		status_label.text = "%s pasuje a sleduje stůl." % enemy_state.display_name
	else:
		status_label.text = " ".join(action_log)


func _refresh_ui() -> void:
	if _battle_state == null:
		return

	var player_state: PlayerBattleState = _battle_state.get_player_state(PLAYER_ID)
	var enemy_state: PlayerBattleState = _battle_state.get_player_state(ENEMY_ID)
	if player_state == null or enemy_state == null:
		return

	enemy_life_label.text = "Životy %s" % enemy_state.life
	_refresh_turn_title()
	_refresh_enemy_hand_row(enemy_state)
	enemy_tuna_label.text = _format_tuna_label(enemy_state)
	player_life_label.text = "Životy %s" % player_state.life
	player_tuna_label.text = _format_tuna_label(player_state)
	deck_count_label.text = str(player_state.deck.size())
	discard_count_label.text = str(player_state.discard.size())
	hand_count_label.text = str(player_state.hand.size())

	_refresh_lanes(_player_lanes, player_state)
	_refresh_lanes(_enemy_lanes, enemy_state)
	_refresh_hand(player_state)
	_refresh_selected_panel()
	_refresh_lane_highlights(player_state, enemy_state)
	_update_turn_indicator()
	_refresh_combat_info_panel()
	_sync_battle_feed()

	if _battle_state.battle_over:
		table_power_button.visible = true
		table_power_button.disabled = true
		table_power_button.text = "Síla stolu"
		end_turn_button.text = "Znovu"
		end_turn_button.disabled = false
	else:
		var player_power := _get_table_power_definition(player_state)
		table_power_button.visible = true
		if player_power == null:
			# Bez Síly stolu (výchozí hra, D-011) tlačítko jen zabíralo místo.
			table_power_button.text = "Bez Síly stolu"
			table_power_button.disabled = true
			table_power_button.visible = false
		else:
			var power_label := "%s (%s)" % [player_power.display_name, player_power.cost]
			if player_state.table_power_used_this_turn:
				table_power_button.text = "%s (využito)" % player_power.display_name
			elif _selected_table_power == player_power:
				table_power_button.text = "Zrušit %s" % player_power.display_name
			else:
				table_power_button.text = power_label
			table_power_button.disabled = _battle_state.active_player_id != PLAYER_ID or not _can_use_table_power(player_state, player_power)
		end_turn_button.text = "Konec tahu"
		end_turn_button.disabled = _battle_state.active_player_id != PLAYER_ID


func _select_hand_card_by_instance_id(instance_id: int, toggle_selection: bool = true) -> bool:
	if _battle_state == null or _battle_state.battle_over or _battle_state.active_player_id != PLAYER_ID:
		return false

	var player_state: PlayerBattleState = _battle_state.get_player_state(PLAYER_ID)
	if player_state == null:
		return false

	for card in player_state.hand:
		if card.instance_id != instance_id:
			continue

		_selected_attacker = null
		_selected_table_power = null
		_selected_info_zone = INFO_ZONE_NONE
		if toggle_selection and _selected_card == card:
			_selected_card = null
			status_label.text = "Výběr z ruky zrušen."
		else:
			_selected_card = card
			var enemy_state := _battle_state.get_enemy_state(PLAYER_ID)
			status_label.text = _build_card_selection_message(_selected_card, player_state, enemy_state)
		_refresh_ui()
		return true

	return false


func _refresh_lanes(views: Array[LaneSlotView], player_state: PlayerBattleState) -> void:
	var lane_feedback := _get_lane_feedback(player_state.player_id)
	for lane_index in range(views.size()):
		views[lane_index].set_card_instance(player_state.board[lane_index].occupant)
		if lane_index < lane_feedback.size():
			var feedback: Dictionary = lane_feedback[lane_index]
			views[lane_index].set_recent_event(str(feedback.get("text", "")), StringName(feedback.get("tone", LaneSlotView.EVENT_NEUTRAL)))
		else:
			views[lane_index].clear_recent_event()


func _refresh_hand(player_state: PlayerBattleState) -> void:
	var enemy_state: PlayerBattleState = _battle_state.get_enemy_state(PLAYER_ID)
	var existing_views: Array = hand_row.get_children()
	for child_index in range(player_state.hand.size(), existing_views.size()):
		var stale_card_view := existing_views[child_index] as CardView
		if stale_card_view == null:
			continue
		stale_card_view.set_interactive(false)
		stale_card_view.set_selected(false)
		stale_card_view.set_playable(false)
		stale_card_view.set_card_instance(null)

	for card_index in range(player_state.hand.size()):
		var card := player_state.hand[card_index]
		var card_view: CardView
		if card_index < existing_views.size():
			card_view = existing_views[card_index] as CardView
		else:
			card_view = CARD_VIEW_SCENE.instantiate() as CardView
			hand_row.add_child(card_view)
			existing_views.append(card_view)

		card_view.set_card_instance(card)
		if _pace_actions and not _seen_hand_ids.has(card.instance_id):
			_seen_hand_ids[card.instance_id] = true
			_animate_card_draw(card_view, card_index)
		card_view.set_selected(card == _selected_card)
		card_view.set_playable(_battle_state.active_player_id == PLAYER_ID and _can_play_card_from_hand(card, player_state, enemy_state))
		card_view.set_interactive(_battle_state.active_player_id == PLAYER_ID and not _battle_state.battle_over)
		if not card_view.card_pressed.is_connected(_on_hand_card_pressed):
			card_view.card_pressed.connect(_on_hand_card_pressed)
			card_view.card_hovered.connect(_on_card_hovered)

	_fit_hand_cards(player_state.hand.size())


# Při mnoha kartách je zúží, aby se všechny vešly do panelu ruky (jinak ujížděly mimo obrazovku).
func _fit_hand_cards(count: int) -> void:
	if count <= 0:
		return
	var area := hand_row.get_parent_control()
	# Před prvním layoutem panel ještě nezná šířku; logická šířka ruky je ~1000 px (viewport 1600).
	var available := area.size.x if area != null and area.size.x >= 600.0 else 1000.0
	var separation := float(hand_row.get_theme_constant("separation"))
	var width := clampf((available - separation * float(count - 1)) / float(count), 96.0, HAND_CARD_SIZE.x)
	for child in hand_row.get_children():
		var view := child as Control
		if view != null:
			view.custom_minimum_size = Vector2(width, HAND_CARD_SIZE.y)


func _animate_card_draw(card_view: Control, order: int) -> void:
	card_view.pivot_offset = card_view.custom_minimum_size * 0.5
	card_view.scale = Vector2(0.6, 0.6)
	card_view.self_modulate.a = 0.0
	var tween := card_view.create_tween().set_parallel(true)
	var delay := 0.06 * float(order % 5)
	tween.tween_property(card_view, "scale", Vector2.ONE, 0.28).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_view, "self_modulate:a", 1.0, 0.18).set_delay(delay)


func _refresh_selected_panel() -> void:
	_preview_presenter.refresh_selected_panel({
		"selected_card": _selected_card,
		"selected_attacker": _selected_attacker,
		"selected_table_power": _selected_table_power,
		"selected_info_zone": _selected_info_zone,
		"player_state": _battle_state.get_player_state(PLAYER_ID),
		"enemy_state": _battle_state.get_player_state(ENEMY_ID),
		"enemy_turn": _enemy_turn_running,
		"hover_card": _hover_card,
	})


func _refresh_combat_info_panel() -> void:
	_preview_presenter.refresh_combat_info_panel({
		"battle_state": _battle_state,
		"selected_attacker": _selected_attacker,
		"selected_card": _selected_card,
		"selected_table_power": _selected_table_power,
		"selected_info_zone": _selected_info_zone,
	})


func _set_lane_preview(owner_id: int, lane_index: int, text: String, tone: StringName = LaneSlotView.EVENT_ACTION) -> void:
	var lanes := _player_lanes if owner_id == PLAYER_ID else _enemy_lanes
	if lane_index < 0 or lane_index >= lanes.size():
		return
	lanes[lane_index].set_preview_event(text, tone)


func _apply_enemy_lethal_lane_previews(player_state: PlayerBattleState, enemy_state: PlayerBattleState) -> void:
	if player_state == null or enemy_state == null or player_state.life <= 0:
		return

	var threats := _preview_presenter.collect_enemy_direct_threats(player_state, enemy_state)
	var total_direct_damage := 0
	for threat in threats:
		total_direct_damage += int(threat.get("damage", 0))

	if total_direct_damage < player_state.life:
		return

	for threat in threats:
		var attacker_lane := int(threat.get("attacker_lane", -1))
		var target_lane := int(threat.get("target_lane", -1))
		var damage := int(threat.get("damage", 0))
		if attacker_lane >= 0 and attacker_lane < _enemy_lanes.size():
			_enemy_lanes[attacker_lane].set_highlight_mode(LaneSlotView.HIGHLIGHT_THREAT)
			_set_lane_preview(ENEMY_ID, attacker_lane, "PŘÍMO %s" % damage, LaneSlotView.EVENT_DIRECT)
		if target_lane >= 0 and target_lane < _player_lanes.size():
			_player_lanes[target_lane].set_highlight_mode(LaneSlotView.HIGHLIGHT_THREAT)
			_set_lane_preview(PLAYER_ID, target_lane, "KRYJ" if damage < player_state.life else "LETHAL", LaneSlotView.EVENT_DIRECT)


func _build_info_zone_title(zone_id: StringName) -> String:
	match zone_id:
		INFO_ZONE_DECK:
			return "Balík"
		INFO_ZONE_DISCARD:
			return "Odhazování"
	return "Náhled"


func _build_info_zone_meta(zone_id: StringName, player_state: PlayerBattleState) -> String:
	if player_state == null:
		return "CHYBÍ DATA"

	var cards := _get_info_zone_cards(zone_id, player_state)
	var type_count := _count_unique_card_names(cards)
	match zone_id:
		INFO_ZONE_DECK:
			return "BALÍK | %s karet | %s typů" % [cards.size(), type_count]
		INFO_ZONE_DISCARD:
			return "ODHAZOVÁNÍ | %s karet | %s typů" % [cards.size(), type_count]
	return "NÁHLED"


func _build_info_zone_detail(zone_id: StringName, player_state: PlayerBattleState) -> String:
	if player_state == null:
		return "Chybí stav hráče."

	var cards := _get_info_zone_cards(zone_id, player_state)
	if cards.is_empty():
		return "Prázdno."
	return _build_card_stack_summary(cards)


func _build_info_zone_hint(zone_id: StringName) -> String:
	match zone_id:
		INFO_ZONE_DECK:
			return "Klikni znovu na Balík pro zavření."
		INFO_ZONE_DISCARD:
			return "Klikni znovu na Odhazování pro zavření."
	return "Klikni znovu pro zavření."


func _get_info_zone_cards(zone_id: StringName, player_state: PlayerBattleState) -> Array[CardInstance]:
	match zone_id:
		INFO_ZONE_DECK:
			return player_state.deck
		INFO_ZONE_DISCARD:
			return player_state.discard
	var empty_cards: Array[CardInstance] = []
	return empty_cards


func _count_unique_card_names(cards: Array[CardInstance]) -> int:
	var counts := _count_cards_by_name(cards)
	return counts.size()


func _build_card_stack_summary(cards: Array[CardInstance]) -> String:
	var counts := _count_cards_by_name(cards)
	var names := counts.keys()
	names.sort()

	var lines: Array[String] = []
	for card_name in names:
		lines.append("%sx %s" % [counts[card_name], card_name])
	return "\n".join(lines)


func _count_cards_by_name(cards: Array[CardInstance]) -> Dictionary:
	var counts: Dictionary = {}
	for card in cards:
		if card == null or card.definition == null:
			continue
		var card_name := card.definition.display_name
		counts[card_name] = int(counts.get(card_name, 0)) + 1
	return counts


func _build_table_power_lane_preview(power_definition: TablePowerDefinition) -> String:
	if power_definition == null:
		return "token"

	for effect in power_definition.effects:
		var typed_effect: CardEffect = effect
		if typed_effect != null and typed_effect.action == &"summon_token":
			return _card_display_name_from_id(typed_effect.keyword_arg)
	return power_definition.display_name


func _format_signed_number(value: int) -> String:
	return "%s%s" % ["+" if value >= 0 else "", value]


func _card_type_label(card_type: int) -> String:
	match card_type:
		CardGameConstants.CardType.TRICK:
			return "TRIK"
		CardGameConstants.CardType.ITEM:
			return "PŘEDMĚT"
		_:
			return "KOČKA"


func _refresh_lane_highlights(player_state: PlayerBattleState, enemy_state: PlayerBattleState) -> void:
	for lane_index in range(_player_lanes.size()):
		_player_lanes[lane_index].set_highlight_mode(LaneSlotView.HIGHLIGHT_NONE)
		_player_lanes[lane_index].clear_preview_event()
		_enemy_lanes[lane_index].set_highlight_mode(LaneSlotView.HIGHLIGHT_NONE)
		_enemy_lanes[lane_index].clear_preview_event()

	if _battle_state.battle_over:
		return

	if _selected_table_power != null and _battle_state.active_player_id == PLAYER_ID:
		for lane_index in _get_valid_table_power_lanes(_selected_table_power, player_state):
			_player_lanes[lane_index].set_highlight_mode(LaneSlotView.HIGHLIGHT_PLAY)
		return

	if _selected_card != null and _battle_state.active_player_id == PLAYER_ID:
		if _selected_card.definition.card_type == CardGameConstants.CardType.CAT:
			var valid_play_lanes: Array[int] = _battle_rules.get_valid_play_lanes(_selected_card, player_state)
			for lane_index in valid_play_lanes:
				_player_lanes[lane_index].set_highlight_mode(LaneSlotView.HIGHLIGHT_PLAY)
		else:
			for lane_index in _get_valid_card_target_lanes(_selected_card, player_state, enemy_state, player_state.player_id):
				_player_lanes[lane_index].set_highlight_mode(LaneSlotView.HIGHLIGHT_PLAY)
				var player_slot := player_state.board[lane_index]
				if player_slot != null and player_slot.occupant != null:
					var player_preview := _preview_presenter.build_target_preview_banner(_selected_card, player_slot.occupant)
					_set_lane_preview(PLAYER_ID, lane_index, str(player_preview.get("text", "")), StringName(player_preview.get("tone", LaneSlotView.EVENT_ACTION)))
			for lane_index in _get_valid_card_target_lanes(_selected_card, player_state, enemy_state, enemy_state.player_id):
				_enemy_lanes[lane_index].set_highlight_mode(LaneSlotView.HIGHLIGHT_ATTACK)
				var enemy_slot := enemy_state.board[lane_index]
				if enemy_slot != null and enemy_slot.occupant != null:
					var enemy_preview := _preview_presenter.build_target_preview_banner(_selected_card, enemy_slot.occupant)
					_set_lane_preview(ENEMY_ID, lane_index, str(enemy_preview.get("text", "")), StringName(enemy_preview.get("tone", LaneSlotView.EVENT_ACTION)))
		return

	if _selected_attacker != null and _battle_state.active_player_id == PLAYER_ID:
		_player_lanes[_selected_attacker.lane_index].set_highlight_mode(LaneSlotView.HIGHLIGHT_SELECTED)
		var valid_attack_lanes: Array[int] = _battle_rules.get_valid_attack_lanes(_selected_attacker, enemy_state)
		for lane_index in valid_attack_lanes:
			_enemy_lanes[lane_index].set_highlight_mode(LaneSlotView.HIGHLIGHT_ATTACK)
			var attack_preview := _preview_presenter.build_attack_preview_banner(_selected_attacker, enemy_state, lane_index)
			_set_lane_preview(ENEMY_ID, lane_index, str(attack_preview.get("text", "")), StringName(attack_preview.get("tone", LaneSlotView.EVENT_ACTION)))
		return

	if _battle_state.active_player_id == PLAYER_ID:
		_apply_enemy_lethal_lane_previews(player_state, enemy_state)


func _update_turn_indicator() -> void:
	if enemy_portrait_frame == null:
		return
	# Layout v2: místo ozdobného rámu tenký okraj v barvě tahu (zlatá konec, zelená ty, červená soupeř).
	var color := Color(0.85, 0.68, 0.36)
	if _battle_state != null and not _battle_state.battle_over:
		color = Color(0.45, 0.8, 0.45) if _battle_state.active_player_id == PLAYER_ID else Color(0.88, 0.36, 0.3)
	BattleLayout.set_portrait_border(enemy_portrait_frame, color)


# Nadpis panelu stavu: číslo kola a kdo je na tahu (místo obecného „Stav tahu“).
func _refresh_turn_title() -> void:
	var title := get_node_or_null("Margin/Layout/TopRow/BoardColumn/CombatInfoPanel/MarginContainer/InfoVBox/StatusTitle") as Label
	if title == null or _battle_state == null:
		return
	if _battle_state.battle_over:
		title.text = "Konec zápasu"
	elif _battle_state.active_player_id == PLAYER_ID:
		title.text = "Kolo %s · Tvůj tah" % _battle_state.turn_number
	else:
		title.text = "Kolo %s · Tah soupeře" % _battle_state.turn_number
	title.add_theme_font_size_override("font_size", 14)


# Soupeřova ruka jako ruby karet v hlavičce (kolik karet drží) + zbytek balíku.
func _refresh_enemy_hand_row(enemy_state: PlayerBattleState) -> void:
	if _enemy_hand_row == null:
		var header := _enemy_hand_host
		if header == null:
			return
		_enemy_hand_row = HBoxContainer.new()
		_enemy_hand_row.name = "EnemyHandRow"
		_enemy_hand_row.add_theme_constant_override("separation", -10)
		_enemy_hand_row.alignment = BoxContainer.ALIGNMENT_END
		_enemy_hand_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header.add_child(_enemy_hand_row)
	var back := CardArtCache.get_full(CardArtCache.CARD_BACK_PATH)
	var count := enemy_state.hand.size()
	while _enemy_hand_row.get_child_count() > count + 1:
		_enemy_hand_row.get_child(_enemy_hand_row.get_child_count() - 1).free()
	if _enemy_hand_row.get_child_count() == 0:
		var deck_label := Label.new()
		deck_label.add_theme_font_size_override("font_size", 14)
		deck_label.add_theme_color_override("font_color", Color(0.85, 0.78, 0.64))
		deck_label.custom_minimum_size = Vector2(70, 0)
		deck_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_enemy_hand_row.add_child(deck_label)
	while _enemy_hand_row.get_child_count() < count + 1:
		var card_back := TextureRect.new()
		card_back.texture = back
		card_back.custom_minimum_size = Vector2(34, 50)
		card_back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card_back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card_back.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		card_back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		card_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_enemy_hand_row.add_child(card_back)
	var deck_label_node := _enemy_hand_row.get_child(0) as Label
	deck_label_node.text = "Ruka %s\nBalík %s" % [count, enemy_state.deck.size()]
	_enemy_hand_row.tooltip_text = "Soupeř drží %s karet, v balíku má %s." % [count, enemy_state.deck.size()]


# Ikona (srdce/ryba) vlevo u statistiky; obsah labelu se odsune, aby se nepřekrýval.
func _attach_stat_icon(label: Label, icon_name: StringName, tint: Color) -> void:
	if label == null:
		return
	var icon := TextureRect.new()
	icon.texture = CardArtCache.get_keyword_icon(icon_name)
	if icon.texture == null:
		return
	icon.modulate = tint
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var side := float(label.get_theme_font_size("font_size")) + 4.0
	icon.anchor_top = 0.5
	icon.anchor_bottom = 0.5
	icon.offset_left = 6.0
	icon.offset_right = 6.0 + side
	icon.offset_top = -side * 0.5
	icon.offset_bottom = side * 0.5
	label.add_child(icon)


func _on_card_hovered(card_instance) -> void:
	if card_instance == _hover_card:
		return
	_hover_card = card_instance
	if _battle_state != null:
		_refresh_selected_panel()


func _on_hand_card_pressed(instance_id: int) -> void:
	if _enemy_turn_running:
		return
	if _select_hand_card_by_instance_id(instance_id, true):
		_play_sfx(&"card_select")


# --- Zvuky a efekty ---

func _get_sfx() -> Node:
	return get_node_or_null("/root/Sfx")


func _play_sfx(sound_id: StringName) -> void:
	var sfx := _get_sfx()
	if sfx != null:
		sfx.play(sound_id)


# Efekt na slot se spustí až po nejbližším _refresh_ui (deferred), aby animoval nový stav.
func _queue_lane_fx(owner_id: int, lane_index: int, method: StringName, args: Array = []) -> void:
	if not _pace_actions:
		return
	var views: Array[LaneSlotView] = _player_lanes if owner_id == PLAYER_ID else _enemy_lanes
	if lane_index < 0 or lane_index >= views.size():
		return
	views[lane_index].callv.call_deferred(method, args)


func _pace_pause(seconds: float) -> void:
	if _pace_actions and is_inside_tree():
		await get_tree().create_timer(seconds).timeout


func _on_lane_card_dropped(instance_id: int, lane_index: int, owner_id: int) -> void:
	if not _select_hand_card_by_instance_id(instance_id, false):
		return
	_on_lane_pressed(lane_index, owner_id)


func _on_table_power_button_pressed() -> void:
	if _battle_state == null or _battle_state.battle_over or _battle_state.active_player_id != PLAYER_ID:
		return

	var player_state: PlayerBattleState = _battle_state.get_player_state(PLAYER_ID)
	var enemy_state: PlayerBattleState = _battle_state.get_enemy_state(PLAYER_ID)
	var power_definition := _get_table_power_definition(player_state)
	if player_state == null or enemy_state == null or power_definition == null:
		return

	if not _can_use_table_power(player_state, power_definition):
		status_label.text = "%s ještě nejde použít." % power_definition.display_name
		_refresh_ui()
		return

	_selected_card = null
	_selected_attacker = null
	_selected_info_zone = INFO_ZONE_NONE

	if _table_power_requires_lane_selection(power_definition):
		_selected_table_power = null if _selected_table_power == power_definition else power_definition
		if _selected_table_power == null:
			status_label.text = "Výběr Síly stolu zrušen."
		else:
			status_label.text = "%s vybraná. Klikni na volnou lajnu." % power_definition.display_name
	else:
		_selected_table_power = null
		status_label.text = _activate_table_power(player_state, enemy_state, power_definition)

	_refresh_ui()


func _build_runtime_style_box(background_color: Color, border_color: Color, corner_radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	return style


func _make_children_click_through(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_make_children_click_through(child)
