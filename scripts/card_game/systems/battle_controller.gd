class_name BattleController
extends Control

const AiController = preload("res://scripts/card_game/systems/ai_controller.gd")
const BattleRules = preload("res://scripts/card_game/systems/battle_rules.gd")
const BattleState = preload("res://scripts/card_game/runtime/battle_state.gd")
const CardDefinition = preload("res://scripts/card_game/data/card_definition.gd")
const CardEffect = preload("res://scripts/card_game/data/card_effect.gd")
const CardGameConstants = preload("res://scripts/card_game/data/card_game_constants.gd")
const CardInstance = preload("res://scripts/card_game/runtime/card_instance.gd")
const CardView = preload("res://scripts/card_game/ui/card_view.gd")
const DeckDefinition = preload("res://scripts/card_game/data/deck_definition.gd")
const DeckSystem = preload("res://scripts/card_game/systems/deck_system.gd")
const EncounterDefinition = preload("res://scripts/card_game/data/encounter_definition.gd")
const LaneSlotState = preload("res://scripts/card_game/runtime/lane_slot_state.gd")
const LaneSlotView = preload("res://scripts/card_game/ui/lane_slot_view.gd")
const PlayerBattleState = preload("res://scripts/card_game/runtime/player_battle_state.gd")
const ProgressionSystem = preload("res://scripts/card_game/systems/progression_system.gd")
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
const PLAYER_TABLE_POWER_ID := &"treat_toss"
const ENCOUNTER_PATH := "res://data/encounters/smug_tabby.tres"
const DEFAULT_ENCOUNTER_ID := &"smug_tabby"
const ENCOUNTER_SELECT_SCENE_PATH := "res://scenes/card_game/encounter_select.tscn"
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

@onready var enemy_portrait_art: TextureRect = $Margin/Layout/TopRow/BoardColumn/EnemyHeader/EnemyPortrait/PortraitArt
@onready var enemy_portrait_frame: TextureRect = $Margin/Layout/TopRow/BoardColumn/EnemyHeader/EnemyPortrait/PortraitFrame
@onready var enemy_name_label: Label = $Margin/Layout/TopRow/BoardColumn/EnemyHeader/EnemyName
@onready var enemy_life_label: Label = $Margin/Layout/TopRow/BoardColumn/EnemyHeader/EnemyLife
@onready var enemy_tuna_label: Label = $Margin/Layout/TopRow/BoardColumn/EnemyHeader/EnemyTuna
@onready var player_life_label: Label = $Margin/Layout/BottomBar/PlayerStats/MarginContainer/VBox/PlayerLife
@onready var player_tuna_label: Label = $Margin/Layout/BottomBar/PlayerStats/MarginContainer/VBox/PlayerTuna
@onready var deck_count_label: Label = $Margin/Layout/BottomBar/DeckPanel/MarginContainer/VBox/DeckCount
@onready var discard_count_label: Label = $Margin/Layout/BottomBar/DiscardPanel/MarginContainer/VBox/DiscardCount
@onready var hand_count_label: Label = $Margin/Layout/BottomBar/HandPanel/MarginContainer/VBox/HandHeader/HandCount
@onready var hand_row: HBoxContainer = $Margin/Layout/BottomBar/HandPanel/MarginContainer/VBox/HandCards
@onready var selected_card_view: SelectedCardPreview = $Margin/Layout/TopRow/SelectedPanel/Content/TopZone/SelectedCardView
@onready var selected_card_title: Label = $Margin/Layout/TopRow/SelectedPanel/Content/TitleBanner/SelectedTitle
@onready var selected_card_detail: Label = $Margin/Layout/TopRow/SelectedPanel/Content/BottomZone/SelectedDetail
@onready var table_power_button: Button = $Margin/Layout/TopRow/SelectedPanel/Content/BottomZone/TablePowerButton
@onready var status_label: Label = $Margin/Layout/TopRow/BoardColumn/StatusLabel
@onready var end_turn_button: Button = $Margin/Layout/TopRow/SelectedPanel/Content/BottomZone/EndTurnButton
@onready var post_match_overlay: Control = $PostMatchOverlay
@onready var post_match_backdrop_art: TextureRect = $PostMatchOverlay/BackdropArt
@onready var post_match_panel_frame: TextureRect = $PostMatchOverlay/Center/Panel/FrameArt
@onready var post_match_result_emblem: TextureRect = $PostMatchOverlay/Center/Panel/MarginContainer/VBox/ResultEmblem
@onready var post_match_result_title: Label = $PostMatchOverlay/Center/Panel/MarginContainer/VBox/ResultTitle
@onready var post_match_result_summary: Label = $PostMatchOverlay/Center/Panel/MarginContainer/VBox/ResultSummary
@onready var post_match_threat_badge: TextureRect = $PostMatchOverlay/Center/Panel/MarginContainer/VBox/ThreatRow/ThreatBadge
@onready var post_match_threat_summary: Label = $PostMatchOverlay/Center/Panel/MarginContainer/VBox/ThreatRow/ThreatSummary
@onready var post_match_deck_shift_detail: Label = $PostMatchOverlay/Center/Panel/MarginContainer/VBox/DeckShiftDetail
@onready var post_match_record_label: Label = $PostMatchOverlay/Center/Panel/MarginContainer/VBox/RecordLabel
@onready var post_match_rematch_button: Button = $PostMatchOverlay/Center/Panel/MarginContainer/VBox/Buttons/RematchButton
@onready var post_match_choose_encounter_button: Button = $PostMatchOverlay/Center/Panel/MarginContainer/VBox/Buttons/ChooseEncounterButton

