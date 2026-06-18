class_name AiController
extends RefCounted

const BattleRules = preload("res://scripts/card_game/systems/battle_rules.gd")
const CardEffect = preload("res://scripts/card_game/data/card_effect.gd")
const CardGameConstants = preload("res://scripts/card_game/data/card_game_constants.gd")
const CardInstance = preload("res://scripts/card_game/runtime/card_instance.gd")
const PlayerBattleState = preload("res://scripts/card_game/runtime/player_battle_state.gd")
const TablePowerDefinition = preload("res://scripts/card_game/data/table_power_definition.gd")

const NEGATIVE_SCORE := -1000000.0
const TABLE_POWER_MIN_SCORE := 4.0


func choose_play(player_state: PlayerBattleState, defender_state: PlayerBattleState, rules: BattleRules) -> Dictionary:
    var best_choice: Dictionary = {}
    var best_score := NEGATIVE_SCORE

    for card in player_state.hand:
        if card == null or card.definition == null:
            continue
        if player_state.tuna_current < card.definition.cost:
            continue

        match card.definition.card_type:
            CardGameConstants.CardType.CAT:
                var valid_lanes := rules.get_valid_play_lanes(card, player_state)
                for lane_index in valid_lanes:
                    var score := _score_play(card, lane_index, player_state, defender_state, rules)
                    if score > best_score:
                        best_score = score
                        best_choice = {
                            "card": card,
                            "lane_index": lane_index,
                            "play_type": "lane",
                        }
            CardGameConstants.CardType.TRICK, CardGameConstants.CardType.ITEM:
                var support_choice := _choose_support_play(card, player_state, defender_state, rules)
                if support_choice.is_empty():
                    continue
                var score := float(support_choice.get("score", NEGATIVE_SCORE))
                if score > best_score:
                    best_score = score
                    best_choice = support_choice
                    best_choice["card"] = card

    return best_choice


func choose_attack_action(attacker_state: PlayerBattleState, defender_state: PlayerBattleState, rules: BattleRules) -> Dictionary:
    var best_action: Dictionary = {}
    var best_score := NEGATIVE_SCORE

    for slot in attacker_state.board:
        if slot == null or slot.occupant == null:
            continue

        var attacker: CardInstance = slot.occupant
        var valid_lanes := rules.get_valid_attack_lanes(attacker, defender_state)
        for lane_index in valid_lanes:
            var score := _score_attack_option(attacker, lane_index, defender_state, rules)
            if score > best_score:
                best_score = score
                best_action = {
                    "attacker": attacker,
                    "lane_index": lane_index,
                }

    return best_action


func choose_table_power(player_state: PlayerBattleState, defender_state: PlayerBattleState, power_definition: TablePowerDefinition, rules: BattleRules) -> Dictionary:
    if power_definition == null:
        return {}
    if player_state.table_power_used_this_turn or player_state.tuna_current < power_definition.cost:
        return {}

    var choice := _build_table_power_choice(player_state, defender_state, power_definition, rules)
    if choice.is_empty():
        return {}

    var adjusted_score := float(choice.get("score", NEGATIVE_SCORE)) - float(power_definition.cost) * 0.5
    if adjusted_score < TABLE_POWER_MIN_SCORE:
        return {}

    choice.erase("score")
    return choice


func _score_play(card: CardInstance, lane_index: int, player_state: PlayerBattleState, defender_state: PlayerBattleState, rules: BattleRules) -> float:
    var score := 0.0
    score += float(card.current_attack) * 2.0
    score += float(card.current_life) * 1.4
    score += float(card.definition.cost) * 0.3
    score += _score_tuna_use(card, player_state)
    score += _score_lane_block_value(lane_index, defender_state)
    score += _score_open_lane_pressure(lane_index, defender_state)
    score += _score_guard_cover_value(card, lane_index, player_state, defender_state)
    score += _score_keyword_value(card, lane_index, defender_state, rules)
    score += _score_effect_value(card, player_state)
    return score


func _score_tuna_use(card: CardInstance, player_state: PlayerBattleState) -> float:
    if player_state.tuna_current <= 0:
        return 0.0
    return (float(card.definition.cost) / float(player_state.tuna_current)) * 1.6


