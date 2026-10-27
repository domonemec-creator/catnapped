class_name BattleRules
extends RefCounted

const CardGameConstants = preload("res://scripts/card_game/data/card_game_constants.gd")
const CardInstance = preload("res://scripts/card_game/runtime/card_instance.gd")
const LaneSlotState = preload("res://scripts/card_game/runtime/lane_slot_state.gd")
const PlayerBattleState = preload("res://scripts/card_game/runtime/player_battle_state.gd")


func card_uses_saved_tuna(card_instance: CardInstance) -> bool:
    return card_instance != null and card_instance.definition != null and card_instance.definition.card_type == CardGameConstants.CardType.TRICK


func get_available_tuna_for_card(card_instance: CardInstance, player_state: PlayerBattleState) -> int:
    if card_instance == null or player_state == null:
        return 0
    if card_uses_saved_tuna(card_instance):
        return player_state.tuna_current + player_state.saved_tuna_current
    return player_state.tuna_current


func can_pay_card_cost(card_instance: CardInstance, player_state: PlayerBattleState) -> bool:
    if card_instance == null or card_instance.definition == null or player_state == null:
        return false
    return get_available_tuna_for_card(card_instance, player_state) >= card_instance.definition.cost


func build_card_cost_payment(card_instance: CardInstance, player_state: PlayerBattleState) -> Dictionary:
    if not can_pay_card_cost(card_instance, player_state):
        return {}

    var cost := card_instance.definition.cost
    var saved_spent := 0
    if card_uses_saved_tuna(card_instance):
        saved_spent = mini(player_state.saved_tuna_current, cost)
    var normal_spent := cost - saved_spent
    return {
        "total_cost": cost,
        "saved_spent": saved_spent,
        "normal_spent": normal_spent,
    }


func get_valid_play_lanes(card_instance: CardInstance, player_state: PlayerBattleState) -> Array[int]:
    var valid_lanes: Array[int] = []
    if card_instance == null or card_instance.definition.card_type != CardGameConstants.CardType.CAT:
        return valid_lanes
    if not can_pay_card_cost(card_instance, player_state):
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
            &"modify_attack", &"modify_life", &"ready_attack", &"grant_keyword":
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


# Kočka, která útok v lajně schytá jako první; null = útok jde dál (Ochrana, jinak soupeř).
# Plíživost (D-031) přeskočí kočku bez Ochrany.
func get_lane_defender(attacker: CardInstance, defender_state: PlayerBattleState, lane_index: int) -> CardInstance:
    var slot: LaneSlotState = defender_state.board[lane_index]
    if slot == null or slot.occupant == null:
        return null
    if attacker != null and attacker.has_keyword(CardGameConstants.KEYWORD_SNEAK) and not slot.occupant.has_keyword(CardGameConstants.KEYWORD_GUARD):
        return null
    return slot.occupant


func find_guard_for_direct_damage(defender_state: PlayerBattleState, lane_index: int) -> CardInstance:
    var candidate_indexes := [lane_index]
    # D-019: Ochrana může krýt i sousední lajny (přepínač kvůli A/B simulaci).
    if CardGameConstants.guard_covers_adjacent:
        if lane_index > 0:
            candidate_indexes.append(lane_index - 1)
        if lane_index < defender_state.board.size() - 1:
            candidate_indexes.append(lane_index + 1)

    for candidate_index in candidate_indexes:
        var slot: LaneSlotState = defender_state.board[candidate_index]
        if slot != null and slot.occupant != null and slot.occupant.has_keyword(CardGameConstants.KEYWORD_GUARD):
            return slot.occupant

    return null
