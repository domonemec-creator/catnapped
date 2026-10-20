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
        if not rules.can_pay_card_cost(card, player_state):
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
            # S odvetou se nevyplatí každý útok; špatnou výměnu AI vynechá.
            if CardGameConstants.combat_retaliation and score <= 0.0:
                continue
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
    score += _score_open_lane_pressure(card, lane_index, defender_state, rules)
    score += _score_attack_setup_value(card, lane_index, defender_state, rules)
    score += _score_guard_cover_value(card, lane_index, player_state, defender_state)
    score += _score_keyword_value(card, lane_index, defender_state, rules)
    score += _score_effect_value(card, player_state)
    score += _score_lane_effect_value(card, lane_index, player_state, defender_state)
    return score


# Efekty závislé na lajně (nové karty 2026-10-20): zranění kočce naproti, posílení sousedů.
func _score_lane_effect_value(card: CardInstance, lane_index: int, player_state: PlayerBattleState, defender_state: PlayerBattleState) -> float:
    var score := 0.0
    for effect in card.definition.effects:
        if effect == null:
            continue
        if effect.trigger == CardGameConstants.TRIGGER_BATTLECRY and effect.action == &"deal_damage" and effect.target_mode == CardGameConstants.TARGET_OPPOSITE_LANE:
            var target: CardInstance = defender_state.board[lane_index].occupant
            if target != null:
                score += float(mini(effect.value, target.current_life)) * 2.5
                if effect.value >= target.current_life:
                    score += _card_board_value(target)
        elif effect.trigger == CardGameConstants.TRIGGER_BATTLECRY and effect.target_mode == CardGameConstants.TARGET_ADJACENT_LANE:
            for neighbor in [lane_index - 1, lane_index + 1]:
                if neighbor >= 0 and neighbor < player_state.board.size() and player_state.board[neighbor].occupant != null:
                    score += float(effect.value) * 2.0
        elif effect.trigger == CardGameConstants.TRIGGER_LAST_BREATH and effect.action == &"summon_token":
            score += 2.5
        elif effect.trigger == CardGameConstants.TRIGGER_ON_DIRECT_DAMAGE:
            score += 2.0
    return score


func _score_tuna_use(card: CardInstance, player_state: PlayerBattleState) -> float:
    if card == null or player_state == null:
        return 0.0
    var available_tuna := player_state.tuna_current
    if card.definition.card_type == CardGameConstants.CardType.TRICK:
        available_tuna += player_state.saved_tuna_current
    if available_tuna <= 0:
        return 0.0
    return (float(card.definition.cost) / float(available_tuna)) * 1.6


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


func _score_open_lane_pressure(card: CardInstance, lane_index: int, defender_state: PlayerBattleState, rules: BattleRules) -> float:
    var slot = defender_state.board[lane_index]
    if slot != null and slot.occupant == null:
        var score := 4.5 + float(card.current_attack) * 1.4
        if _lane_is_open_for_direct_damage(lane_index, defender_state, rules):
            score += 2.0
            if card.current_attack >= defender_state.life:
                score += 40.0
            elif card.current_attack >= defender_state.life - 2:
                score += 8.0
        return score
    return 0.0


func _score_attack_setup_value(card: CardInstance, lane_index: int, defender_state: PlayerBattleState, rules: BattleRules) -> float:
    if card == null or card.definition == null:
        return 0.0

    if card.has_keyword(CardGameConstants.KEYWORD_QUICK_PAWS):
        return _score_attack_option_for_lane_with_attack(card, lane_index, card.current_attack, defender_state, rules) * 0.45

    if not _lane_is_open_for_direct_damage(lane_index, defender_state, rules):
        return 0.0

    var score := float(card.current_attack) * 2.0
    if card.current_attack >= defender_state.life:
        score += 18.0
    elif card.current_attack >= defender_state.life - 2:
        score += 6.0
    return score


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

    if card.has_keyword(CardGameConstants.KEYWORD_FEAST):
        # Sticky long-game value: worth more when the board is contested (more deaths coming).
        score += 2.0
        score += float(_count_board_occupants(defender_state)) * 1.0

    return score