func _score_lane_block_value(lane_index: int, defender_state: PlayerBattleState) -> float:
    var slot = defender_state.board[lane_index]
    if slot == null or slot.occupant == null:
        return 0.0

    var target: CardInstance = slot.occupant
    var score := 4.0 + float(target.current_attack) * 2.2
    if target.has_keyword(CardGameConstants.KEYWORD_POUNCE):
        score += 2.0
    if target.has_keyword(CardGameConstants.KEYWORD_QUICK_PAWS):
        score += 1.5
    return score


func _score_open_lane_pressure(lane_index: int, defender_state: PlayerBattleState) -> float:
    var slot = defender_state.board[lane_index]
    if slot != null and slot.occupant == null:
        return 4.5
    return 0.0


func _score_guard_cover_value(card: CardInstance, lane_index: int, player_state: PlayerBattleState, defender_state: PlayerBattleState) -> float:
    if not card.has_keyword(CardGameConstants.KEYWORD_GUARD):
        return 0.0

    var score := 2.0
    for covered_lane in _covered_lane_indexes(lane_index, player_state.board.size()):
        if covered_lane == lane_index:
            continue
        var ally_slot = player_state.board[covered_lane]
        var enemy_slot = defender_state.board[covered_lane]
        if ally_slot == null or enemy_slot == null:
            continue
        if ally_slot.occupant == null and enemy_slot.occupant != null:
            score += 6.0 + float(enemy_slot.occupant.current_attack) * 2.0
    return score


func _score_keyword_value(card: CardInstance, lane_index: int, defender_state: PlayerBattleState, rules: BattleRules) -> float:
    var score := 0.0

    if card.has_keyword(CardGameConstants.KEYWORD_QUICK_PAWS):
        score += 3.0
        score += _score_immediate_attack_value(card, lane_index, defender_state, rules) * 0.7

    if card.has_keyword(CardGameConstants.KEYWORD_POUNCE):
        score += 2.0
        if not card.has_keyword(CardGameConstants.KEYWORD_QUICK_PAWS):
            score += _score_future_pounce_value(lane_index, defender_state)

    if card.has_keyword(CardGameConstants.KEYWORD_GUARD):
        score += 2.0

    return score


func _score_future_pounce_value(lane_index: int, defender_state: PlayerBattleState) -> float:
    var score := 0.0
    for target_lane in _get_attack_lanes_from_position(lane_index, true, defender_state.board.size()):
        var slot = defender_state.board[target_lane]
        if slot == null:
            continue
        if slot.occupant == null:
            score = maxf(score, 2.0)
            continue
        score = maxf(score, 3.0 + float(slot.occupant.current_attack))
    return score


func _score_effect_value(card: CardInstance, player_state: PlayerBattleState) -> float:
    var score := 0.0

    for effect in card.definition.effects:
        if effect == null:
            continue

        if effect.trigger == CardGameConstants.TRIGGER_BATTLECRY:
            match effect.action:
                &"draw_cards":
                    score += float(effect.value) * 4.0
                &"heal_life":
                    if player_state.life <= 4:
                        score += float(effect.value) * 5.0
                    else:
                        score += float(effect.value) * 2.0
        elif effect.trigger == CardGameConstants.TRIGGER_LAST_BREATH:
            match effect.action:
                &"draw_cards":
                    score += float(effect.value) * 1.5
                &"heal_life":
                    score += float(effect.value) * 1.2

    return score


