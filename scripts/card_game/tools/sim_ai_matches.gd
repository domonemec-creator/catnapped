extends SceneTree

# Headless AI-vs-AI balance simulation.
# Plays the player's starter deck (driven by the same AI as the NPCs) against each
# NPC encounter at threat 0. Runs BOTH turn orders (player first / player second),
# seeds the RNG for reproducibility, and asserts the enemy deck is identical across
# games. Restores the player's progression save afterwards.
# Usage: Godot --headless --script res://scripts/card_game/tools/sim_ai_matches.gd -- <games_per_order>

const TURN_CAP := 60
const CardGameConstants = preload("res://scripts/card_game/data/card_game_constants.gd")
const RNG_SEED := 20260620
const ENCOUNTERS: Array[StringName] = [&"smug_tabby", &"ragclaw_brawler", &"harbor_warden", &"lantern_striker", &"fog_seer", &"bilge_king"]

var _progression_system := ProgressionSystem.new()
var _packed_scene: PackedScene
# Optional candidate player deck (card ids, expanded by count). Empty = use starter.
var _candidate_ids: Array[StringName] = []
# Metriky „smyčky smrti“ (2026-10-20): vyložené kočky, které umřou bez útoku, a změny vedení.
var _played_ids: Dictionary = {}
var _attacked_ids: Dictionary = {}
var _score_history: Array[int] = []
var _turn_starts := 0
var _starved_turns := 0


func _init() -> void:
    call_deferred("_run")


func _load_candidate_ids(path: String) -> Array[StringName]:
    var ids: Array[StringName] = []
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        push_warning("Could not open candidate deck file %s" % path)
        return ids
    while not f.eof_reached():
        var line := f.get_line().strip_edges()
        if line.is_empty() or line.begins_with("#"):
            continue
        var parts := line.split(" ", false)
        var card_id := StringName(parts[0])
        var count := 1
        if parts.size() > 1:
            count = maxi(1, int(parts[1]))
        for _c in range(count):
            ids.append(card_id)
    return ids


func _other(battle, id: int) -> int:
    return battle.ENEMY_ID if id == battle.PLAYER_ID else battle.PLAYER_ID


# Generic AI turn for either side (mirrors battle_controller._run_enemy_stub_turn).
func _drive_turn(battle, acting_id: int, defender_id: int) -> void:
    var bs = battle._battle_state
    var me = bs.get_player_state(acting_id)
    var foe = bs.get_player_state(defender_id)
    var ai = battle._ai_controller
    var rules = battle._battle_rules

    var plays := 0
    while not bs.battle_over and plays < 10:
        var choice: Dictionary = ai.choose_play(me, foe, rules)
        if choice.is_empty():
            break
        var card = choice["card"]
        match str(choice.get("play_type", "lane")):
            "targeted":
                var toid := int(choice.get("target_owner_id", foe.player_id))
                var tlane := int(choice.get("lane_index", -1))
                var tstate = me if toid == me.player_id else foe
                if tlane < 0 or tlane >= tstate.board.size():
                    break
                var tslot = tstate.board[tlane]
                if tslot == null or tslot.occupant == null:
                    break
                battle._play_targeted_card(me, foe, card, tslot.occupant)
            "instant":
                battle._play_targeted_card(me, foe, card, null)
            _:
                var lane := int(choice.get("lane_index", -1))
                if lane < 0:
                    break
                battle._play_card_to_lane(me, lane, card)
                _played_ids[card.instance_id] = true
        plays += 1

    var power = battle._get_table_power_definition(me)
    var pc: Dictionary = ai.choose_table_power(me, foe, power, rules)
    if not pc.is_empty():
        battle._activate_table_power(me, foe, power, int(pc.get("lane_index", -1)))

    var attacks := 0
    while not bs.battle_over and attacks < 12:
        var ac: Dictionary = ai.choose_attack_action(me, foe, rules)
        if ac.is_empty():
            break
        _attacked_ids[ac["attacker"].instance_id] = true
        battle._perform_attack(me, foe, ac["attacker"], ac["lane_index"])
        attacks += 1
    _score_history.append(_board_score(battle))


