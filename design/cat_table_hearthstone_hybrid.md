# Cat Table Hearthstone Hybrid

## Goal

Combine the strong part of the current prototype with the useful part of Hearthstone.

Keep:

- `3 lanes`
- `NPC gauntlet at one table`
- `direct pressure through open lanes`
- `short matches`

Borrow:

- `mana curve`
- `mulligan`
- `clean keywords`
- `once-per-turn table power`
- `curve/value/tempo deckbuilding`

Do not copy:

- full free targeting for every attack
- giant text-heavy cards
- reaction chains
- a 30-card, content-hungry clone

## Recommended hybrid rules

- Format: `1v1`
- Mode: singleplayer run against NPCs
- Deck size: `20 cards`
- Starting Fish: `10`
- Board: `3 lanes`
- Starting hand: `4 cards`
- Before turn 1, each player may mulligan any number of cards once
- Starting player is random
- The second player draws `1 extra card` and gets `Lucky Sardine`
- Max hand size: `8`

## Resource system

- Resource is `Tuna`
- Tuna starts at `1`
- Tuna increases by `1` each turn
- Maximum Tuna is `7`
- Tuna fully refills at the start of your turn
- Unspent Tuna is lost

## Lucky Sardine

- Type: Trick
- Cost: `0`
- Text: Gain `+1 Tuna` this turn only

This is the Hearthstone-style tempo compensation for going second.

## Card types

- `Cat`: unit played into one lane
- `Trick`: one-shot effect
- `Item`: permanent attachment for one Cat; each Cat may hold only `1 Item`

## Turn structure

1. Draw `1 card`
2. Refill Tuna
3. Use your `Table Power` if you want
4. Play cards in any order
5. Attack with any Cats that can attack
6. End turn

## Combat rules

- A Cat may attack `1x per turn`
- Newly played Cats cannot attack that turn unless they have `Quick Paws`
- By default, Cats attack the opposite lane only
- If the opposite lane is empty, that Cat deals damage equal to its Attack directly to enemy Fish
- If direct damage would go through an empty lane and the defender has an eligible `Guard`, the attack is redirected into that Guard instead
- If the opposite lane has an enemy Cat, combat damage is dealt to that Cat
- Unless a card says otherwise, Cats do not hit left or right lanes
- When a Cat reaches `0 Life`, it dies immediately

## Why this combat model is the right hybrid

This keeps the lane identity and positional pressure from the current design. Hearthstone's full free targeting would flatten the board and turn lanes into decoration.

## Table Powers

Each duelist has one once-per-turn ability that costs `2 Tuna`.

### Player table power

- `Treat Toss`: summon a `1/1 Stray` in an empty lane

This is simple, readable, and gives comeback potential without adding weird rules.

### NPC examples

- `Street Swarm`: summon a `1/1 Stray` in a random empty lane
- `Cheat Eyes`: reveal one random card in your hand; the next Trick this turn costs `1` less
- `Old Tom`: give a friendly Cat `+0/+2`

## Core keywords

Use only these in v1.

- `Battlecry`: effect happens when the card is played
- `Last Breath`: effect happens when the Cat dies
- `Quick Paws`: this Cat can attack on the turn it is played
- `Guard`: this Cat blocks direct damage through its lane and adjacent lanes; if multiple Guards could intercept, the defender chooses which Guard takes the hit
- `Pounce`: this Cat may attack the opposite lane or one adjacent lane

## Win condition

- Reduce enemy Fish from `10` to `0`
- From round `10` onward, both players lose `1 Fish` at end of round to stop stalls

## Run structure

- One run = `5 NPC opponents`
- Fish resets between matches
- Deck persists during the run
- After each win, choose `1 of 3 rewards`

## Reward types

- Add `1 card`
- Remove `1 card`
- Upgrade `1 card`
- Improve your Table Power for the rest of the run

## Why this is better than either extreme

Compared to the current lane-only version:

- more comeback tools
- better early-turn decisions because of mulligan
- more deck identity because of Table Powers and keywords
- more room for archetypes than just stats and tempo

Compared to a full Hearthstone clone:

- stronger identity
- cheaper to build
- clearer AI
- shorter matches
- less content required before the game feels real

