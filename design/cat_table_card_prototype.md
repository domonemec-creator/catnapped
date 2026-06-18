# Cat Table Card Prototype

## Premise

Singleplayer card battler. Player sits at a table in a cat tavern. NPC opponents take turns sitting down for a duel. One run is one night.

## Prototype goals

- Short matches: 3 to 6 minutes
- Clear board state
- Hidden hand information
- Stronger focus on meso and macro than on raw speed

## Match rules

- Format: `1v1`
- Deck size: `20 cards`
- Starting life: `5 Fish`
- Board: `3 slots`
- Starting hand: `4 cards`
- First player: player starts in v1
- Draw: `1 card` at the start of your turn
- Max hand size: `7 cards`
- Resource: `Tuna`
- Tuna starts at `1`, increases by `1` each turn, max `6`
- Unspent Tuna does not carry over

## Card types

- `Cat`: unit played into one of the 3 slots
- `Trick`: one-shot spell effect used on your turn
- `Item`: equipment attached to one of your Cats; each Cat can hold only `1 Item`

## Turn flow

1. Start turn and draw `1 card`
2. Refill Tuna to the current turn maximum
3. Play any number of cards you can afford
4. Each Cat may attack `1x`
5. End turn

## Combat rules

- Cats attack only the opposite slot
- If the opposite slot has an enemy Cat, attacker deals damage equal to its Attack
- If the opposite slot is empty, attacker deals `1 direct damage` to enemy Fish
- Newly played Cats cannot attack that turn unless their text says otherwise
- When a Cat reaches `0 Life`, it dies and is removed
- Direct damage is the main win condition; board control is how you create it

## Win condition

- Reduce enemy Fish from `5` to `0`
- From round `8` onward, both players lose `1 Fish` at end of round to prevent stall games

## Run rules

- One night = `5 opponents`
- Each match resets both players to `5 Fish`
- Your deck persists through the run
- After each win, choose `1 of 3 rewards`

## Reward types

- Add `1 new card`
- Remove `1 card` from your deck
- Upgrade `1 card` in your deck

## Start card set

The first playable prototype can use this exact 20-card starter deck.

| # | Name | Type | Cost | ATK | LIFE | Effect |
|---|---|---|---:|---:|---:|---|
| 1 | Alley Kitten | Cat | 1 | 1 | 1 | When played, draw 1 card then discard 1 card. |
| 2 | Alley Kitten | Cat | 1 | 1 | 1 | When played, draw 1 card then discard 1 card. |
| 3 | Table Scrapper | Cat | 1 | 2 | 1 | No effect. Pure early pressure. |
| 4 | Nap Cat | Cat | 1 | 0 | 3 | At the start of your turn, heal this Cat by 1. |
| 5 | Window Scout | Cat | 2 | 1 | 2 | When played, reveal 1 random card from enemy hand. |
| 6 | Fishbone Thief | Cat | 2 | 2 | 2 | The first time this deals direct damage each turn, draw 1 card. |
| 7 | Fast Paw | Cat | 2 | 2 | 1 | Can attack on the turn it is played. |
| 8 | Fast Paw | Cat | 2 | 2 | 1 | Can attack on the turn it is played. |
| 9 | Alley Guard | Cat | 2 | 1 | 4 | Adjacent friendly Cats have +1 Life while this is alive. |
| 10 | Card Shark Cat | Cat | 3 | 2 | 3 | When played, if you have fewer cards than the enemy, draw 1. |
| 11 | Trapdoor Cat | Cat | 3 | 3 | 2 | When this dies, deal 1 damage to the opposite enemy Cat. |
| 12 | Lantern Watcher | Cat | 3 | 2 | 4 | Enemy Tricks that target this slot cost 1 more Tuna. |
| 13 | Tavern Bruiser | Cat | 4 | 4 | 3 | No effect. Solid finisher. |
| 14 | Nine Lives | Cat | 4 | 2 | 5 | The first time this would die, set its Life to 1 instead. |
| 15 | Catnip Burst | Trick | 1 | - | - | Give a friendly Cat +2 Attack this turn. |
| 16 | Hidden Claws | Trick | 1 | - | - | Deal 1 damage to any Cat. |
| 17 | Table Flip | Trick | 2 | - | - | Return one enemy Cat with cost 2 or less to its owner's hand. |
| 18 | Fish Toss | Trick | 2 | - | - | A friendly Cat may attack again this turn. |
| 19 | Spiked Collar | Item | 2 | - | - | Equipped Cat gets +1 Attack. |
| 20 | Iron Bowl | Item | 2 | - | - | Equipped Cat gets +2 Life. |

## Why this set works

- Low-cost cards create early board fights
- A few direct-pressure cards let games end
- Hidden information starts mattering because of Tricks and tempo swings
- There are not enough effects to confuse the first test

## First three NPC archetypes

### 1. Street Swarm

- Style: floods the board with cheap Cats
- Pressure: early direct damage
- Weakness: runs out of cards if stabilized

### 2. Cheat Eyes

- Style: holds Tricks, punishes bad commits
- Pressure: tempo swings and hand reading
- Weakness: weaker board if you force multiple lanes

### 3. Old Tom

- Style: slow deck with heavy Cats and Items
- Pressure: wins long fights through stat quality
- Weakness: can be rushed before Tuna 4 to 6

## Rules for future cards

- Most Cats should stay between cost `1` and `4`
- Avoid more than one effect per card in v1
- Avoid random target effects unless they serve hidden information
- Do not add reaction cards until basic pacing is proven

## Next useful step

Implement this as data first:

- one card data file
- one deck list per NPC
- one simple battle scene with 3 slots per side
