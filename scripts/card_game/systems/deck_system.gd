class_name DeckSystem
extends RefCounted

const CardDefinition = preload("res://scripts/card_game/data/card_definition.gd")
const CardGameConstants = preload("res://scripts/card_game/data/card_game_constants.gd")
const CardInstance = preload("res://scripts/card_game/runtime/card_instance.gd")
const DeckDefinition = preload("res://scripts/card_game/data/deck_definition.gd")
const PlayerBattleState = preload("res://scripts/card_game/runtime/player_battle_state.gd")


func build_runtime_deck(deck_definition: DeckDefinition, card_library: Dictionary, owner_id: int, next_instance_id: int) -> Dictionary:
    var deck_cards: Array[CardInstance] = []

    for entry in deck_definition.cards:
        if entry == null:
            continue

        var card_definition: CardDefinition = card_library.get(entry.card_id)
        if card_definition == null:
            push_warning("Missing card definition for %s." % entry.card_id)
            continue

        for _count in range(entry.count):
            var instance: CardInstance = CardInstance.new()
            instance.instance_id = next_instance_id
            instance.definition = card_definition
            instance.owner_id = owner_id
            instance.current_attack = card_definition.attack
            instance.current_life = card_definition.life
            instance.can_attack = card_definition.keywords.has(CardGameConstants.KEYWORD_QUICK_PAWS)
            deck_cards.append(instance)
            next_instance_id += 1

    deck_cards.shuffle()
    return {
        "cards": deck_cards,
        "next_instance_id": next_instance_id,
    }


func build_runtime_deck_from_card_ids(card_ids: Array[StringName], card_library: Dictionary, owner_id: int, next_instance_id: int) -> Dictionary:
    var deck_cards: Array[CardInstance] = []

    for card_id in card_ids:
        var card_definition: CardDefinition = card_library.get(card_id)
        if card_definition == null:
            push_warning("Missing card definition for %s." % card_id)
            continue

        var instance: CardInstance = CardInstance.new()
        instance.instance_id = next_instance_id
        instance.definition = card_definition
        instance.owner_id = owner_id
        instance.current_attack = card_definition.attack
        instance.current_life = card_definition.life
        instance.can_attack = card_definition.keywords.has(CardGameConstants.KEYWORD_QUICK_PAWS)
        deck_cards.append(instance)
        next_instance_id += 1

    deck_cards.shuffle()
    return {
        "cards": deck_cards,
        "next_instance_id": next_instance_id,
    }


func draw_cards(player_state: PlayerBattleState, amount: int) -> Array[CardInstance]:
    var drawn: Array[CardInstance] = []

    for _draw in range(amount):
        if player_state.deck.is_empty():
            break
        var card: CardInstance = player_state.deck.pop_back()
        player_state.hand.append(card)
        drawn.append(card)

    return drawn