var _enemy_lanes: Array[LaneSlotView] = []
var _player_lanes: Array[LaneSlotView] = []
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
var _next_instance_id: int = 1

var _deck_system := DeckSystem.new()
var _battle_rules := BattleRules.new()
var _ai_controller := AiController.new()
var _progression_system := ProgressionSystem.new()
var _progression_state: Dictionary = {}
var _postmatch_victory_emblem_texture: Texture2D
var _postmatch_defeat_emblem_texture: Texture2D
var _postmatch_threat_badge_texture: Texture2D
var _postmatch_smug_tabby_art_texture: Texture2D
var _encounter_backdrop_texture: Texture2D
var _postmatch_panel_frame_texture: Texture2D
var _portrait_frame_gold_texture: Texture2D
var _portrait_frame_green_texture: Texture2D
var _portrait_frame_red_texture: Texture2D


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
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
        _enemy_lanes[lane_index].configure(lane_index, ENEMY_ID, "Enemy %s" % (lane_index + 1), "Open — direct hit")
        _player_lanes[lane_index].configure(lane_index, PLAYER_ID, "Player %s" % (lane_index + 1), "Play a cat")
        _enemy_lanes[lane_index].slot_pressed.connect(_on_lane_pressed)
        _player_lanes[lane_index].slot_pressed.connect(_on_lane_pressed)

    selected_card_view.set_interactive(false)
    table_power_button.pressed.connect(_on_table_power_button_pressed)
    end_turn_button.pressed.connect(_on_end_turn_pressed)
    post_match_rematch_button.pressed.connect(_on_rematch_button_pressed)
    post_match_choose_encounter_button.pressed.connect(_on_choose_encounter_button_pressed)

    _load_libraries()
    _setup_battle()
    _refresh_ui()


func _load_libraries() -> void:
    _card_library = _load_resources_by_id("res://data/cards")
    _deck_library = _load_resources_by_id("res://data/decks")
    _table_power_library = _load_resources_by_id("res://data/table_powers")
    _encounter_library = _load_resources_by_id("res://data/encounters")
    var encounter_id: StringName = startup_encounter_id if startup_encounter_id != &"" else DEFAULT_ENCOUNTER_ID
    _encounter = _encounter_library.get(encounter_id) as EncounterDefinition
    if _encounter == null:
        _encounter = load(ENCOUNTER_PATH) as EncounterDefinition
    _encounter_backdrop_texture = _load_texture(_get_encounter_portrait_path())
    _progression_state = _progression_system.load_state()


func _get_current_threat() -> int:
    return _progression_system.get_threat_level(_progression_state)


func _build_enemy_header_name(display_name: String) -> String:
    return "%s [T%s]" % [display_name, _get_current_threat()]


func _build_opening_status() -> String:
    return "Threat %s (%s). Select a card from hand, place it into a lane, then set up your next attack." % [
        _get_current_threat(),
        _progression_system.get_threat_label(_get_current_threat()),
    ]


func _get_enemy_deck_id() -> StringName:
    if _encounter == null:
        return StringName()
    return _encounter.deck_id


func _hide_post_match_overlay() -> void:
    post_match_overlay.visible = false


func _show_post_match_overlay(result_title: String, result_summary: String, previous_threat: int, next_threat: int, deck_messages: Array[String]) -> void:
    post_match_overlay.visible = true
    post_match_backdrop_art.texture = _get_post_match_backdrop_texture()
    post_match_threat_badge.texture = _postmatch_threat_badge_texture
    post_match_result_title.text = result_title
    post_match_result_summary.text = result_summary
    post_match_threat_summary.text = _build_post_match_threat_text(previous_threat, next_threat)
    post_match_deck_shift_detail.text = _build_post_match_deck_shift_text(deck_messages, previous_threat, next_threat)
    post_match_record_label.text = "Wins %s   Losses %s" % [
        _progression_system.get_win_count(_progression_state),
        _progression_system.get_loss_count(_progression_state),
    ]

    match result_title:
        "Victory":
            post_match_result_emblem.texture = _postmatch_victory_emblem_texture
        "Defeat":
            post_match_result_emblem.texture = _postmatch_defeat_emblem_texture
        _:
            post_match_result_emblem.texture = null

    post_match_result_emblem.visible = post_match_result_emblem.texture != null


func _build_post_match_threat_text(previous_threat: int, next_threat: int) -> String:
    var previous_label := _progression_system.get_threat_label(previous_threat)
    var next_label := _progression_system.get_threat_label(next_threat)
    if previous_threat == next_threat:
        return "Threat stays at %s (%s)." % [next_threat, next_label]
    return "Threat %s (%s) -> %s (%s)." % [previous_threat, previous_label, next_threat, next_label]