func _count_board_occupants(state: PlayerBattleState) -> int:
    var count := 0
    for slot in state.board:
        if slot != null and slot.occupant != null:
            count += 1
    return count


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
                var can_swing := target.can_attack and not target.has_attacked
                # A "this turn" buff (value_2 > 0) is wasted on a cat that won't attack this turn.
                if effect.value_2 > 0 and not can_swing:
                    score -= 5.0
                    continue
                var attack_bonus := float(effect.value) * 2.5
                if can_swing:
                    attack_bonus += float(effect.value) * 4.0
                elif target.has_keyword(CardGameConstants.KEYWORD_QUICK_PAWS):
                    attack_bonus += float(effect.value) * 3.0
                if target.has_keyword(CardGameConstants.KEYWORD_POUNCE):
                    attack_bonus += 2.0
                attack_bonus += _score_attack_buff_follow_up(target, effect.value, defender_state, rules)
                score += attack_bonus
            &"modify_life":
                if target_owner_id != player_state.player_id:
                    score -= 1000.0
                    continue
                var missing_life := maxi(0, target.definition.life - target.current_life)
                score += float(effect.value) * 2.0 + float(missing_life) * 3.0
                if target.has_keyword(CardGameConstants.KEYWORD_GUARD):
                    score += 2.0
                score += _score_lane_anchor_value(target, defender_state, rules) * 0.8
            &"ready_attack":
                if target_owner_id != player_state.player_id:
                    score -= 1000.0
                    continue
                # No effect on a cat that just entered without an immediate-attack grant
                # (the resolver no-ops it), so never waste the card there.
                if target.entered_this_turn and not target.immediate_entry_attack_granted:
                    score -= 1000.0
                    continue
                if target.has_attacked:
                    # Re-readying a cat that already swung = a genuine extra attack.
                    score += float(target.current_attack) * 6.0
                    if target.has_keyword(CardGameConstants.KEYWORD_POUNCE):
                        score += 2.0
                    score += _score_immediate_attack_value(target, target.lane_index, defender_state, rules)
                else:
                    score += 1.0
            &"deal_damage":
                if target_owner_id != defender_state.player_id:
                    score -= 1000.0
                    continue
                score += _score_damage_support_target(effect.value, target, player_state, defender_state, rules)
            &"return_to_hand":
                if target_owner_id != defender_state.player_id:
                    score -= 1000.0
                    continue
                score += _score_bounce_support_target(target, effect.value, player_state, defender_state, rules)
            &"steal_item":
                if target_owner_id != defender_state.player_id or target.attached_item == null:
                    score -= 1000.0
                    continue
                # Steal both denies the enemy and arms our own cat.
                score += _score_item_value(target.attached_item) * 2.0 + 5.0
            &"destroy_item":
                if target_owner_id != defender_state.player_id or target.attached_item == null:
                    score -= 1000.0
                    continue
                score += _score_item_value(target.attached_item) + 3.0
            &"grant_keyword":
                if target_owner_id != player_state.player_id:
                    score -= 1000.0
                    continue
                score += _score_granted_keyword_value(effect.keyword_arg, target, defender_state, rules)

    return score


func _score_item_value(item: CardInstance) -> float:
    if item == null or item.definition == null:
        return 0.0
    var value := 0.0
    for effect in item.definition.effects:
        if effect == null:
            continue
        match effect.action:
            &"modify_attack":
                value += float(effect.value) * 2.5
            &"modify_life":
                value += float(effect.value) * 1.5
            &"grant_keyword":
                value += 4.0
    return value


