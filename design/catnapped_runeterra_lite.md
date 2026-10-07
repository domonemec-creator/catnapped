# Catnapped Runeterra-Lite Direction

## Verdict upfront

Full `Legends of Runeterra` combat pacing is the wrong fit for Catnapped right now.

Reasons:

- Catnapped is already locked around `3 lanes`, short matches, and board-first readability.
- The project deliberately moved back to a simpler `cat-only core` and away from off-board trick noise.
- Full shared rounds, open response chains, and free blocker assignment would raise UI, AI, and rules cost too fast.

What does fit is a **Runeterra-lite** pass:

- keep lane combat and alternating full turns
- import a small amount of resource banking
- import a narrow combat-trick response window
- formalize initiative and deterministic timing
- reject full stack play and free-form blocking

This keeps the LoR-style feeling of tension and sequencing without turning Catnapped into a fake clone.

## Target experience

The intended match should feel like:

- a short tempo duel with visible lane pressure
- bluffable combat, but not stack-war bookkeeping
- simple card text with deeper sequencing
- NPC archetypes that stay distinct and readable

It should not become:

- a reaction-chain game
- a hand-centric burn game
- a blocker-shuffle puzzle where lanes stop mattering
- a value soup where every deck has all the answers

## Keep, add, reject

### Keep

- `3 lanes`
- direct Fish damage through open lanes
- one-way lane combat
- current archetype identity split: rush, tempo, control, gear
- short matches and low card-count deckbuilding

### Add

- `Saved Tuna`: up to `2` unused Tuna carries over as Trick-only resource
- `Combat Trick` speed: a narrow response window during one attack
- formal `round` and `initiative` language in rules and runtime state
- deterministic simultaneous-resolution rules

### Reject

- shared-round alternating actions for every play
- full spell stack
- burst/focus/fast/slow speed ladder
- defender-chosen free blockers
- unlimited banked resource

## Concrete rules proposal

### 1. Economy

- Keep `STARTING_TUNA = 3`, ramp `+1` per turn, cap `7`.
- Add `Saved Tuna` with cap `2`.
- At end of your turn, unused normal Tuna converts into Saved Tuna up to cap.
- Saved Tuna may pay only for `Trick` cards.
- `Item`, `Cat`, and `Table Power` may not spend Saved Tuna.

Why:

- This is the cleanest LoR import.
- It smooths bad curves without removing tempo discipline.
- It gives both player and AI a reason to respect open mana.

### 2. Card timing

Split cards into only three timing buckets:

- `Cat`: main phase only
- `Item`: main phase only
- `Trick`: either `Main Trick` or `Combat Trick`

Do not add more timing buckets in v1.

### 3. Combat Trick window

Add a single narrow window per attack:

1. Active player selects attacker and target lane.
2. Attacker may play one `Combat Trick`.
3. Defender may play one `Combat Trick`.
4. Resolve tricks in fixed order.
5. Deal combat or direct damage.

Recommended fixed order:

- active player trick resolves first
- defending player trick resolves second
- then damage

This is intentionally not a stack. No chain-building, no repeated passing, no hidden exception timing.

### 4. Initiative and rounds

Keep full turns, but formalize a `round` as:

- player turn
- enemy turn

Add `initiative_player_id` to the rules language and state.

Use initiative only for:

- round ownership in UI
- deterministic tie-breaks if a future simultaneous effect needs active-side ordering
- future encounter rules keyed to "your round" or "enemy round"

Do not add a LoR-style attack token as a separate board mechanic yet. The current active turn already carries enough initiative for Catnapped.

### 5. Combat model

Keep current lane-locked combat:

- attacker chooses one legal lane target based on `Pounce` or opposite lane
- occupied lane means combat into that unit
- open lane means direct Fish damage
- `Guard` continues to intercept direct damage from its lane and adjacent lanes

Do not switch to defender-assigned blockers.

Reason:

- defender-assigned blockers would erase the identity of fixed lane pressure
- it would also force a much larger AI and UX rewrite than the gain justifies

## Keyword and content direction

Use the current card pool and future additions under these rules:

- `Quick Paws` stays a tempo keyword, not a loophole to bypass all reaction
- `Guard` becomes more interesting because Saved Tuna lets the defender hold up Tricks
- `Pounce` stays the main positional keyword
- keep `Battlecry`, `Last Breath`, `Feast` as visible board keywords

Do not add more than `1-2` new combat-facing keywords in the same release as Saved Tuna and Combat Tricks.

## Archetype impact

### Rush

Strength:

- uses Saved Tuna to convert low-curve turns into surprise damage

Weakness:

- still folds to sturdy Guard lanes and efficient answers

### Tempo

Strength:

- benefits most from Combat Trick windows and lane re-open plays

Weakness:

- can overextend into defender-held Saved Tuna

### Control

Strength:

- finally has a reason to pass with mana and threaten interaction

Weakness:

- must not gain too much cheap removal or the board stops mattering

### Gear

Strength:

- can protect one important equipped Cat through narrow trick timing

Weakness:

- still loses if item protection becomes more efficient than item removal

## Balance guardrails

Do not print these early in the same environment as Saved Tuna:

- repeated free Trick generation
- cost reduction on Tricks
- zero-cost Combat Tricks
- face burn that ignores lanes
- broad silence or hard removal at low cost
- multiple extra-attack enablers on one body

If a card both uses Saved Tuna well and creates direct Fish damage from hand, assume it is dangerous until proven otherwise.

## Implementation cut for this codebase

### Runtime

Update these state holders:

- `scripts/card_game/runtime/battle_state.gd`
  Add explicit `round_number`, `initiative_player_id`, and `combat_window_state`.
- `scripts/card_game/runtime/player_battle_state.gd`
  Add `saved_tuna_current` and a per-attack combat-trick usage flag.

### Rules

Update:

- `scripts/card_game/systems/battle_rules.gd`
  Add legality checks for `Combat Trick` windows, Saved Tuna spending, and exact trick timing.

### Controller

Update:

- `scripts/card_game/systems/battle_controller.gd`
  Attack flow must pause before damage, offer the trick window, and resume deterministically.
- `scripts/card_game/systems/ai_controller.gd`
  AI must decide whether to hold Saved Tuna, spend it on offense, or answer during defense.

### Data

Likely additions:

- `speed` or `timing_class` on trick definitions
- optional `can_use_saved_tuna` boolean if not all future Trick-like cards should use the bank

### UI

Add:

- visible Saved Tuna counter for both sides
- explicit combat-window banner in the right panel
- lane preview copy that says whether defender can still answer

Do not add giant on-board banners for this. The right panel should stay the primary explanation surface.

## Suggested rollout

### Phase 1

- Saved Tuna only
- no Combat Trick window yet

This is the safest first cut and already imports a meaningful LoR principle.

### Phase 2

- add Combat Trick window to a small subset of existing Tricks
- verify rush, control, and gear matchups specifically

### Phase 3

- only if Phase 2 is good, consider a few new cards built specifically for held-up Tuna

## Verifier additions needed when implemented

- `verify_saved_tuna.gd`
- `verify_combat_trick_window.gd`
- `verify_ai_saved_tuna_usage.gd`
- update `verify_battle_previews.gd`
- update `verify_battle_feedback.gd`
- update `verify_enemy_ai_support.gd`

## Final recommendation

If the goal is "make Catnapped feel a bit more like Runeterra," do **not** rebuild the whole turn model.

Do this instead:

1. ship `Saved Tuna`
2. test whether open mana already creates enough tension
3. only then add the narrow `Combat Trick` window

That is the highest-signal LoR influence for this project and the lowest-risk path for the current codebase.