func _choose_support_play(card: CardInstance, player_state: PlayerBattleState, defender_state: PlayerBattleState, rules: BattleRules) -> Dictionary:
    var best_choice: Dictionary = {}
    var best_score := NEGATIVE_SCORE

    var valid_friendly_targets := rules.get_valid_card_target_lanes(card, player_state, defender_state, player_state.player_id)
    for lane_index in valid_friendly_targets:
        var slot = player_state.board[lane_index]
        if slot == null or slot.occupant == null:
            continue
        var score := _score_support_target(card, slot.occupant, player_state.player_id, player_state, defender_state, rules)
        if score > best_score:
            best_score = score
            best_choice = {
                "play_type": "targeted",
                "lane_index": lane_index,
                "target_owner_id": player_state.player_id,
                "score": score,
            }

    var valid_enemy_targets := rules.get_valid_card_target_lanes(card, player_state, defender_state, defender_state.player_id)
    for lane_index in valid_enemy_targets:
        var slot = defender_state.board[lane_index]
        if slot == null or slot.occupant == null:
            continue
        var score := _score_support_target(card, slot.occupant, defender_state.player_id, player_state, defender_state, rules)
        if score > best_score:
            best_score = score
            best_choice = {
                "play_type": "targeted",
                "lane_index": lane_index,
                "target_owner_id": defender_state.player_id,
                "score": score,
            }

    if best_choice.is_empty():
        var instant_score := _score_instant_support(card, player_state, defender_state)
        if instant_score > NEGATIVE_SCORE:
            best_choice = {
                "play_type": "instant",
                "score": instant_score,
            }

    return best_choice


func _score_support_target(card: CardInstance, target: CardInstance, target_owner_id: int, player_state: PlayerBattleState, defender_state: PlayerBattleState, rules: BattleRules) -> float:
    var score := _score_tuna_use(card, player_state) + float(card.definition.cost) * 0.25

    for effect in card.definition.effects:
        if effect == null:
            continue

        match effect.action:
            &"modify_attack":
                if target_owner_id != player_state.player_id:
                    score -= 1000.0
                    continue
                var attack_bonus := float(effect.value) * 2.5
                if target.can_attack and not target.has_attacked:
                    attack_bonus += float(effect.value) * 4.0
                elif target.has_keyword(CardGameConstants.KEYWORD_QUICK_PAWS):
                    attack_bonus += float(effect.value) * 3.0
                if target.has_keyword(CardGameConstants.KEYWORD_POUNCE):
                    attack_bonus += 2.0
                score += attack_bonus
            &"modify_life":
                if target_owner_id != player_state.player_id:
                    score -= 1000.0
                    continue
                var missing_life := maxi(0, target.definition.life - target.current_life)
                score += float(effect.value) * 2.0 + float(missing_life) * 3.0
                if target.has_keyword(CardGameConstants.KEYWORD_GUARD):
                    score += 2.0
            &"ready_attack":
                if target_owner_id != player_state.player_id:
                    score -= 1000.0
                    continue
                if not target.can_attack or target.has_attacked:
                    score += float(target.current_attack) * 6.0
                    if target.has_keyword(CardGameConstants.KEYWORD_POUNCE):
                        score += 2.0
                    score += _score_immediate_attack_value(target, target.lane_index, defender_state, rules) * 0.8
                else:
                    score += 1.0
            &"deal_damage":
                if target_owner_id != defender_state.player_id:
                    score -= 1000.0
                    continue
                score += _score_damage_support_target(effect.value, target)
            &"return_to_hand":
                if target_owner_id != defender_state.player_id:
                    score -= 1000.0
                    continue
                score += _score_bounce_support_target(target, effect.value)

    return score


func _score_instant_support(card: CardInstance, player_state: PlayerBattleState, defender_state: PlayerBattleState) -> float:
    var score := NEGATIVE_SCORE

    for effect in card.definition.effects:
        if effect == null:
            continue
        if score <= NEGATIVE_SCORE:
            score = _score_tuna_use(card, player_state)

        match effect.action:
            &"draw_cards":
                if effect.target_mode == CardGameConstants.TARGET_SELF_OWNER:
                    score += float(effect.value) * 4.0
            &"heal_life":
                if effect.target_mode == CardGameConstants.TARGET_SELF_OWNER:
                    score += float(effect.value) * (5.0 if player_state.life <= 5 else 2.0)
            &"deal_damage":
                if effect.target_mode == CardGameConstants.TARGET_ENEMY_PLAYER:
                    score += float(effect.value) * 6.0

    return score


func _score_damage_support_target(damage: int, target: CardInstance) -> float:
    var score := float(target.current_attack) * 4.0 + float(target.current_life) * 1.5
    if damage >= target.current_life:
        score += 12.0
    else:
        score += float(damage) * 1.2

    if target.has_keyword(CardGameConstants.KEYWORD_GUARD):
        score += 6.0
    if target.has_keyword(CardGameConstants.KEYWORD_POUNCE):
        score += 3.0
    if target.has_keyword(CardGameConstants.KEYWORD_QUICK_PAWS):
        score += 2.5
    if target.has_keyword(CardGameConstants.KEYWORD_LAST_BREATH):
        score -= 2.0

    return score