## How the current starter cards should change

Do not throw away the current set. Convert it.

| Current card | Hybrid version |
|---|---|
| Alley Kitten | Keep almost the same. `Battlecry: draw 1, discard 1.` |
| Table Scrapper | Keep as cheap pressure. |
| Nap Cat | Keep as slow wall. |
| Window Scout | `Battlecry: reveal 1 random enemy card.` |
| Fishbone Thief | Keep as card-advantage lane threat. |
| Fast Paw | Replace text with keyword `Quick Paws`. |
| Alley Guard | Replace text with keyword `Guard`. Remove the adjacent life aura. |
| Card Shark Cat | Keep as hand-size catch-up draw. |
| Trapdoor Cat | Replace text with `Last Breath: deal 1 to the opposite enemy Cat.` |
| Lantern Watcher | Keep as anti-Trick tech. |
| Tavern Bruiser | Keep as raw stats finisher. |
| Nine Lives | Keep as sticky midgame Cat. |
| Catnip Burst | Keep as attack buff Trick. |
| Hidden Claws | Keep as 1-damage Trick. |
| Table Flip | Keep as cheap tempo bounce. |
| Fish Toss | Keep as extra attack enabler. |
| Spiked Collar | Keep as basic attack Item. |
| Iron Bowl | Keep as basic life Item. |

## Exact 20-card hybrid starter deck

This should be the first real player deck in the hybrid version.

### Deck identity

- Style: `tempo-midrange`
- Main goal: take lanes early, punish open lanes, then finish with buffs and one heavy Cat
- Skill focus: lane pressure, timing, hand reading, efficient Tuna use

### Exact list

| Count | Card | Cost | Role |
|---|---|---:|---|
| 2x | Alley Kitten | 1 | Smooths bad hands, improves mulligan value |
| 2x | Table Scrapper | 1 | Early lane pressure |
| 2x | Window Scout | 2 | Hidden-info peek, safe board filler |
| 2x | Fast Paw | 2 | Tempo swing with `Quick Paws` |
| 1x | Alley Guard | 2 | Protects open lanes and stops direct damage |
| 1x | Trapdoor Cat | 3 | Sticky trade piece with `Last Breath` value |
| 1x | Lantern Watcher | 3 | Anti-Trick anchor for one important lane |
| 1x | Tavern Bruiser | 4 | Simple finisher |
| 2x | Catnip Burst | 1 | Burst damage, forces trades, closes games |
| 2x | Hidden Claws | 1 | Cheap removal, breaks small boards |
| 1x | Table Flip | 2 | Tempo bounce against cheap defenders |
| 1x | Fish Toss | 2 | Extra attack for punish turns |
| 1x | Spiked Collar | 2 | Permanent pressure upgrade |
| 1x | Iron Bowl | 2 | Keeps one lane alive longer |

Total: `20 cards`

### Curve

- Cost `1`: `8 cards`
- Cost `2`: `8 cards`
- Cost `3`: `2 cards`
- Cost `4`: `1 card`
- Cost `5+`: `0 cards`
- Plus `Treat Toss` as Table Power every game

This is intentionally low-curve. A starter deck should teach tempo and lane pressure before slower value engines.

### Mulligan rules for this deck

Keep:

- at least one `1-cost Cat`
- at least one `2-cost Cat`
- `Fast Paw` if you expect to fight for board immediately

Throw back:

- `Tavern Bruiser` in almost every opening hand
- double `Item` openers
- hands with only Tricks and no Cats

### How the deck wins

1. Play cheap Cats into multiple lanes
2. Force the NPC to answer inefficiently
3. Use `Fast Paw`, `Catnip Burst`, or `Fish Toss` to convert an open lane into direct Fish damage
4. Use `Table Flip` or `Hidden Claws` to reopen a blocked lane
5. End the game before a slower NPC outvalues you

### What this deck is weak against

- heavy `Guard` walls
- repeated healing or armor-style mechanics if added later
- slow starts with too many non-Cat cards

## Recommendation

If you want the strongest direction, build this hybrid and not a pure Hearthstone copy.

The pure lane version is cleaner for an ultra-fast prototype.
The hybrid version is better if you want the game to have more depth and replayability without losing its own face.