func _build_post_match_deck_shift_text(deck_messages: Array[String], previous_threat: int, next_threat: int) -> String:
    if not deck_messages.is_empty():
        return "\n".join(deck_messages)
    if previous_threat == next_threat:
        return "No deck changes. The next rematch uses the same list."
    return "Threat changed, but this bracket keeps the same deck list."


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
    instance.can_attack = card_definition.keywords.has(CardGameConstants.KEYWORD_QUICK_PAWS)
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
    card_instance.attached_item_instance_id = -1
    card_instance.temporary_attack_bonus = 0
    card_instance.temporary_life_bonus = 0
    card_instance.temporary_keywords.clear()


func _clear_end_of_turn_modifiers(player_state: PlayerBattleState) -> void:
    if player_state == null:
        return
    for slot in player_state.board:
        if slot == null or slot.occupant == null:
            continue
        var occupant := slot.occupant
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
    if player_state.tuna_current < card_instance.definition.cost:
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
        return "Hand selection cleared."

    var display_name := card_instance.definition.display_name
    match card_instance.definition.card_type:
        CardGameConstants.CardType.CAT:
            if _battle_rules.get_valid_play_lanes(card_instance, player_state).is_empty():
                return "%s selected, but no player lane is open." % display_name
            return "%s selected. Click an open player lane to play it." % display_name
        CardGameConstants.CardType.TRICK, CardGameConstants.CardType.ITEM:
            if not _card_requires_board_target(card_instance):
                return "%s selected. This card resolves immediately." % display_name

            var valid_friendly_targets := _get_valid_card_target_lanes(card_instance, player_state, enemy_state, player_state.player_id)
            var valid_enemy_targets := _get_valid_card_target_lanes(card_instance, player_state, enemy_state, enemy_state.player_id)
            if valid_friendly_targets.is_empty() and valid_enemy_targets.is_empty():
                return "%s selected, but no valid target is on board." % display_name
            if not valid_friendly_targets.is_empty() and not valid_enemy_targets.is_empty():
                return "%s selected. Click any cat." % display_name
            if not valid_friendly_targets.is_empty():
                return "%s selected. Click a friendly cat." % display_name
            return "%s selected. Click an enemy cat." % display_name

    return "%s selected." % display_name


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
                if typed_effect.value_2 > 0:
                    target_card.temporary_attack_bonus += typed_effect.value
                    summaries.append("%s gains +%s Attack this turn." % [target_card.definition.display_name, typed_effect.value])
                else:
                    summaries.append("%s gains +%s Attack." % [target_card.definition.display_name, typed_effect.value])
            &"modify_life":
                if target_card == null:
                    continue
                _adjust_card_life(target_card, typed_effect.value)
                if typed_effect.value_2 > 0:
                    target_card.temporary_life_bonus += typed_effect.value
                    summaries.append("%s gains +%s Life this turn." % [target_card.definition.display_name, typed_effect.value])
                else:
                    summaries.append("%s gains +%s Life." % [target_card.definition.display_name, typed_effect.value])
            &"deal_damage":
                if target_card == null:
                    continue
                _adjust_card_life(target_card, -typed_effect.value)
                summaries.append("%s takes %s damage." % [target_card.definition.display_name, typed_effect.value])
            &"ready_attack":
                if target_card == null:
                    continue
                target_card.can_attack = true
                target_card.has_attacked = false
                summaries.append("%s is ready to attack again." % target_card.definition.display_name)
            &"return_to_hand":
                if target_card == null:
                    continue
                var target_owner_state := owner_state if target_card.owner_id == owner_state.player_id else opposing_state
                if target_owner_state == null:
                    continue
                var returned_name := target_card.definition.display_name
                _return_card_to_hand(target_owner_state, target_card)
                summaries.append("%s returns to hand." % returned_name)
            &"draw_cards":
                if typed_effect.target_mode == CardGameConstants.TARGET_SELF_OWNER:
                    _deck_system.draw_cards(owner_state, typed_effect.value)
                    summaries.append("%s draws %s card%s." % [owner_state.display_name, typed_effect.value, "" if typed_effect.value == 1 else "s"])
            &"heal_life":
                if typed_effect.target_mode == CardGameConstants.TARGET_SELF_OWNER:
                    _adjust_player_life(owner_state, typed_effect.value)
                    summaries.append("%s heals %s Life." % [owner_state.display_name, typed_effect.value])

    return summaries


func _return_card_to_hand(owner_state: PlayerBattleState, target_card: CardInstance) -> void:
    if owner_state == null or target_card == null or target_card.lane_index < 0:
        return
    var lane_index := target_card.lane_index
    if lane_index >= 0 and lane_index < owner_state.board.size():
        owner_state.board[lane_index].occupant = null
    _reset_card_instance_runtime_state(target_card)
    owner_state.hand.append(target_card)


