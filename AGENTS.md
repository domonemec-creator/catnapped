# AGENTS.md – Catnapped! (Godot 4.6)

Karetní hra „Catnapped!“ (3 lane board, kočičí NPC soupeři). Odpovídej česky, stručně.

## Mapa
- Zdroj pravdy (návrh + stav): `design/catnapped_master_notes.md`
- Směr LoR-lite: `design/catnapped_runeterra_lite.md` (rozhodnutí D-012)
- Rozhodnutí: `docs/decisions.md`
- Changelog = `docs/worklog.md` (nezakládat další CHANGELOG)
- Roadmapa: `PLAN.md`, předání práce: `HANDOFF.md`
- Entry scéna: `scenes/card_game/encounter_select.tscn` (souboj: `battle_scene.tscn`)
- Audio: autoload `Sfx` (`scripts/card_game/systems/sfx.gd`), assety `assets/audio/`, téma+font `assets/ui_theme/`
- Kód: `scripts/card_game/` (`systems/` pravidla+controller+AI, `ui/` presentery, `runtime/` stav, `data/` konstanty, `tools/` testy a capture)
- Data: `data/` (karty, decky, encountery, table powers)
- `skills/` je externí Codex skill, je v `.gitignore`; `artifacts/` a `.godot/` také.

## Testy (headless)
Godot: `C:\Users\voone\Desktop\Godot_v4.6.2-stable_win64_console.exe`

    Godot --headless --path . --script res://scripts/card_game/tools/verify_saved_tuna.gd

Spusť všechny `scripts/card_game/tools/verify_*.gd` (21 skriptů); každý končí hláškou „... verification passed.“. Po změně pravidel/UI vždy pusť relevantní verifiery. Tempo a animace ověř v okně přes `capture_midgame.gd` a `capture_enemy_turn.gd`. Celý tok hry (menu → run → zápas do konce) v okně: `smoke_full_flow.gd` (obnoví save). Balanc: `sim_ai_matches.gd -- 40` (headless).

## Screenshot
`scripts/card_game/tools/capture_battle_scene.gd` se spouští **S oknem, NE `--headless`**:

    Godot --path . --script res://scripts/card_game/tools/capture_battle_scene.gd -- "<abs cesta>.png"

Výstup do `artifacts/`.

## Pravidla práce
- Změny pravidel/UI zapisuj do `docs/worklog.md`, rozhodnutí do `docs/decisions.md`, stav do master notes.
- Push: Mark 2026-10-21 dal hlavnímu jednateli (Claude) volnou ruku pushovat. Ostatní AI bez pokynu nepushují. Před pushem musí projít všechny verifiery.
