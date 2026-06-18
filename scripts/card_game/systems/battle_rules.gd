class_name BattleRules
extends RefCounted

const CardGameConstants = preload("res://scripts/card_game/data/card_game_constants.gd")
const CardInstance = preload("res://scripts/card_game/runtime/card_instance.gd")
const LaneSlotState = preload("res://scripts/card_game/runtime/lane_slot_state.gd")
const PlayerBattleState = preload("res://scripts/card_game/runtime/player_battle_state.gd")


func get_valid_play_lanes(card_instance: CardInstance, player_state: PlayerBattleState) -> Array[int]:
    var valid_lanes: Array[int] = []
    if card_instance == null or card_instance.definition.card_type != CardGameConstants.CardType.CAT:
        return valid_lanes
    if player_state.tuna_current < card_instance.definition.cost:
        return valid_lanes

    for slot in player_state.board:
        if slot != null and slot.is_empty():
            valid_lanes.append(slot.lane_index)

    return valid_lanes


func get_valid_card_target_lanes(card_instance: CardInstance, friendly_state: PlayerBattleState, enemy_state: PlayerBattleState, target_owner_id: int) -> Array[int]:
    var valid_lanes: Array[int] = []
    if card_instance == null or card_instance.definition == null:
        return valid_lanes

    var target_state := friendly_state if target_owner_id == friendly_state.player_id else enemy_state
    if target_state == null:
        return valid_lanes

    for slot in target_state.board:
        if slot == null or slot.occupant == null:
            continue
        if is_valid_card_target(card_instance, slot.occupant, target_owner_id, friendly_state, enemy_state):
            valid_lanes.append(slot.lane_index)

    return valid_lanes


func is_valid_card_target(card_instance: CardInstance, target_card: CardInstance, target_owner_id: int, friendly_state: PlayerBattleState, enemy_state: PlayerBattleState) -> bool:
    if card_instance == null or target_card == null:
        return false
    if card_instance.definition.card_type == CardGameConstants.CardType.CAT:
        return false

    for effect in card_instance.definition.effects:
        var typed_effect = effect
        if typed_effect == null:
            continue

        match typed_effect.target_mode:
            CardGameConstants.TARGET_ALLY_CAT:
                if target_owner_id != friendly_state.player_id:
                    continue
            CardGameConstants.TARGET_ENEMY_CAT:
                if target_owner_id != enemy_state.player_id:
                    continue
            CardGameConstants.TARGET_ANY_CAT:
                pass
            _:
                continue

        match typed_effect.action:
            &"modify_attack", &"modify_life", &"ready_attack":
                if card_instance.definition.card_type == CardGameConstants.CardType.ITEM and target_owner_id != friendly_state.player_id:
                    continue
                if card_instance.definition.card_type == CardGameConstants.CardType.ITEM and target_card.attached_item_instance_id >= 0:
                    continue
                return true
            &"deal_damage":
                return true
            &"return_to_hand":
                if typed_effect.value > 0 and target_card.definition.cost > typed_effect.value:
                    continue
                return true
            &"destroy_item":
                if target_card.attached_item == null:
                    continue
                return true
            &"steal_item":
                if target_card.attached_item == null:
                    continue
                if not _has_free_item_host(friendly_state):
                    continue
                return true

    return false


func _has_free_item_host(player_state: PlayerBattleState) -> bool:
    if player_state == null:
        return false
    for slot in player_state.board:
        if slot != null and slot.occupant != null and slot.occupant.attached_item == null:
            return true
    return false


func get_valid_attack_lanes(attacker: CardInstance, defender_state: PlayerBattleState) -> Array[int]:
    var valid_lanes: Array[int] = []
    if attacker == null or not attacker.can_attack or attacker.has_attacked:
        return valid_lanes
    if attacker.lane_index < 0:
        return valid_lanes

    valid_lanes.append(attacker.lane_index)
    if attacker.has_keyword(CardGameConstants.KEYWORD_POUNCE):
        if attacker.lane_index > 0:
            valid_lanes.append(attacker.lane_index - 1)
        if attacker.lane_index < defender_state.board.size() - 1:
            valid_lanes.append(attacker.lane_index + 1)
    return valid_lanes


func find_guard_for_direct_damage(defender_state: PlayerBattleState, lane_index: int) -> CardInstance:
    var candidate_indexes := [lane_index]
    if lane_index > 0:
        candidate_indexes.append(lane_index - 1)
    if lane_index < defender_state.board.size() - 1:
        candidate_indexes.append(lane_index + 1)

    for candidate_index in candidate_indexes:
        var slot: LaneSlotState = defender_state.board[candidate_index]
        if slot != null and slot.occupant != null and slot.occupant.has_keyword(CardGameConstants.KEYWORD_GUARD):
            return slot.occupant

    return null