func _play_targeted_card(owner_state: PlayerBattleState, opposing_state: PlayerBattleState, card_instance: CardInstance, target_card: CardInstance) -> String:
    if owner_state == null or opposing_state == null or card_instance == null:
        return ""

    owner_state.tuna_current -= card_instance.definition.cost
    owner_state.hand.erase(card_instance)

    var lines: Array[String] = ["%s uses %s." % [owner_state.display_name, card_instance.definition.display_name]]
    if card_instance.definition.card_type == CardGameConstants.CardType.ITEM and target_card != null:
        target_card.attached_item_instance_id = card_instance.instance_id
    lines.append_array(_resolve_instant_card_effects(card_instance, owner_state, opposing_state, target_card))
    owner_state.discard.append(card_instance)

    _resolve_deaths(owner_state)
    _resolve_deaths(opposing_state)
    _check_battle_end()
    return " ".join(lines)


func _activate_table_power(user_state: PlayerBattleState, opposing_state: PlayerBattleState, power_definition: TablePowerDefinition, lane_index: int = -1) -> String:
    if user_state == null or power_definition == null:
        return "No table power available."
    if not _can_use_table_power(user_state, power_definition):
        return "%s cannot be used right now." % power_definition.display_name
    if _table_power_requires_lane_selection(power_definition) and not _get_valid_table_power_lanes(power_definition, user_state).has(lane_index):
        return "That lane is not valid for %s." % power_definition.display_name

    user_state.tuna_current -= power_definition.cost
    user_state.table_power_used_this_turn = true

    var lines: Array[String] = ["%s uses %s." % [user_state.display_name, power_definition.display_name]]
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
            token_instance.can_attack = false
            slot.occupant = token_instance
            return "Summons %s into lane %s." % [token_instance.definition.display_name, lane_index + 1]
        &"reveal_random_hand_card":
            var target_state := opposing_state if effect.target_mode == CardGameConstants.TARGET_ENEMY_PLAYER else user_state
            if target_state == null or target_state.hand.is_empty():
                return "Finds no cards to reveal."
            var reveal_index := randi() % target_state.hand.size()
            var revealed_card: CardInstance = target_state.hand[reveal_index]
            return "Reveals %s." % revealed_card.definition.display_name
        &"heal_life":
            if effect.target_mode == CardGameConstants.TARGET_SELF_OWNER:
                user_state.life += effect.value
                return "Heals %s Life." % effect.value

    return ""


func _setup_battle() -> void:
    _hide_post_match_overlay()
    _battle_state = BattleState.new()
    _battle_state.turn_number = 1
    _battle_state.active_player_id = PLAYER_ID
    _battle_state.priority_player_id = PLAYER_ID

    var player_state := PlayerBattleState.new()
    player_state.initialize(PLAYER_ID, "Player", STARTING_LIFE, STARTING_TUNA, PLAYER_TABLE_POWER_ID, LANE_COUNT)

    var enemy_state := PlayerBattleState.new()
    var enemy_name := "NPC Opponent"
    var enemy_life := STARTING_LIFE
    var enemy_power_id := StringName()
    var enemy_deck_id := StringName()
    if _encounter != null:
        enemy_name = _encounter.npc_name
        enemy_life = _encounter.starting_life
        enemy_power_id = _encounter.table_power_id
        enemy_deck_id = _encounter.deck_id
    enemy_state.initialize(ENEMY_ID, enemy_name, enemy_life, STARTING_TUNA, enemy_power_id, LANE_COUNT)

    _next_instance_id = _assign_deck_to_player(player_state, PLAYER_DECK_ID, _next_instance_id)
    _next_instance_id = _assign_deck_to_player(enemy_state, enemy_deck_id, _next_instance_id)

    _battle_state.player_states = [player_state, enemy_state]

    _deck_system.draw_cards(player_state, STARTING_HAND)
    _deck_system.draw_cards(enemy_state, STARTING_HAND)

    enemy_name_label.text = _build_enemy_header_name(enemy_state.display_name)
    enemy_portrait_art.texture = _get_post_match_backdrop_texture()
    status_label.text = _build_opening_status()