func _score_bounce_support_target(target: CardInstance, max_cost: int) -> float:
    if max_cost > 0 and target.definition.cost > max_cost:
        return NEGATIVE_SCORE

    var score := float(target.definition.cost) * 5.0
    score += float(target.current_attack) * 2.0
    if target.has_keyword(CardGameConstants.KEYWORD_GUARD):
        score += 4.0
    if target.has_keyword(CardGameConstants.KEYWORD_POUNCE):
        score += 2.0
    return score


func _score_immediate_attack_value(card: CardInstance, lane_index: int, defender_state: PlayerBattleState, rules: BattleRules) -> float:
    var best_score := 0.0
    for target_lane in _get_attack_lanes_from_position(lane_index, card.has_keyword(CardGameConstants.KEYWORD_POUNCE), defender_state.board.size()):
        best_score = maxf(best_score, _score_attack_option_for_lane(card, target_lane, defender_state, rules))
    return best_score


func _get_attack_lanes_from_position(lane_index: int, has_pounce: bool, lane_count: int) -> Array[int]:
    var lanes: Array[int] = [lane_index]
    if has_pounce:
        if lane_index > 0:
            lanes.append(lane_index - 1)
        if lane_index < lane_count - 1:
            lanes.append(lane_index + 1)
    return lanes


func _covered_lane_indexes(lane_index: int, lane_count: int) -> Array[int]:
    var lanes: Array[int] = [lane_index]
    if lane_index > 0:
        lanes.append(lane_index - 1)
    if lane_index < lane_count - 1:
        lanes.append(lane_index + 1)
    return lanes


func _score_attack_option(attacker: CardInstance, lane_index: int, defender_state: PlayerBattleState, rules: BattleRules) -> float:
    return _score_attack_option_for_lane(attacker, lane_index, defender_state, rules)


func _score_attack_option_for_lane(attacker: CardInstance, lane_index: int, defender_state: PlayerBattleState, rules: BattleRules) -> float:
    var slot = defender_state.board[lane_index]
    if slot != null and slot.occupant != null:
        return _score_target_card(attacker, slot.occupant)

    var guard_target: CardInstance = rules.find_guard_for_direct_damage(defender_state, lane_index)
    if guard_target != null:
        return _score_target_card(attacker, guard_target) + 4.0

    var score := float(attacker.current_attack) * 8.0 + 6.0
    if attacker.current_attack >= defender_state.life:
        score += 1000.0
    elif attacker.current_attack >= defender_state.life - 2:
        score += 10.0
    return score


func _score_target_card(attacker: CardInstance, target: CardInstance) -> float:
    var score := float(target.current_attack) * 4.0
    score += float(target.current_life) * 1.5

    if attacker.current_attack >= target.current_life:
        score += 12.0
    else:
        score += float(attacker.current_attack) * 1.2

    if target.has_keyword(CardGameConstants.KEYWORD_GUARD):
        score += 6.0
    if target.has_keyword(CardGameConstants.KEYWORD_POUNCE):
        score += 3.0
    if target.has_keyword(CardGameConstants.KEYWORD_QUICK_PAWS):
        score += 2.5
    if target.has_keyword(CardGameConstants.KEYWORD_LAST_BREATH):
        score -= 2.0

    return score


func _build_table_power_choice(player_state: PlayerBattleState, defender_state: PlayerBattleState, power_definition: TablePowerDefinition, rules: BattleRules) -> Dictionary:
    if _table_power_requires_lane_selection(power_definition):
        return _choose_lane_targeted_table_power(player_state, defender_state, power_definition, rules)

    var score := _score_table_power(power_definition, -1, player_state, defender_state, rules)
    if score <= NEGATIVE_SCORE:
        return {}

    return {
        "use_power": true,
        "score": score,
    }


