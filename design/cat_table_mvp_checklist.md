# Cat Table MVP Checklist

## Goal

Build one fully playable `1v1` battle in Godot with:

- `3 lanes`
- `player hand`
- `one NPC opponent`
- `card play`
- `attacks`
- `damage`
- `death`
- `end turn`
- `win/lose`

If this is not fun, the rest of the game is irrelevant.

## Rules to lock before implementation

These must stop moving for MVP.

- Match health is `Life`, not `Fish`
- Starting Life is `10`, not `30`
- `Tuna` is the only in-match resource
- `Fish Tokens` are post-match reward currency only
- Board has `3 lanes`
- Cats attack the opposite lane by default
- `Quick Paws` = can attack on the turn it is played
- `Pounce` = can attack opposite or adjacent lane
- `Guard` = intercepts direct damage through its lane and adjacent lanes
- One run system is out of scope until one battle works

## Out of scope for MVP

Do not build these yet.

- full run progression
- multiple NPC personalities
- card collection
- deckbuilding menu
- rarity system
- shop
- audio polish
- VFX polish
- advanced AI
- more than `20 to 24` real cards

## Milestone 1: Rules Lock

Definition of done:

- one `source of truth` document for keywords and turn order
- no conflicting text like `Pounce = immediate attack`
- one clear glossary for `Life`, `Tuna`, `Deck`, `Discard`, `Hand`

Tasks:

- lock turn order
- lock attack rules
- lock win condition
- lock keyword meanings
- lock starter deck list

## Milestone 2: Data Foundation

Definition of done:

- cards are loaded from data, not hardcoded in UI scenes
- starter deck can be authored without code edits
- NPC deck can be authored without code edits

Tasks:

- create `CardDefinition` data
- create `DeckDefinition` data
- create `EncounterDefinition` data
- define keyword enum/list
- define effect verbs for simple abilities

## Milestone 3: Core Battle Scene

Definition of done:

- one battle scene opens and is playable with mouse only
- player sees hand, board, deck count, discard count, Life, Tuna, End Turn
- selected card panel updates correctly

Tasks:

- create battle root scene
- create `3` player lanes
- create `3` enemy lanes
- create player hand area
- create top HUD for enemy and player state
- create selected-card panel
- create End Turn button

## Milestone 4: Turn System

Definition of done:

- turn starts cleanly
- player draws `1`
- Tuna refills correctly
- turn ownership flips correctly
- end-turn cannot be skipped into broken state

Tasks:

- start battle setup
- mulligan or skip mulligan for v1
- start-turn flow
- draw step
- Tuna refill step
- action phase
- end-turn flow
- enemy turn flow

## Milestone 5: Card Play

Definition of done:

- player can click a card, choose a valid lane, and play it
- invalid plays are blocked cleanly
- hand, board, and Tuna update immediately

Tasks:

- hand selection
- valid lane highlight
- play validation
- Tuna cost payment
- move card from hand to board
- trigger `Battlecry` if present

## Milestone 6: Combat and Death

Definition of done:

- Cats can attack legal targets only
- damage resolves correctly
- direct damage hits Life only when legal
- dead Cats go to discard
- `Last Breath`, `Quick Paws`, `Pounce`, `Guard` all work

Tasks:

- attack selection
- target validation
- combat resolution
- direct damage resolution
- death check
- discard placement
- keyword resolution

## Milestone 7: NPC AI

Definition of done:

- NPC completes turns without hanging
- NPC can play cards and attack legally
- NPC is dumb but functional

Tasks:

- play the cheapest valid card first
- prefer empty lanes early
- attack for lethal if possible
- otherwise attack direct if legal
- otherwise trade into weakest valid enemy

Do not overbuild AI before the battle is proven fun.

## Milestone 8: Match End

Definition of done:

- battle ends immediately at `0 Life`
- win screen and lose screen both work
- match can restart cleanly

Tasks:

- detect lethal
- freeze input after result
- show result panel
- restart battle
- return to menu later

## Milestone 9: Debug and Test Tools

Definition of done:

- basic debugging exists so iteration is fast

Tasks:

- button or hotkey to draw cards
- button or hotkey to add Tuna
- battle log panel or console output
- restart button
- test encounter loader

## MVP Acceptance Test

MVP is done only if this full loop works:

1. Open battle scene
2. See starting hand
3. Play a Cat into a lane
4. End turn
5. NPC plays a turn
6. On later turn, attack with a Cat
7. Kill a Cat and send it to discard
8. Trigger one keyword effect
9. Reduce one side to `0 Life`
10. Show result and restart without errors

## Recommended implementation order

1. Rules lock
2. Data schema
3. Battle scene shell
4. Hand to board play
5. Turn flow
6. Combat
7. NPC AI
8. Result screen
9. Debug tools

## Red flags

If any of these happen, stop adding content and fix the system first.

- cards are hardcoded into UI nodes
- keyword meaning changes from screen to screen
- `Fish` means both health and reward in the same match
- matches last more than `8 minutes`
- too many dead turns
- AI takes more than `1 second` to decide in MVP