func _score_granted_keyword_value(keyword: StringName, target: CardInstance, defender_state: PlayerBattleState, rules: BattleRules) -> float:
    if keyword == StringName() or target == null:
        return 0.0
    if target.has_keyword(keyword):
        return 0.5  # redundant grant, low value
    match keyword:
        CardGameConstants.KEYWORD_GUARD:
            return 5.0
        CardGameConstants.KEYWORD_POUNCE:
            return 4.0 + float(target.current_attack) * 0.5
        CardGameConstants.KEYWORD_QUICK_PAWS:
            return 3.0 + _score_immediate_attack_value(target, target.lane_index, defender_state, rules) * 0.5
    return 3.0


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
                    score += _score_direct_attack_value(effect.value, defender_state.life)

    return score


func _score_damage_support_target(damage: int, target: CardInstance, player_state: PlayerBattleState, defender_state: PlayerBattleState, rules: BattleRules) -> float:
    var score := float(target.current_attack) * 4.0 + float(target.current_life) * 1.5
    if damage >= target.current_life:
        score += 12.0
        score += _score_blocker_break_bonus(target, player_state, defender_state, rules)
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


func _score_bounce_support_target(target: CardInstance, max_cost: int, player_state: PlayerBattleState, defender_state: PlayerBattleState, rules: BattleRules) -> float:
    if max_cost > 0 and target.definition.cost > max_cost:
        return NEGATIVE_SCORE

    var score := float(target.definition.cost) * 5.0
    score += float(target.current_attack) * 2.0
    if target.has_keyword(CardGameConstants.KEYWORD_GUARD):
        score += 4.0
    if target.has_keyword(CardGameConstants.KEYWORD_POUNCE):
        score += 2.0
    score += _score_blocker_break_bonus(target, player_state, defender_state, rules) * 0.8
    return score


func _score_attack_buff_follow_up(target: CardInstance, attack_bonus: int, defender_state: PlayerBattleState, rules: BattleRules) -> float:
    if target == null or attack_bonus <= 0 or target.lane_index < 0:
        return 0.0

    var current_value := _score_attack_option_for_lane_with_attack(target, target.lane_index, target.current_attack, defender_state, rules)
    var buffed_value := _score_attack_option_for_lane_with_attack(target, target.lane_index, target.current_attack + attack_bonus, defender_state, rules)
    var delta := maxf(0.0, buffed_value - current_value)
    if delta <= 0.0:
        return 0.0

    if target.can_attack and not target.has_attacked:
        return delta * 0.9
    if target.has_keyword(CardGameConstants.KEYWORD_QUICK_PAWS):
        return delta * 0.65
    if _lane_is_open_for_direct_damage(target.lane_index, defender_state, rules):
        return delta * 0.3
    return delta * 0.15


func _score_lane_anchor_value(target: CardInstance, defender_state: PlayerBattleState, rules: BattleRules) -> float:
    if target == null or target.lane_index < 0:
        return 0.0
    if target.has_keyword(CardGameConstants.KEYWORD_GUARD):
        return 3.0 + float(target.current_attack)
    if _lane_is_open_for_direct_damage(target.lane_index, defender_state, rules):
        return 2.0 + float(target.current_attack) * 1.5
    return 0.0


func _score_blocker_break_bonus(target: CardInstance, player_state: PlayerBattleState, defender_state: PlayerBattleState, rules: BattleRules) -> float:
    if target == null or player_state == null or defender_state == null:
        return 0.0

    var best_bonus := 0.0
    for slot in player_state.board:
        if slot == null or slot.occupant == null:
            continue

        var attacker: CardInstance = slot.occupant
        if not attacker.can_attack or attacker.has_attacked:
            continue

        if attacker.lane_index == target.lane_index:
            var current_score := _score_target_card_with_attack(attacker.current_attack, target)
            var direct_score := _score_direct_attack_value(attacker.current_attack, defender_state.life)
            best_bonus = maxf(best_bonus, maxf(0.0, direct_score - current_score) * 0.65)
            continue

        if not target.has_keyword(CardGameConstants.KEYWORD_GUARD):
            continue

        var lane_gap := absi(attacker.lane_index - target.lane_index)
        var defender_slot = defender_state.board[attacker.lane_index]
        if lane_gap <= 1 and defender_slot != null and defender_slot.occupant == null:
            best_bonus = maxf(best_bonus, _score_direct_attack_value(attacker.current_attack, defender_state.life) * 0.35)

    return best_bonus


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
    return _score_attack_option_for_lane_with_attack(attacker, lane_index, attacker.current_attack, defender_state, rules)