func _assign_deck_to_player(player_state: PlayerBattleState, deck_id: StringName, next_instance_id: int) -> int:
    var deck_definition: DeckDefinition = _deck_library.get(deck_id)
    if deck_definition == null:
        push_warning("Missing deck %s." % deck_id)
        return next_instance_id

    var result: Dictionary = {}
    if player_state.player_id == ENEMY_ID:
        var threat_deck_cards := _progression_system.build_enemy_deck_card_ids(deck_definition, _get_current_threat())
        result = _deck_system.build_runtime_deck_from_card_ids(threat_deck_cards, _card_library, player_state.player_id, next_instance_id)
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
        var enemy_state := _battle_state.get_enemy_state(PLAYER_ID)
        var valid_power_lanes := _get_valid_table_power_lanes(_selected_table_power, player_state)
        if valid_power_lanes.has(lane_index):
            status_label.text = _activate_table_power(player_state, enemy_state, _selected_table_power, lane_index)
            _selected_table_power = null
            return
        status_label.text = "That lane is not valid for %s." % _selected_table_power.display_name
        return

    if _selected_card != null:
        var enemy_state := _battle_state.get_enemy_state(PLAYER_ID)
        if _selected_card.definition.card_type == CardGameConstants.CardType.CAT:
            var valid_play_lanes: Array[int] = _battle_rules.get_valid_play_lanes(_selected_card, player_state)
            if valid_play_lanes.has(lane_index):
                _play_card_to_lane(player_state, lane_index, _selected_card)
                _selected_card = null
                _selected_attacker = null
                return
            status_label.text = "That lane is not valid for %s." % _selected_card.definition.display_name
            return

        var slot: LaneSlotState = player_state.board[lane_index]
        if slot != null and slot.occupant != null and _is_valid_card_target(_selected_card, slot.occupant, player_state.player_id, player_state, enemy_state):
            status_label.text = _play_targeted_card(player_state, enemy_state, _selected_card, slot.occupant)
            _clear_selection_state()
            return

        status_label.text = "That target is not valid for %s." % _selected_card.definition.display_name
        return

    var slot: LaneSlotState = player_state.board[lane_index]
    if slot == null or slot.occupant == null:
        _selected_attacker = null
        status_label.text = "Empty player lane. Pick a card from hand or select a ready cat."
        return

    if not slot.occupant.can_attack or slot.occupant.has_attacked:
        _selected_attacker = null
        status_label.text = "%s cannot attack right now." % slot.occupant.definition.display_name
        return

    _selected_table_power = null
    _selected_attacker = null if _selected_attacker == slot.occupant else slot.occupant
    if _selected_attacker == null:
        status_label.text = "Attack selection cleared."
    else:
        status_label.text = "%s selected. Choose an enemy lane to attack." % _selected_attacker.definition.display_name


func _handle_enemy_lane_pressed(lane_index: int) -> void:
    var player_state: PlayerBattleState = _battle_state.get_player_state(PLAYER_ID)
    var enemy_state: PlayerBattleState = _battle_state.get_enemy_state(PLAYER_ID)
    if player_state == null or enemy_state == null:
        return

    if _selected_card != null:
        if _selected_card.definition.card_type == CardGameConstants.CardType.CAT:
            status_label.text = "Cats must be played on your side of the table."
            return

        var slot: LaneSlotState = enemy_state.board[lane_index]
        if slot != null and slot.occupant != null and _is_valid_card_target(_selected_card, slot.occupant, enemy_state.player_id, player_state, enemy_state):
            status_label.text = _play_targeted_card(player_state, enemy_state, _selected_card, slot.occupant)
            _clear_selection_state()
            return

        status_label.text = "That target is not valid for %s." % _selected_card.definition.display_name
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

    slot.occupant = card_instance
    card_instance.lane_index = lane_index
    card_instance.has_attacked = false
    card_instance.can_attack = card_instance.has_keyword(CardGameConstants.KEYWORD_QUICK_PAWS)
    player_state.tuna_current -= card_instance.definition.cost
    player_state.hand.erase(card_instance)
    _resolve_triggered_effects(card_instance, player_state, CardGameConstants.TRIGGER_BATTLECRY)
    status_label.text = "%s enters lane %s." % [card_instance.definition.display_name, lane_index + 1]
    _check_battle_end()


func _perform_attack(attacker_owner_state: PlayerBattleState, defender_state: PlayerBattleState, attacker: CardInstance, target_lane: int) -> String:
    if attacker == null or _battle_state == null or _battle_state.battle_over:
        return ""

    var valid_attack_lanes: Array[int] = _battle_rules.get_valid_attack_lanes(attacker, defender_state)
    if not valid_attack_lanes.has(target_lane):
        return "That lane is not a legal target for %s." % attacker.definition.display_name

    attacker.has_attacked = true
    var target_slot: LaneSlotState = defender_state.board[target_lane]
    var summary := ""

    if target_slot.occupant != null:
        _adjust_card_life(target_slot.occupant, -attacker.current_attack)
        summary = "%s hits %s for %s damage." % [attacker.definition.display_name, target_slot.occupant.definition.display_name, attacker.current_attack]
    else:
        var guard_target: CardInstance = _battle_rules.find_guard_for_direct_damage(defender_state, target_lane)
        if guard_target != null:
            _adjust_card_life(guard_target, -attacker.current_attack)
            summary = "%s lunges through lane %s, but %s intercepts the hit." % [attacker.definition.display_name, target_lane + 1, guard_target.definition.display_name]
        else:
            _adjust_player_life(defender_state, -attacker.current_attack)
            summary = "%s deals %s direct damage." % [attacker.definition.display_name, attacker.current_attack]
            _resolve_triggered_effects(attacker, attacker_owner_state, CardGameConstants.TRIGGER_ON_DIRECT_DAMAGE)

    _resolve_deaths(defender_state)
    _check_battle_end()
    return summary


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
    player_state.life = maxi(0, player_state.life + delta)


func _send_to_discard(owner_state: PlayerBattleState, slot: LaneSlotState) -> void:
    var dead_card: CardInstance = slot.occupant
    slot.occupant = null
    if dead_card == null:
        return

    dead_card.lane_index = -1
    _resolve_triggered_effects(dead_card, owner_state, CardGameConstants.TRIGGER_LAST_BREATH)
    owner_state.discard.append(dead_card)


