# HANDOFF.md (2026-10-07)

## Stav
- Projekt funguje: 19/19 headless `verify_*.gd` prošlo.
- Git: lokální commity, nepushnuto. `skills/` ignorováno (externí Codex skill).
- Poslední práce: split `battle_controller.gd` + presentery (`ui/battle_overlay_presenter.gd`, `ui/battle_preview_presenter.gd`), oprava češtiny, `Saved Tuna`, návrh LoR-lite.

## Pozor
- Controller závisí na presenterech (musí zůstat spolu).
- Verifiery resetují `saved_tuna_current`, jinak se testy kontaminují.
- Capture tool běží jen s oknem.
- Screenshot ukazuje tutorial overlay „Jak to hrát“ překrývající board; board token nebyl vizuálně ověřen.

## Další krok
Viz `PLAN.md` – nejdřív potvrzení směru LoR-lite od majitele.

Mapa a spuštění testů: `AGENTS.md`. Changelog: `docs/worklog.md`.
