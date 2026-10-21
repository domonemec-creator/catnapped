# HANDOFF.md (2026-10-21 noc, Claude Opus 5.5 – hlavní jednatel projektu)

## Stav
- Pracovní větev `lead/plan-2026-10`, sloučená fast-forwardem do `main` a pushnutá na GitHub (domonemec-creator/catnapped) 2026-10-21.
- 21/21 headless `verify_*.gd` PASS (ověřeno 2026-10-21 noc).
- Lidské testy #1–#3 hotové. #3: celý run vyhrán 5:0, „bavil jsem se, chápal jsem to“, což vedlo k D-021.
- Směr D-022: singleplayer = trénink (žebříček, každý soupeř těžší), hlavní cíl multiplayer 1v1. Testovat se bude přes **Radmin VPN** (přímá IP, ENet, `scripts/multiplayer_manager.gd` = kostra, k souboji zatím nenapojená).
- Hotovo: D1 žebříček tréninku, art všech 9 nových karet (`slice_art_sheet.gd`).
- **Záznamy zápasů:** `%APPDATA%\Godotpp_userdata\Catnapped!\match_logs\`.

## Noční smyčka 21.→22. 10. (do 5:00), Claude Opus 5.5
- Hotovo a pushnuto (každý blok 23/23 verifierů):
  - UI rozbor body 3–6: menu se dvěma režimy, pravý panel s velkým náhledem karty, Hrozba pryč z UI, Balík a postup s „Smazat postup“ (malé, vlevo, potvrzení druhým klikem).
  - Balanc: Stokový král je nejtěžší i s 10 životy (sim 2,5 % vs Harbor 10 %).
  - D2 stavění balíku (D-023): kolekce v Balík a postup (+/−), trénink odemyká 3 karty za soupeře.
  - D4 multiplayer 1v1 (D-024): menu „Hra ve dvou“, hostovat / připojit přes IP (Radmin). Ověřeno dvěma procesy na jednom PC (net_smoke.gd), mezi dvěma PC ještě ne.
- Incident: síťový test v okně přepsal skutečný save; obnoven ze screenshotů, prevence v `_save_path()` (viz worklog).

## Další krok
1. Lidský test #4 (Mark + kamarád přes Radmin VPN): oba spustí hru → „Hra ve dvou“. Jeden „Hostovat hru“ (Windows firewall: povolit), druhý zadá jeho IP 26.x.x.x → „Připojit se“. Dohrát zápas. Hlásit: připojení, zpoždění, nečitelné tahy soupeře, chyby.
2. D3 víc karet (prompt na art arch je v `design/art_prompt_2026-10-22.md`, jakmile vznikne).
3. MP v1 limity: klient nevidí animace soupeřových akcí, žádná odveta.

## Co se změnilo (podrobně `docs/worklog.md`)
- Stůl: token s artem, jménem a odznaky; opraven roztažený StatusBadge; event bannery jsou malé štítky.
- Ruka: větší karty s artem a keywordem. Pravý panel: čistá karta místo rámu.
- Diakritika všude, opraveny texty rozbité na „?“.
- Tah soupeře se v okně přehrává po krocích (0,75 s), s výpadem, otřesem, plovoucími čísly a zvuky. Headless zůstává synchronní (verifiery).
- Audio: autoload `Sfx` (`scripts/card_game/systems/sfx.gd`), Kenney CC0 zvuky, 2 CC0 hudební smyčky, cvaknutí u všech tlačítek.
- Font Alegreya (OFL) v globálním tématu `assets/ui_theme/catnapped_theme.tres`.
- Zdroj stažených assetů: `C:\Users\voone\Desktop\karty` (licence v `LICENSES.md`, kopie `assets/audio/LICENSES_SOURCE.md`).

## Ověřeno čím
- `smoke_full_flow.gd` v okně (2026-10-20 noc): menu → run → celý zápas 16 kol, bez script errorů, záznam zápasu vznikl.
- Verifiery (headless), screenshoty v okně: `capture_midgame.gd` (rozehraná hra + vybraná karta), `capture_enemy_turn.gd` (průběh tahu soupeře).

## Neověřeno (jen člověk)
- Zvuk a hudba (hlasitost, jestli neruší). Plynulost animací v reálném hraní. Celý run od začátku do konce rukama.

## Lidský test #1 (Mark) – checklist (HOTOVO 2026-10-20)
1. Spusť hru (F5 v Godotu nebo `Godot --path .`), dej „Spustit run“.
2. Poznáš na první pohled, co je na stole za kočky a kolik mají útok a životy?
3. Je tah soupeře dost pomalý, abys viděl, co dělá? Nebo moc pomalý?
4. Zvuky a hudba: příjemné, nebo otravné? (hlasitost)
5. Najdi cokoli, co se překrývá, je useknuté nebo nedává smysl, a pošli screenshot.
6. Dohraj aspoň 2 souboje. Byla hra zábavná? Co nudilo?

## Pozor
- Controller závisí na presenterech; verifiery resetují `saved_tuna_current`.
- `_run_enemy_stub_turn` je coroutine; v okně ho volej přes `await`. Verifiery ho volají synchronně (headless), proto pacing hlídá `_pace_actions`.
- `SlotShell` je PanelContainer, takže děti s anchory je potřeba dát do volného `Control` overlaye (viz `_fix_status_badge_layout`).
- Alegreya má minuskové číslice („0“ je nízká); `lnum` ve variabilní verzi nefunguje.
- `_load_ui_texture` už načítá přes `load()` (funguje v exportu), `Image.load_from_file` zůstává jen jako záloha. Okno se škáluje (`canvas_items`, `keep`).