func _resolve_triggered_effects(card_instance: CardInstance, owner_state: PlayerBattleState, trigger: StringName) -> void:
    for effect in card_instance.definition.effects:
        var typed_effect: CardEffect = effect
        if typed_effect == null or typed_effect.trigger != trigger:
            continue

        match typed_effect.action:
            &"heal_life":
                if typed_effect.target_mode == CardGameConstants.TARGET_SELF_OWNER:
                    owner_state.life += typed_effect.value
            &"draw_cards":
                if typed_effect.target_mode == CardGameConstants.TARGET_SELF_OWNER:
                    _deck_system.draw_cards(owner_state, typed_effect.value)


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
        status_label.text = "Draw. Both sides are out of Life. Threat holds at %s." % _get_current_threat()
        _show_post_match_overlay("Draw", "Both sides collapse at the same time. Nobody takes the table tonight.", previous_threat, previous_threat, [])
        return

    if enemy_state.life <= 0:
        _battle_state.battle_over = true
        _battle_state.winner_player_id = PLAYER_ID
        var victory_state := _progression_system.apply_battle_result(_progression_state, PLAYER_ID, PLAYER_ID, ENEMY_ID)
        var victory_threat := _progression_system.get_threat_level(victory_state)
        var victory_deck_messages := _progression_system.get_threat_transition_messages(_get_enemy_deck_id(), previous_threat, victory_threat)
        _progression_state = victory_state
        _progression_system.save_state(_progression_state)
        enemy_name_label.text = _build_enemy_header_name(enemy_state.display_name)
        status_label.text = "Victory. %s is out of Life. Threat drops to %s." % [enemy_state.display_name, _get_current_threat()]
        _show_post_match_overlay("Victory", "You broke %s and cooled the room down for the next rematch." % enemy_state.display_name, previous_threat, victory_threat, victory_deck_messages)
        return

    if player_state.life <= 0:
        _battle_state.battle_over = true
        _battle_state.winner_player_id = ENEMY_ID
        var defeat_state := _progression_system.apply_battle_result(_progression_state, ENEMY_ID, PLAYER_ID, ENEMY_ID)
        var defeat_threat := _progression_system.get_threat_level(defeat_state)
        var defeat_deck_messages := _progression_system.get_threat_transition_messages(_get_enemy_deck_id(), previous_threat, defeat_threat)
        _progression_state = defeat_state
        _progression_system.save_state(_progression_state)
        enemy_name_label.text = _build_enemy_header_name(enemy_state.display_name)
        status_label.text = "Defeat. Your side is out of Life. Threat rises to %s." % _get_current_threat()
        _show_post_match_overlay("Defeat", "%s keeps the table and comes back nastier next time." % enemy_state.display_name, previous_threat, defeat_threat, defeat_deck_messages)


func _on_end_turn_pressed() -> void:
    if _battle_state == null:
        return

    if _battle_state.battle_over:
        get_tree().reload_current_scene()
        return

    _clear_selection_state()

    var player_state: PlayerBattleState = _battle_state.get_player_state(PLAYER_ID)
    var enemy_state: PlayerBattleState = _battle_state.get_player_state(ENEMY_ID)
    if player_state == null or enemy_state == null:
        return

    _clear_end_of_turn_modifiers(player_state)
    if _battle_state.battle_over:
        _refresh_ui()
        return

    _battle_state.active_player_id = ENEMY_ID
    _start_turn(enemy_state)
    _run_enemy_stub_turn()
    if _battle_state.battle_over:
        _refresh_ui()
        return

    _clear_end_of_turn_modifiers(enemy_state)
    if _battle_state.battle_over:
        _refresh_ui()
        return

    _battle_state.active_player_id = PLAYER_ID
    _battle_state.turn_number += 1
    _start_turn(player_state)
    status_label.text = "Your turn. Play a card, use your Table Power, or attack with a ready cat."
    _refresh_ui()


func _on_rematch_button_pressed() -> void:
    get_tree().reload_current_scene()


func _on_choose_encounter_button_pressed() -> void:
    var packed_scene := load(ENCOUNTER_SELECT_SCENE_PATH) as PackedScene
    if packed_scene == null:
        push_error("Could not load encounter_select.tscn")
        return

    var select_scene := packed_scene.instantiate()
    var tree := get_tree()
    tree.root.add_child(select_scene)
    tree.current_scene = select_scene
    queue_free()


func _start_turn(player_state: PlayerBattleState) -> void:
    player_state.tuna_max = mini(player_state.tuna_max + 1, MAX_TUNA)
    player_state.tuna_current = player_state.tuna_max
    player_state.table_power_used_this_turn = false
    _deck_system.draw_cards(player_state, 1)
    _refresh_attack_state_for_player(player_state)


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
                action_log.append("%s plays %s into lane %s." % [enemy_state.display_name, played_card.definition.display_name, played_lane + 1])
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
        attack_iterations += 1

    if action_log.is_empty():
        status_label.text = "%s passes and watches the table." % enemy_state.display_name
    else:
        status_label.text = " ".join(action_log)