# Kladné = vede hráč. Životy + polovina síly stolu (útok + životy koček).
func _board_score(battle) -> int:
    var bs = battle._battle_state
    var p = bs.get_player_state(battle.PLAYER_ID)
    var e = bs.get_player_state(battle.ENEMY_ID)
    var score: int = p.life - e.life
    for slot in p.board:
        if slot.occupant != null:
            score += int((slot.occupant.current_attack + slot.occupant.current_life) / 2)
    for slot in e.board:
        if slot.occupant != null:
            score -= int((slot.occupant.current_attack + slot.occupant.current_life) / 2)
    return score


func _enemy_deck_signature(state) -> String:
    # Full built deck = library still in deck + the opening hand already drawn.
    var ids: Array[String] = []
    for c in state.deck:
        ids.append(String(c.definition.id))
    for c in state.hand:
        ids.append(String(c.definition.id))
    ids.sort()
    return ",".join(ids)


# Returns {winner:int, turns:int, enemy_sig:String}. winner: 0 player, 1 enemy, -1 draw, -2 timeout.
func _play_one_game(encounter_id: StringName, player_first: bool) -> Dictionary:
    _progression_system.reset_state()  # pin threat 0 + starter deck baseline
    if not _candidate_ids.is_empty():
        var st := _progression_system.load_state()
        st = _progression_system.set_player_deck_card_ids(st, _candidate_ids)
        _progression_system.save_state(st)
    var battle = _packed_scene.instantiate()
    battle.startup_encounter_id = encounter_id
    root.add_child(battle)
    await process_frame
    await process_frame

    var bs = battle._battle_state
    var first_id: int = battle.PLAYER_ID if player_first else battle.ENEMY_ID
    var second_id: int = _other(battle, first_id)
    var first_state = bs.get_player_state(first_id)
    var second_state = bs.get_player_state(second_id)
    var enemy_sig := _enemy_deck_signature(bs.get_player_state(battle.ENEMY_ID))

    # Opening: first mover plays off the init hand/tuna (no ramp, no extra draw);
    # second mover ramps-less first turn but draws (handled by _start_turn flags).
    first_state.has_started_turn = true
    second_state.has_started_turn = false
    bs.active_player_id = first_id

    _drive_turn(battle, first_id, second_id)
    if not bs.battle_over:
        battle._clear_end_of_turn_modifiers(first_state)

    var actor := second_id
    var turns := 0
    while not bs.battle_over and turns < TURN_CAP:
        bs.active_player_id = actor
        battle._start_turn(bs.get_player_state(actor))
        _turn_starts += 1
        if bs.get_player_state(actor).hand.size() <= 1:
            _starved_turns += 1
        _drive_turn(battle, actor, _other(battle, actor))
        if not bs.battle_over:
            battle._clear_end_of_turn_modifiers(bs.get_player_state(actor))
        actor = _other(battle, actor)
        turns += 1

    var wasted := 0
    for side in [bs.get_player_state(battle.PLAYER_ID), bs.get_player_state(battle.ENEMY_ID)]:
        for c in side.discard:
            if _played_ids.has(c.instance_id) and not _attacked_ids.has(c.instance_id):
                wasted += 1
    var lead_changes := 0
    var last_sign := 0
    var winner_was_behind := false
    var winner_id: int = bs.winner_player_id if bs.battle_over else -2
    for i in range(_score_history.size()):
        var sc: int = _score_history[i]
        var sgn := signi(sc)
        if sgn != 0 and last_sign != 0 and sgn != last_sign:
            lead_changes += 1
        if sgn != 0:
            last_sign = sgn
        # Comeback: vítěz po 4. tahu aspoň jednou jasně prohrával (o 3+).
        if i >= 4 and ((winner_id == battle.PLAYER_ID and sc <= -3) or (winner_id == battle.ENEMY_ID and sc >= 3)):
            winner_was_behind = true
    var result := {
        "winner": winner_id,
        "turns": turns,
        "enemy_sig": enemy_sig,
        "played": _played_ids.size(),
        "wasted": wasted,
        "lead_changes": lead_changes,
        "comeback": winner_was_behind,
    }
    _played_ids.clear()
    _attacked_ids.clear()
    _score_history.clear()
    battle.queue_free()
    await process_frame
    return result


