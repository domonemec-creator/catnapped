# HANDOFF.md (2026-10-20, Claude Opus 5.5 – hlavní jednatel projektu)

## Stav
- Větev `lead/plan-2026-10` (lokální commity, nepushnuto; `master` beze změny).
- 20/20 headless `verify_*.gd` PASS (ověřeno 2026-10-20 po všech změnách).
- Hotové fáze A a B. Po lidském testu #1 nová pravidla: odveta (D-014), ruka 4 a balanc (D-015), 7 nových koček (D-016).
- Lidský test #1: „přehlednější“, 1 výhra a 1 prohra, smyčka smrti → řeší D-014 a D-015.
- Noc 20./21. 10.: Hlad proti patům (D-017), záznamy zápasů, nastavení a titulky, náhled pod myší, odměny s kartami, banner tahů, přechody scén.
- Ráno 21. 10.: designový průchod všemi obrazovkami (menu, souboj, ruka, balík, tutorial, výsledek), viz worklog.
- **Záznamy tvých zápasů:** `%APPDATA%\Godotpp_userdata\Catnapped!\match_logs\` (stačí odehrát, AI je pak projde).

## Lidský test #2 (Mark) – checklist
1. Pořád vzniká smyčka „vyložím, umře, dokola“? Je to lepší, nebo horší?
2. Chápeš, že napadená kočka vrací úder (plovoucí číslo nad útočníkem)?
3. Pomáhá panel „Co teď?“ vpravo?
4. Smug Tabby (první soupeř): hratelný, příliš lehký, nebo těžký?
5. Nové karty (s tlapkou místo obrázku) se objevují v odměnách po výhře. Dávají smysl?
6. Art nových karet: prompty v `design/art_prompts_2026-10.md`, obrázky ulož do `assets/card_game/card_art/<id>.png`.
7. Nové: najeď myší na soupeřovu kočku (náhled vpravo), Nastavení v menu (hlasitost), Hlad při prázdném balíku.
8. Je jasné, které karty můžeš zahrát (svítí) a které kočky můžou útočit (zelený pulzující rámeček)?

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

## Další krok
Viz `PLAN.md`: fáze C (obsah: Feast karty, víc odměn), přechody scén, úklid pravého panelu bez výběru, export build.