func _refresh_ui() -> void:
    if _battle_state == null:
        return

    var player_state: PlayerBattleState = _battle_state.get_player_state(PLAYER_ID)
    var enemy_state: PlayerBattleState = _battle_state.get_player_state(ENEMY_ID)
    if player_state == null or enemy_state == null:
        return

    enemy_life_label.text = "Life %s" % enemy_state.life
    enemy_tuna_label.text = "Tuna %s/%s" % [enemy_state.tuna_current, enemy_state.tuna_max]
    player_life_label.text = "Life %s" % player_state.life
    player_tuna_label.text = "Tuna %s/%s" % [player_state.tuna_current, player_state.tuna_max]
    deck_count_label.text = str(player_state.deck.size())
    discard_count_label.text = str(player_state.discard.size())
    hand_count_label.text = str(player_state.hand.size())

    _refresh_lanes(_player_lanes, player_state)
    _refresh_lanes(_enemy_lanes, enemy_state)
    _refresh_hand(player_state)
    _refresh_selected_panel()
    _refresh_lane_highlights(player_state, enemy_state)
    _update_turn_indicator()

    if _battle_state.battle_over:
        table_power_button.disabled = true
        table_power_button.text = "Table Power"
        end_turn_button.text = "Restart"
        end_turn_button.disabled = false
    else:
        var player_power := _get_table_power_definition(player_state)
        if player_power == null:
            table_power_button.text = "No Table Power"
            table_power_button.disabled = true
        else:
            var power_label := "%s (%s)" % [player_power.display_name, player_power.cost]
            if player_state.table_power_used_this_turn:
                table_power_button.text = "%s (Used)" % player_power.display_name
            elif _selected_table_power == player_power:
                table_power_button.text = "Cancel %s" % player_power.display_name
            else:
                table_power_button.text = power_label
            table_power_button.disabled = _battle_state.active_player_id != PLAYER_ID or not _can_use_table_power(player_state, player_power)
        end_turn_button.text = "End Turn"
        end_turn_button.disabled = _battle_state.active_player_id != PLAYER_ID


func _refresh_lanes(views: Array[LaneSlotView], player_state: PlayerBattleState) -> void:
    for lane_index in range(views.size()):
        views[lane_index].set_card_instance(player_state.board[lane_index].occupant)


func _refresh_hand(player_state: PlayerBattleState) -> void:
    var enemy_state: PlayerBattleState = _battle_state.get_enemy_state(PLAYER_ID)
    for child in hand_row.get_children():
        child.free()

    for card in player_state.hand:
        var card_view: CardView = CARD_VIEW_SCENE.instantiate()
        hand_row.add_child(card_view)
        card_view.set_card_instance(card)
        card_view.set_selected(card == _selected_card)
        card_view.set_playable(_battle_state.active_player_id == PLAYER_ID and _can_play_card_from_hand(card, player_state, enemy_state))
        card_view.set_interactive(_battle_state.active_player_id == PLAYER_ID and not _battle_state.battle_over)
        card_view.card_pressed.connect(_on_hand_card_pressed)


func _refresh_selected_panel() -> void:
    selected_card_view.set_selected(false)
    selected_card_view.set_playable(false)

    if _selected_table_power != null:
        var player_state: PlayerBattleState = _battle_state.get_player_state(PLAYER_ID)
        selected_card_view.set_card_instance(null)
        selected_card_title.text = "Table Power: %s" % _selected_table_power.display_name
        selected_card_detail.text = _build_table_power_detail(_selected_table_power, player_state)
        return

    if _selected_card != null:
        selected_card_view.set_card_instance(_selected_card)
        selected_card_view.set_selected(true)
        selected_card_title.text = _selected_card.definition.display_name
        selected_card_detail.text = _build_selected_card_extra_detail(_selected_card.definition)
        return

    if _selected_attacker != null:
        var enemy_state: PlayerBattleState = _battle_state.get_player_state(ENEMY_ID)
        selected_card_view.set_card_instance(_selected_attacker)
        selected_card_view.set_selected(true)
        selected_card_title.text = "Attacker: %s" % _selected_attacker.definition.display_name
        selected_card_detail.text = "%s\nValid targets: %s" % [_build_selected_card_extra_detail(_selected_attacker.definition), _format_lane_names(_battle_rules.get_valid_attack_lanes(_selected_attacker, enemy_state))]
        return

    selected_card_view.set_card_instance(null)
    selected_card_title.text = "Selected Card"
    selected_card_detail.text = "Pick a card from your hand to inspect it, use your Table Power, or click a ready cat on your side to choose an attack."


func _build_selected_card_extra_detail(card_definition: CardDefinition) -> String:
    var lines: Array[String] = ["Cost: %s Tuna" % card_definition.cost]
    if not card_definition.keywords.is_empty():
        for keyword in card_definition.keywords:
            lines.append("%s: %s" % [CardGameConstants.keyword_label(keyword), CardGameConstants.keyword_summary(keyword)])
    elif card_definition.effects.is_empty() and card_definition.rules_text.is_empty():
        lines.append("No extra abilities.")
    return "\n".join(lines)


