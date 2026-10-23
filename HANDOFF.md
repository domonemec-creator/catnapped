# HANDOFF.md (2026-10-22 večer, Claude Opus 5.5 – hlavní jednatel projektu)

## Stav
- 25/25 verifierů PASS 2026-10-22 ~20:50 (D-029).
- Pracovní větev `lead/plan-2026-10` = `main`, pushnuto na GitHub (domonemec-creator/catnapped) 2026-10-22.
- 25/25 headless `verify_*.gd` PASS (ověřeno 2026-10-22 17:39), `net_smoke` host+klient OK.
- Lidské testy #1–#3 hotové. #3: celý run vyhrán 5:0, „bavil jsem se, chápal jsem to“, což vedlo k D-021.
- Směr D-022: singleplayer = trénink (žebříček, každý soupeř těžší), hlavní cíl multiplayer 1v1 přes **Radmin VPN** (přímá IP, ENet). Hra ve dvou je hotová (D-024), mezi dvěma PC ještě netestovaná.
- Hotovo: D1 žebříček tréninku, art všech 9 nových karet (`slice_art_sheet.gd`).
- **Záznamy zápasů:** `%APPDATA%\Godotpp_userdata\Catnapped!\match_logs\`.

## Noční smyčka 21.→22. 10. (do 5:00), Claude Opus 5.5
- Hotovo a pushnuto (každý blok 23/23 verifierů):
  - UI rozbor body 3–6: menu se dvěma režimy, pravý panel s velkým náhledem karty, Hrozba pryč z UI, Balík a postup s „Smazat postup“ (malé, vlevo, potvrzení druhým klikem).
  - Balanc: Stokový král je nejtěžší i s 10 životy (sim 2,5 % vs Harbor 10 %).
  - D2 stavění balíku (D-023): kolekce v Balík a postup (+/−), trénink odemyká 3 karty za soupeře.
  - D3: 13 nových karet (47 sběratelných), kouzla bez cíle jdou zahrát.
  - D4 multiplayer 1v1 (D-024): menu „Hra ve dvou“, hostovat / připojit přes IP (Radmin). Ověřeno dvěma procesy na jednom PC (net_smoke.gd), mezi dvěma PC ještě ne.
- Incident: síťový test v okně přepsal skutečný save; obnoven ze screenshotů, prevence v `_save_path()` (viz worklog).

## Dopolední smyčka 22. 10. (do 14:00), Claude Opus 5.5
- Hotovo a pushnuto (23/23 verifierů u každého bloku):
  - Art archů A+B ve hře; štítek TRIK/PŘEDMĚT v ruce; tutoriál zmiňuje kouzla a předměty.
  - Pravý panel v tahu soupeře ukazuje jeho zahranou kartu (i u klienta ve hře ve dvou).
  - Výsledkové obrazovky: rodově neutrální texty, čitelná trasa; odměny ukazují cenu a první větu pravidel.
  - Balík a postup: velký náhled karty při najetí myší.
  - Balanc (sim 120): Věštkyně +1 Šedý veterán; žebříček teď stoupá plynule 73 → 34 → 15 → 10 → 8 → 2,5 % výher AI hráče.
  - MP: opravy z code review, `PROTOCOL_VERSION` + kontrola balíku klienta (jiná verze = odmítnutí s hláškou), test pádu klienta i hostitele (`NET_DROP`, `NET_DROP_ROLE`).
  - Windowed `smoke_full_flow` OK.
- Odpoledne: arch C ve hře (všech 9 obrázků, i portrét soupeře ve hře ve dvou).
- Export: šablony 4.6.2 (jen Windows x86_64) v `%APPDATA%\Godot\export_templates.6.2.stable\`; `build/Catnapped.exe` (218 MB, pck uvnitř) vyexportovaný a spustitelný. Nový build: `Godot --headless --path . --export-release "Windows Desktop" build/Catnapped.exe`.
- Mark 22. 10. odpoledne hrál `.exe` (stůl shora): Namyšlený kocour výhra, Lucernová útočnice výhra, Ragclaw rváč prohra v 5. kole (10 vs 14 životů, 3 kočky soupeře naráz). Odpovídá žebříčku, bez hlášených chyb.
- Čeká na Marka: test dvou PC přes Radmin.

## Odpolední smyčka 22. 10. (do 18:00), Claude Opus 5.5 – fáze E
- Hotovo a pushnuto (každý blok 24/24 verifierů):
  - E1 (D-025): levné kočky mají víc životů než útok. Smrt obou při útoku na kočku 26–48 % → 15–29 %. Žebříček tréninku stoupá dál: 68 → 32 → 23 → 17,5 → 9 → 1,3 % výher AI hráče (3 balíky soupeřů doladěny).
  - E2: Tuna karta **Sardinková konzerva** (trik za 0, +2 Tuny v tomto tahu). Odemyká ji výhra nad Věštkyní. AI ji hraje, jen když tím odemkne dražší kartu. Art od Marka je ve hře.
  - E5: Balík a postup má přepínač „Přepnout na hru ve dvou“. Je to vlastní balík ze všech 48 karet a lobby posílá ten.
  - E6 + D-026: `sim_deck_vs_deck.gd`. Ve hře ve dvou vyhrával první na tahu 62 %; teď druhý dostane +2 životy a konzervu do ruky, výsledek 50,1 %.
  - E3 obchod: rybí šupiny za zápas proti AI (výhra 10 + 5 × stupeň, prohra 3), v Balík a postup 3 nabídky karet mimo kolekci (cena 5 + 5 × cena karty).
  - `PROTOCOL_VERSION` 2: starý .exe se s novým nespojí.
- `build/Catnapped.exe` vyexportován znovu 17:43 (obsahuje vše výše včetně obchodu); export ověřen přes pck (konzerva, balík pro hru ve dvou, obchod).

## Večer 22. 10.
- Mark hrál trénink na exe ze 18:25: porazil všech 5 soupeřů, prohrál až se Stokovým králem (poslední, nejtěžší). Žebříček obtížnosti funguje podle záměru.
- Mark: „docela vyrovnané“, nic nenudilo; Stokový král na konci balíku tlačí silné tanky. Obchod zatím nepoužil (116 šupin má).
- D-028: hra ve dvou 30 životů / 10 Tun, protokol 5.
- Nález: Hřbitovní hodovník narostl na 4/13, Hostina dostala strop 3× (`6cc1812`, protokol 4, exe 19:02).
- D-029: balík ve hře ve dvou přesně 30 karet, nejvýš 3 kopie (protokol 6). Trénink dál 20–30 / 4 kopie. Balík a postup: Doplnit, X/30, křivka ceny, filtry kolekce podle ceny a typu, klik na řádek = +/−. Screenshot `artifacts/deck_pvp.png`. 25/25 verifierů, net_smoke OK.
- Otevřené (balanc): při 30 životech tanky dominují (sim Stokový král 100 % i s 30kartovými balíky). Další páka: síla tanků (Ochrana / vysoké životy za nízkou cenu), ne velikost balíku.
- Pozor: `net_smoke` a verifiery sdílejí testovací save – nepouštět je souběžně (falešné „soupeř se nepřipojil“).

## 24. 10. – E4 sbírka (Claude Opus 5.5)
- Mark otestoval nový vzhled: hra zajímavější a hezčí, vzhled „ještě to není ono“ (bez konkrétní výtky, nespěchá). Pašerák mu přišel jako chyba (zranění šlo přes kočku) → jen přepsaný text.
- E4 hotové v datech: 12 nových karet, 59 celkem, placeholder art, sim viz worklog 24. 10. Čeká na Marka: art podle `design/art_prompt_2026-10-24_e4.md` (mřížka 4×3, příkaz na řezání je v promptu).
- Další krok: E3 dokončit (šupiny ve hře ve dvou, zkrátit automatické odemykání), slabé agro balíky (PLAN).

## 23. 10. – vizuální audit (Mark: multiplayer až na konec)
- Kola 1–3 hotová a pushnutá (`be08d05`, `de230bf`, `d7af9a0`), každé 25/25 verifierů: jména na stole v jednom řádku, odměny jako skutečné karty, nadpis kola v levém panelu, ruka soupeře, globální téma tlačítek a posuvníků. Screenshoty `artifacts/audit/`. Exe znovu vyexportované.
- Zbývá z auditu (nižší dopad): prázdný pravý panel v tahu soupeře, malé karty v ruce (pevná výška stolu), návod OK.
- UI arch (`b71d9f8`): deska s nápisem, ikony v menu/souboji/obchodě. Nevyužito: široká a kulatá tlačítka, rám panelu, dělicí linka, zámek.
- Díly karet od Marka (Claude Opus 5.5): `slice_ui_sheet.gd` → `assets/card_game/ui/sheet/` (frame_cat/trick/item, holder_cost/attack/health/shield, banner_name, tag_keyword, badge_paw, splash_damage). Nasazeno v ruce (`card_view.gd`), velkém náhledu (`selected_card_preview.gd`, režimy full/large) a na stole (`lane_slot_view.gd`, NinePatch rám, aby se kruhy nedeformovaly). Pozice v podílech karty jsou konstanty `FACE_*` v `card_view.gd`, sdílené. Ověřeno 25/25 verifierů a screenshoty (midgame, reward, progression). Nevyužito: holder_shield, tag_keyword, badge_paw, splash_damage.

## Další krok
0. Fáze E zbývá: E3 obchod je hotový v základu (šupiny po zápase proti AI, 3 nabídky nad kolekcí v Balík a postup, `verify_shop.gd`); chybí šupiny ve hře ve dvou a zkrácení automatického odemykání, E4 sbírka ~60 karet (sady 15–20, každá přes `sim_deck_vs_deck.gd`).
1. Lidský test #4 (Mark + kamarád přes Radmin VPN): oba spustí hru → „Hra ve dvou“. Jeden „Hostovat hru“ (Windows firewall: povolit), druhý zadá jeho IP 26.x.x.x → „Připojit se“. Dohrát zápas. Hlásit: připojení, zpoždění, nečitelné tahy soupeře, chyby.
   - Kamarád potřebuje hru: buď `build/Catnapped.exe` (stačí poslat ten jeden soubor; oba hrají stejný .exe), nebo Godot 4.6.2 + `git clone https://github.com/domonemec-creator/catnapped.git`. Oba musí mít **stejnou verzi** (stejný commit / stejný .exe); jinak hostitel připojení odmítne s hláškou o verzi.
   - Sólo checklist (5 min): Balík a postup → přidat/odebrat kartu (+/−), zkusit „Smazat postup“ (chce 2 kliky; NEdokončovat, pokud chceš save). Trénink: porazit 1. soupeře → hláška o odemčeném soupeři a nových kartách v kolekci. V souboji: mezerník = konec tahu, F11 = celá obrazovka, Rybí trh se hraje druhým klikem.
2. Art: archy A, B, C jsou ve hře (2026-10-22). Další art jen pozadí/logo (`design/polish_assets_2026-10.md`). Řezání: `slice_art_sheet.gd -- <arch> id1,...,id9`, pak `--headless --import`.
3. MP v1 limity: záznam akcí ve 3. osobě.

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