func _run() -> void:
    var games_per := 100
    var user_args := OS.get_cmdline_user_args()
    if not user_args.is_empty():
        games_per = maxi(1, int(user_args[0]))
    if user_args.size() > 1 and String(user_args[1]).ends_with(".txt"):
        _candidate_ids = _load_candidate_ids(String(user_args[1]))
        print("# candidate deck: %s cards from %s" % [_candidate_ids.size(), user_args[1]])

    # Volitelně: "noretal" kdekoli v argumentech vypne odvetu (A/B porovnání D-014).
    if user_args.has("noretal"):
        CardGameConstants.combat_retaliation = false
    for arg in user_args:
        if String(arg).begins_with("draw"):
            CardGameConstants.draw_per_turn = int(String(arg).substr(4))
        elif String(arg) == "noladder":
            CardGameConstants.training_ladder = false
        elif String(arg) == "guardlane":
            CardGameConstants.guard_covers_adjacent = false
        elif String(arg) == "firststrike":
            CardGameConstants.attacker_first_strike = true
        elif String(arg).begins_with("hand"):
            CardGameConstants.starting_hand = int(String(arg).substr(4))
    print("# first_strike=%s" % CardGameConstants.attacker_first_strike)
    print("# combat_retaliation=%s draw_per_turn=%s starting_hand=%s" % [CardGameConstants.combat_retaliation, CardGameConstants.draw_per_turn, CardGameConstants.starting_hand])
    seed(RNG_SEED)

    _packed_scene = load("res://scenes/card_game/battle_scene.tscn") as PackedScene
    if _packed_scene == null:
        push_error("Could not load battle_scene.tscn")
        quit(1)
        return

    var original_state := _progression_system.load_state()

    print("=== AI-vs-AI SIM  (%s games/order, both orders, seed %s, threat 0) ===" % [games_per, RNG_SEED])
    print("matchup,p_first_wr,p_second_wr,overall_wr,avg_turns,deck_stable,wasted_pct,lead_changes,comeback_pct,starved_pct,timeout_pct")

    for encounter_id in ENCOUNTERS:
        CardGameConstants.stat_cat_attacks = 0
        CardGameConstants.stat_mutual_kills = 0
        var pf_wins := 0
        var ps_wins := 0
        var total_turns := 0
        var sig := ""
        var deck_stable := true
        _turn_starts = 0
        _starved_turns = 0
        var played_sum := 0
        var wasted_sum := 0
        var lead_sum := 0
        var comebacks := 0
        var timeouts := 0
        for order in [true, false]:
            for _i in range(games_per):
                var r: Dictionary = await _play_one_game(encounter_id, order)
                total_turns += int(r["turns"])
                played_sum += int(r["played"])
                wasted_sum += int(r["wasted"])
                lead_sum += int(r["lead_changes"])
                if bool(r["comeback"]):
                    comebacks += 1
                if int(r["winner"]) == -2:
                    timeouts += 1
                if sig == "":
                    sig = str(r["enemy_sig"])
                elif str(r["enemy_sig"]) != sig:
                    deck_stable = false
                if int(r["winner"]) == 0:
                    if order:
                        pf_wins += 1
                    else:
                        ps_wins += 1
        var pf_wr := 100.0 * float(pf_wins) / float(games_per)
        var ps_wr := 100.0 * float(ps_wins) / float(games_per)
        var overall := 100.0 * float(pf_wins + ps_wins) / float(games_per * 2)
        var avg_turns := float(total_turns) / float(games_per * 2)
        var wasted_pct := 100.0 * float(wasted_sum) / float(maxi(1, played_sum))
        var games := float(games_per * 2)
        print("%s,%.1f,%.1f,%.1f,%.1f,%s,%.1f,%.2f,%.1f,%.1f,%.1f" % [encounter_id, pf_wr, ps_wr, overall, avg_turns, deck_stable, wasted_pct, float(lead_sum) / games, 100.0 * float(comebacks) / games, 100.0 * float(_starved_turns) / float(maxi(1, _turn_starts)), 100.0 * float(timeouts) / games])
        print("  %s: útoky na kočku %s, smrt obou %.1f %%" % [encounter_id, CardGameConstants.stat_cat_attacks, 100.0 * float(CardGameConstants.stat_mutual_kills) / float(maxi(1, CardGameConstants.stat_cat_attacks))])

    _progression_system.save_state(original_state)
    print("=== SIM DONE (progress save restored) ===")
    quit()