func _refresh_lane_highlights(player_state: PlayerBattleState, enemy_state: PlayerBattleState) -> void:
    for lane_index in range(_player_lanes.size()):
        _player_lanes[lane_index].set_highlight_mode(LaneSlotView.HIGHLIGHT_NONE)
        _enemy_lanes[lane_index].set_highlight_mode(LaneSlotView.HIGHLIGHT_NONE)

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
            for lane_index in _get_valid_card_target_lanes(_selected_card, player_state, enemy_state, enemy_state.player_id):
                _enemy_lanes[lane_index].set_highlight_mode(LaneSlotView.HIGHLIGHT_ATTACK)
        return

    if _selected_attacker != null and _battle_state.active_player_id == PLAYER_ID:
        _player_lanes[_selected_attacker.lane_index].set_highlight_mode(LaneSlotView.HIGHLIGHT_SELECTED)
        var valid_attack_lanes: Array[int] = _battle_rules.get_valid_attack_lanes(_selected_attacker, enemy_state)
        for lane_index in valid_attack_lanes:
            _enemy_lanes[lane_index].set_highlight_mode(LaneSlotView.HIGHLIGHT_ATTACK)


func _update_turn_indicator() -> void:
    if enemy_portrait_frame == null:
        return
    if _battle_state == null or _battle_state.battle_over:
        enemy_portrait_frame.texture = _portrait_frame_gold_texture
    elif _battle_state.active_player_id == PLAYER_ID:
        enemy_portrait_frame.texture = _portrait_frame_green_texture
    else:
        enemy_portrait_frame.texture = _portrait_frame_red_texture


func _on_hand_card_pressed(instance_id: int) -> void:
    if _battle_state == null or _battle_state.battle_over or _battle_state.active_player_id != PLAYER_ID:
        return

    var player_state: PlayerBattleState = _battle_state.get_player_state(PLAYER_ID)
    if player_state == null:
        return

    for card in player_state.hand:
        if card.instance_id != instance_id:
            continue
        _selected_attacker = null
        _selected_table_power = null
        _selected_card = null if _selected_card == card else card
        if _selected_card == null:
            status_label.text = "Hand selection cleared."
        else:
            var enemy_state := _battle_state.get_enemy_state(PLAYER_ID)
            status_label.text = _build_card_selection_message(_selected_card, player_state, enemy_state)
        _refresh_ui()
        return


func _on_table_power_button_pressed() -> void:
    if _battle_state == null or _battle_state.battle_over or _battle_state.active_player_id != PLAYER_ID:
        return

    var player_state: PlayerBattleState = _battle_state.get_player_state(PLAYER_ID)
    var enemy_state: PlayerBattleState = _battle_state.get_enemy_state(PLAYER_ID)
    var power_definition := _get_table_power_definition(player_state)
    if player_state == null or enemy_state == null or power_definition == null:
        return

    if not _can_use_table_power(player_state, power_definition):
        status_label.text = "%s is not ready." % power_definition.display_name
        _refresh_ui()
        return

    _selected_card = null
    _selected_attacker = null

    if _table_power_requires_lane_selection(power_definition):
        _selected_table_power = null if _selected_table_power == power_definition else power_definition
        if _selected_table_power == null:
            status_label.text = "Table Power selection cleared."
        else:
            status_label.text = "%s selected. Click an open player lane." % power_definition.display_name
    else:
        _selected_table_power = null
        status_label.text = _activate_table_power(player_state, enemy_state, power_definition)

    _refresh_ui()


func _build_card_detail(card_definition: CardDefinition) -> String:
    if not card_definition.rules_text.is_empty():
        if card_definition.keywords.is_empty():
            return card_definition.rules_text
        var detail_lines: Array[String] = [card_definition.rules_text]
        for keyword in card_definition.keywords:
            detail_lines.append("%s: %s" % [CardGameConstants.keyword_label(keyword), CardGameConstants.keyword_summary(keyword)])
        return "\n".join(detail_lines)

    if card_definition.keywords.is_empty():
        return "No extra abilities."

    var lines: Array[String] = []
    for keyword in card_definition.keywords:
        lines.append("%s: %s" % [CardGameConstants.keyword_label(keyword), CardGameConstants.keyword_summary(keyword)])
    return "\n".join(lines)


func _build_table_power_detail(power_definition: TablePowerDefinition, player_state: PlayerBattleState) -> String:
    if power_definition == null:
        return "No table power."

    var lines: Array[String] = [power_definition.rules_text]
    lines.append("Cost: %s Tuna" % power_definition.cost)
    if player_state != null:
        if player_state.table_power_used_this_turn:
            lines.append("Status: already used this turn.")
        elif player_state.tuna_current < power_definition.cost:
            lines.append("Status: not enough Tuna.")
        elif _table_power_requires_lane_selection(power_definition):
            lines.append("Valid lanes: %s" % _format_lane_names(_get_valid_table_power_lanes(power_definition, player_state)))
    return "\n".join(lines)


func _format_lane_names(lane_indexes: Array[int]) -> String:
    if lane_indexes.is_empty():
        return "none"

    var lane_names: Array[String] = []
    for lane_index in lane_indexes:
        lane_names.append("Lane %s" % (lane_index + 1))
    return ", ".join(lane_names)