func _table_power_requires_lane_selection(power_definition: TablePowerDefinition) -> bool:
    if power_definition == null:
        return false

    for effect in power_definition.effects:
        var typed_effect: CardEffect = effect
        if typed_effect != null and typed_effect.action == &"summon_token" and typed_effect.target_mode == CardGameConstants.TARGET_SELF_OWNER:
            return true

    return false


func _choose_lane_targeted_table_power(player_state: PlayerBattleState, defender_state: PlayerBattleState, power_definition: TablePowerDefinition, rules: BattleRules) -> Dictionary:
    var best_lane := -1
    var best_score := NEGATIVE_SCORE

    for slot in player_state.board:
        if slot == null or not slot.is_empty():
            continue

        var lane_index := slot.lane_index
        var score := _score_table_power(power_definition, lane_index, player_state, defender_state, rules)
        if score > best_score:
            best_score = score
            best_lane = lane_index

    if best_lane < 0 or best_score <= NEGATIVE_SCORE:
        return {}

    return {
        "use_power": true,
        "lane_index": best_lane,
        "score": best_score,
    }


func _score_table_power(power_definition: TablePowerDefinition, lane_index: int, player_state: PlayerBattleState, defender_state: PlayerBattleState, rules: BattleRules) -> float:
    var score := 0.0
    var found_effect := false

    for effect in power_definition.effects:
        var typed_effect: CardEffect = effect
        if typed_effect == null:
            continue
        found_effect = true
        score += _score_table_power_effect(typed_effect, lane_index, player_state, defender_state, rules)

    if not found_effect:
        return NEGATIVE_SCORE

    return score


func _score_table_power_effect(effect: CardEffect, lane_index: int, player_state: PlayerBattleState, defender_state: PlayerBattleState, rules: BattleRules) -> float:
    match effect.action:
        &"summon_token":
            if effect.target_mode != CardGameConstants.TARGET_SELF_OWNER:
                return 0.0
            if lane_index < 0 or lane_index >= player_state.board.size():
                return NEGATIVE_SCORE
            var slot = player_state.board[lane_index]
            if slot == null or not slot.is_empty():
                return NEGATIVE_SCORE
            return _score_summon_token_lane(lane_index, player_state, defender_state, rules)
        &"reveal_random_hand_card":
            var target_state = defender_state if effect.target_mode == CardGameConstants.TARGET_ENEMY_PLAYER else player_state
            if target_state == null or target_state.hand.is_empty():
                return 0.0
            return 4.5 + float(min(target_state.hand.size(), 3)) * 0.75
        &"heal_life":
            if effect.target_mode != CardGameConstants.TARGET_SELF_OWNER:
                return 0.0
            return _score_heal_life_effect(player_state.life, effect.value)
        &"draw_cards":
            if effect.target_mode == CardGameConstants.TARGET_SELF_OWNER:
                return float(effect.value) * 4.0
        &"deal_damage":
            if effect.target_mode == CardGameConstants.TARGET_ENEMY_PLAYER:
                var score := float(effect.value) * 6.0
                if effect.value >= defender_state.life:
                    score += 1000.0
                elif effect.value >= defender_state.life - 2:
                    score += 8.0
                return score

    return 0.0


func _score_summon_token_lane(lane_index: int, player_state: PlayerBattleState, defender_state: PlayerBattleState, rules: BattleRules) -> float:
    var score := 2.0
    var enemy_slot = defender_state.board[lane_index]
    if enemy_slot != null and enemy_slot.occupant != null:
        score += 7.0 + float(enemy_slot.occupant.current_attack) * 2.5
        if enemy_slot.occupant.has_keyword(CardGameConstants.KEYWORD_POUNCE):
            score += 2.0
        if enemy_slot.occupant.has_keyword(CardGameConstants.KEYWORD_QUICK_PAWS):
            score += 1.5
    else:
        score += 1.0

    if rules.find_guard_for_direct_damage(player_state, lane_index) == null:
        score += 1.0

    return score


func _score_heal_life_effect(current_life: int, heal_amount: int) -> float:
    if heal_amount <= 0:
        return 0.0
    if current_life <= 4:
        return float(heal_amount) * 7.0
    if current_life <= 7:
        return float(heal_amount) * 5.5
    return float(heal_amount) * 1.5