func _score_attack_option_for_lane_with_attack(attacker: CardInstance, lane_index: int, attack_value: int, defender_state: PlayerBattleState, rules: BattleRules) -> float:
    var slot = defender_state.board[lane_index]
    if slot != null and slot.occupant != null:
        if CardGameConstants.combat_retaliation:
            return _score_trade(attacker, attack_value, slot.occupant)
        return _score_target_card_with_attack(attack_value, slot.occupant)

    var guard_target: CardInstance = rules.find_guard_for_direct_damage(defender_state, lane_index)
    if guard_target != null:
        if CardGameConstants.combat_retaliation:
            return _score_trade(attacker, attack_value, guard_target) + 2.0
        return _score_target_card_with_attack(attack_value, guard_target) + 4.0

    return _score_direct_attack_value(attack_value, defender_state.life)


# Hodnota výměny s odvetou: co získám (zabití / zranění cíle) minus co ztratím (vlastní kočka).
func _score_trade(attacker: CardInstance, attack_value: int, target: CardInstance) -> float:
    var target_value := _card_board_value(target)
    var gain := target_value + 4.0 if attack_value >= target.current_life else float(mini(attack_value, target.current_life)) * 1.0
    var strike := target.current_attack
    var loss := 0.0
    if strike >= attacker.current_life:
        loss = _card_board_value(attacker)
    else:
        loss = float(strike) * 0.8
    return gain - loss


func _card_board_value(card: CardInstance) -> float:
    var value := float(card.current_attack) * 3.0 + float(card.current_life) * 1.5
    if card.has_keyword(CardGameConstants.KEYWORD_GUARD):
        value += 4.0
    if card.has_keyword(CardGameConstants.KEYWORD_POUNCE):
        value += 2.0
    if card.has_keyword(CardGameConstants.KEYWORD_LAST_BREATH):
        value -= 2.0
    return value


func _score_target_card(attacker: CardInstance, target: CardInstance) -> float:
    return _score_target_card_with_attack(attacker.current_attack, target)


func _score_target_card_with_attack(attack_value: int, target: CardInstance) -> float:
    var score := float(target.current_attack) * 4.0
    score += float(target.current_life) * 1.5

    if attack_value >= target.current_life:
        score += 12.0
    else:
        score += float(attack_value) * 1.2

    if target.has_keyword(CardGameConstants.KEYWORD_GUARD):
        score += 6.0
    if target.has_keyword(CardGameConstants.KEYWORD_POUNCE):
        score += 3.0
    if target.has_keyword(CardGameConstants.KEYWORD_QUICK_PAWS):
        score += 2.5
    if target.has_keyword(CardGameConstants.KEYWORD_LAST_BREATH):
        score -= 2.0

    return score


func _score_direct_attack_value(attack_value: int, defender_life: int) -> float:
    var score := float(attack_value) * 8.0 + 6.0
    if attack_value >= defender_life:
        score += 1000.0
    elif attack_value >= defender_life - 2:
        score += 10.0
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
        if _lane_is_open_for_direct_damage(lane_index, defender_state, rules):
            score += 2.0
            if defender_state.life <= 2:
                score += 5.0

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


func _lane_is_open_for_direct_damage(lane_index: int, defender_state: PlayerBattleState, rules: BattleRules) -> bool:
    if lane_index < 0 or lane_index >= defender_state.board.size():
        return false
    var slot = defender_state.board[lane_index]
    if slot != null and slot.occupant != null:
        return false
    return rules.find_guard_for_direct_damage(defender_state, lane_index) == null
