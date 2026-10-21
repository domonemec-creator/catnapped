# Worklog

Ucel: kratke vecne zaznamy o vyznamnych zmenach, overeni a dalsim kroku.
Zapisuj jen zmeny, ktere ovlivni dalsi praci. Nezapisuj kosmeticky sum.

## Sablona zaznamu

### YYYY-MM-DD - Kratky nazev
- Oblast:
- Soubory:
- Zmena:
- Overeni:
- Dalsi krok:

## Zaznamy

### 2026-10-21 (dopoledne) - Dotažení designu, robustnost (Claude Opus 5.5)
- Změna: ukazatel cesty runu (portréty 5 soupeřů) na výsledkové obrazovce, výška panelu podle obsahu, červené označení prohry. Placeholder art pro všech 23 karet bez obrázku (`make_placeholder_art.gd`, ikony game-icons CC BY). Škálování okna `canvas_items/keep`. `_load_ui_texture` přes `load()` (export). Plná ruka (7+ karet) se zúží a vejde. Karta vysvětluje keyword v textu. Vysvětlení hrozby.
- Ověření: 20/20 verify PASS; `smoke_full_flow.gd` v okně; `capture_postmatch_modes.gd`; test v rozlišení 1280×720.
- Neověřeno: export do .exe (chybí exportní šablony Godotu).
- Další krok: lidský test #2; podle něj návrat malé sady Triků (C3) a art od majitele.

### 2026-10-21 (ráno) - Designový průchod všemi obrazovkami (Claude Opus 5.5, /loop do 16:00)
- Menu: titul „Catnapped!“ (Cinzel), pozadí krčmy, soupeři s portréty v pořadí runu, srozumitelnější texty (trénink vs. run). Tematické portréty: Lantern = Svíčkotlapý, Ragclaw = Uliční rváč, Harbor = Kapitán.
- Souboj: karty v ruce ve stylu tokenů, skryté hlavičky lajn, ikony srdce a ryby, odsazení panelu stavu, „Kolo N · Tvůj tah“, pravý panel v klidu jen s průvodcem.
- Balík a postup: řádky s artem a staty, pozadí, čitelné tlačítko Zpět.
- Tutorial s ikonami, výsledek zápasu Cinzel + barva, oprava pádu v textu výhry.
- Nové capture nástroje: `capture_scene.gd` (libovolná scéna), `capture_tutorial.gd`.
- Ověření: 20/20 verify PASS po každém kroku; screenshoty v `artifacts/`.

### 2026-10-21 - Oprava: verifiery přepisovaly save hráče
- Problém (existoval už před 2026-10-20): `verify_run_flow` a další volají `ProgressionSystem.reset_state()`/`save_state()` do `user://catnapped_progress.cfg`. Při testech se tak ztratilo Markovo skóre (1 výhra, 1 prohra) a příznak tutoriálu.
- Oprava: headless běh používá `user://catnapped_progress_test.cfg` (`ProgressionSystem._save_path()`). Markův save je ručně obnovený (1/1, tutoriál viděn, nový starter podle D-015).
- Ověření: 20/20 verify PASS, save po běhu beze změny (wins=1, losses=1).

### 2026-10-21 (noc, 2. blok) - Čitelnost voleb pro začátečníka (Claude Opus 5.5, /loop)
- Změna: hratelné karty v ruce svítí, nehratelné jsou ztmavené. Připravené kočky mají pulzující zelený rámeček (průvodce na něj odkazuje). Soupeřova ruka se ukazuje jako ruby karet + počet v balíku. Animace líznutí karty.
- Ověření: 20/20 verify PASS; `capture_midgame.gd`, `capture_enemy_turn.gd` (snímky v `artifacts/`)

### 2026-10-20 (noc) - Samostatná práce bez majitele (Claude Opus 5.5, /loop)
- Oblast: UX pro začátečníka, analýza testů, pravidla proti patu
- Změna: záznamy zápasů `user://match_logs/` (každá akce s kolem a životy, snímek stolu na začátku tahu). Nastavení hlasitosti a titulky (CC BY) v menu. Roztmívání scén (autoload `SceneFade`). Menu ukazuje styl soupeře. Náhled karty pod myší (i soupeřovy). Skryté tlačítko Síly stolu bez síly. Odměny jako karty s artem a staty. Banner „Tvůj tah“ / „Tah soupeře“. Mizení padlé kočky. Hlad (D-017). Harbor přeladěn.
- Ověření: 20/20 verify PASS; screenshoty `artifacts/lead_settings*.png`, `lead_reward.png`, `lead_midgame_hover.png`, `lead_enemy_turn_*.png`; simulace viz D-017
- Další krok: lidský test #2, art nových karet

### 2026-10-20 - Lidský test #1 → odveta, ruka 4, balanc, nové karty (Claude Opus 5.5)
- Oblast: pravidla, balanc, obsah, UX
- Zpětná vazba majitele (nehraje karetní hry): „přehlednější než dřív“, 1 výhra a 1 prohra, ale „smyčka“: vyložené kočky další kolo umřou, a tak dokola až do konce zápasu.
- Diagnóza (simulace, `sim_ai_matches.gd` s novými metrikami): jednosměrný souboj (35 % koček umře bez útoku) plus hladovění po kartách (13–26 % tahů s max. 1 kartou). Starter proti Smug Tabbymu vyhrával 2–6 %.
- Změna: D-014 odveta, D-015 ruka 4, nový starter a NPC balíky, Harbor jako boss na konci runu, D-016 sedm nových koček a nové efekty. Panel „Co teď?“ radí konkrétní další krok. Tutorial zmiňuje odvetu. Pozadí souboje = interiér krčmy (od majitele), rub karty jako placeholder art.
- Ověření: 20/20 verify PASS (nový `verify_new_cards.gd`); simulace viz D-015; screenshot `artifacts/lead_midgame_selected.png`
- Další krok: lidský test #2 (pocit ze smyčky, odveta pochopitelná?), art nových karet od majitele

### 2026-10-20 - Herní pocit: tempo AI, animace, zvuk, font (Claude Opus 5.5)
- Oblast: battle flow, audio, téma
- Soubory: `scripts/card_game/systems/battle_controller.gd`, `scripts/card_game/ui/lane_slot_view.gd`, `scripts/card_game/ui/battle_fx.gd`, `scripts/card_game/systems/sfx.gd` (autoload `Sfx`), `assets/audio/**`, `assets/fonts/**`, `assets/ui_theme/catnapped_theme.tres`, `project.godot`, `scripts/card_game/tools/verify_threat_progression.gd`
- Změna: Tah soupeře byl synchronní, hráč viděl jen výsledek. Teď se v okně přehrává po krocích. Útok/zásah/ochrana/přímý zásah mají animaci a zvuk. Event bannery přes celou kartu nahrazeny malým štítkem. Hlavička soupeře má „Hrozba N“ místo „[TN]“ (verifier upraven). „Rez.“ se ukazuje jen s Triky v balíku. Diakritiku doplnil subagent (Sonnet) v ~46 souborech včetně 4 verifierů.
- Ověření: 19/19 verify PASS; `capture_enemy_turn.gd` (tah doběhne, hráč je zpět na tahu, snímky průběhu); spuštění hlavní scény bez script erroru
- Další krok: lidský test #1, pak fáze C

### 2026-10-20 - Audit + čitelnost boardu, ruky a pravého panelu (Claude Opus 5.5, větev `lead/plan-2026-10`)
- Oblast: battle UI, audit stavu, plán
- Soubory: `scripts/card_game/ui/lane_slot_view.gd`, `scripts/card_game/ui/card_view.gd`, `scenes/card_game/card_view.tscn`, `scripts/card_game/ui/selected_card_preview.gd`, `scenes/card_game/battle_scene.tscn`, nové `scripts/card_game/ui/card_art_cache.gd`, `scripts/card_game/tools/capture_midgame.gd`, `assets/card_game/card_art/*.png.import`
- Zjištění: karty na stole neměly art ani jméno. `StatusBadge` je dítě `PanelContainer`u (`SlotShell`), takže se roztáhl přes celý slot jako velký medailon a překryl text. Art v ruce byl malá ikonka. Pravý panel kombinoval ozdobný rám s nesedícími okny a duplicitní texty. Saved Tuna je ve výchozí hře mrtvá (žádný deck ani reward nemá Trick).
- Změna: token na stole ukazuje oříznutý art, jméno, odznaky cena/útok/životy a keyword. StatusBadge přesunut do volného overlaye (malý v rohu). Karta v ruce je větší (176×118), ukazuje oříznutý art a první keyword. Pravý panel místo rámu vykresluje čistou kartu (art, jméno, keyword, text, staty) a panel je přes celou výšku sloupce. Art má mipmapy. Sdílený `CardArtCache` načítá art přes `load()`, což funguje i v exportu (na rozdíl od `Image.load_from_file` v `_load_ui_texture`).
- Ověření: screenshoty `artifacts/lead_midgame.png` a `artifacts/lead_midgame_selected.png` (capture_midgame), verifiery viz níže
- Další krok: diakritika všude, D-013 (skrýt Saved Tuna v UI bez Triků), audio/VFX

### 2026-07-24 - Saved Tuna je zavedena a verifier sada znovu beha
- Oblast: battle economy, AI, verifikace
- Soubory: `scripts/card_game/data/card_game_constants.gd`, `scripts/card_game/runtime/player_battle_state.gd`, `scripts/card_game/systems/battle_rules.gd`, `scripts/card_game/systems/battle_controller.gd`, `scripts/card_game/systems/ai_controller.gd`, `scripts/card_game/ui/battle_preview_presenter.gd`, `scripts/card_game/tools/verify_saved_tuna.gd`, `scripts/card_game/tools/verify_trick_item.gd`, `scripts/card_game/tools/verify_enemy_ai_support.gd`, `scripts/card_game/tools/verify_battle_previews.gd`, `scripts/card_game/tools/verify_battle_feedback.gd`, `scripts/card_game/tools/verify_table_power_ai.gd`, `scripts/card_game/tools/verify_item_steal_burn.gd`
- Zmena: Prvni LoR-like rez pridal `Saved Tuna` jako bank do `2`, ktery se plni z nevyuzite bezne Tuny na konci tahu a muze se utracet jen na `Trick` karty. Runtime a AI uz s tim pocitaji pri affordability a utraceni. Preview presenter byl opraven tak, aby battle scena znovu kompilovala, a reset helpery verifieru nulujou i `saved_tuna_current`, aby se testy navzajem nekontaminovaly.
- Overeni: `verify_saved_tuna.gd`, `verify_trick_item.gd`, `verify_enemy_ai_support.gd`, `verify_battle_previews.gd`, `verify_battle_feedback.gd`, `verify_table_power_ai.gd`, `verify_item_steal_burn.gd`
- Dalsi krok: Pokud budes chtit navazat dalsim LoR-like krokem, dalsi rozumny rez je pridat `Combat Trick` window jen pro uzkou podmnozinu Triku a az potom resit slozitejsi timing.

### 2026-07-17 - UI recovery po rozbitem encoding cisteni
- Oblast: battle UI, run completion verification
- Soubory: `scripts/card_game/ui/battle_preview_presenter.gd`, `scripts/card_game/ui/battle_overlay_presenter.gd`, `scripts/card_game/tools/verify_run_completion.gd`
- Zmena: Rozbite UI texty a verifier ocekavani byly vraceny do validniho stavu bez zasahu do scene wiring. `battle_preview_presenter` byl zapsan znovu jako cisty presenter s normalni cestinou a completion overlay ted znovu pouziva text `Zpět na výběr`, ktery verifier kontroluje.
- Overeni: `verify_battle_previews.gd`, `verify_battle_feedback.gd`, `verify_battle_layout.gd`, `verify_run_completion.gd`
- Dalsi krok: Dalsi cisteni cestiny delat po mensich blocich, hlavne ve `battle_controller.gd`, a po kazdem bloku hned pustit relevantni verifier.

### 2026-07-17 - Combat prose se vratila k normalni cestine
- Oblast: battle UI readability
- Soubory: `scripts/card_game/systems/battle_controller.gd`
- Zmena: Akcni vety v battle summary uz znovu pouzivaji normalni ceska slova jako `zraneni`, `zivoty`, `ukradne` a `vraci se do ruky`. Zkratky `UTK/ZIV/PRIMO` zustaly jen v bannerech, preview hodnotach a stat blocich, kde jsou citelnejsi nez plna veta.
- Overeni: `verify_battle_layout.gd`, `verify_lane_slot_view.gd`, `verify_battle_feedback.gd`, `verify_battle_previews.gd`, `verify_trick_item.gd`, `verify_item_steal_burn.gd`
- Dalsi krok: Pokud budes chtit dalsi cisteni, dalsi rez je sjednotit diakritiku a ceske copy i v nekterych starsich skriptech mimo tenhle refaktor.

### 2026-07-17 - Instant a trick feedback mluvi kratsimi vetami
- Oblast: battle UI readability
- Soubory: `scripts/card_game/systems/battle_controller.gd`
- Zmena: Texty z instant/trick efektu, targeted karet a Sily stolu byly zkracene na kratke akcni vety. Buffy, heal, draw, steal, destroy itemu a navrat do ruky ted rikaji hlavne vysledek a nepopisuji zbytecne celou situaci.
- Overeni: `verify_battle_layout.gd`, `verify_lane_slot_view.gd`, `verify_battle_feedback.gd`, `verify_battle_previews.gd`, `verify_trick_item.gd`, `verify_item_steal_burn.gd`
- Dalsi krok: Pokud budes chtit jeste cistsi UX, dalsi rez je sjednotit naming `ZIV/UTK/dmg` vs plna slova a rozhodnout jeden stabilni styl pro celou hru.

### 2026-07-24 - Runeterra-like smer je zapsany jako selektivni LoR-lite navrh
- Oblast: dlouhodoby battle design, pravidla
- Soubory: `design/catnapped_runeterra_lite.md`, `docs/decisions.md`
- Zmena: Misto slepeho kopirovani `Legends of Runeterra` byl zapsan konkretni navrh, co se pro Catnapped hodi a co ne. Doporuceny smer je `Saved Tuna` bank jen pro Triky, volitelne pozdeji uzky `Combat Trick` window a formalni initiative/tie-break pravidla. Naopak byly vedome odmitnuty plne sdilene roundy, full stack a defender-assigned blokovani, protoze by rozbily lane identitu a nafoukly AI/UI slozitost.
- Overeni: dokumentacni zmena, bez headless verifieru
- Dalsi krok: pokud ten smer potvrdis, prvni implementacni rez ma byt samotne `Saved Tuna` bez reaction window a s novymi verifiery pro ekonomiku a preview.

### 2026-07-17 - Combat feedback copy je kratsi a primocarejsi
- Oblast: battle UI readability
- Soubory: `scripts/card_game/systems/battle_controller.gd`, `scripts/card_game/ui/battle_preview_presenter.gd`, `scripts/card_game/tools/verify_battle_feedback.gd`
- Zmena: Status zpravy a hinty v boji byly zkracene. Vyber karty, vyber utoku, neplatne cile, vstup do lajny, primy zasah a idle hint v pravem panelu ted rikaji stejnou vec mensim poctem slov a bez zbytecne omacky.
- Overeni: `verify_battle_layout.gd`, `verify_lane_slot_view.gd`, `verify_battle_feedback.gd`, `verify_battle_previews.gd`
- Dalsi krok: Pokud budes chtit jit jeste dal, dalsi rozumny rez je zkratit i texty z instant/trick efektu a sjednotit battle log do jeste kratsich vet.

### 2026-07-16 - Battle controller je rozdeleny na controller plus dva presentery
- Oblast: battle architecture, battle UI
- Soubory: `scripts/card_game/systems/battle_controller.gd`, `scripts/card_game/ui/battle_overlay_presenter.gd`, `scripts/card_game/ui/battle_preview_presenter.gd`
- Zmena: `battle_controller.gd` ted drzi hlavne orchestraci boje, lane highlight flow a scene wiring. Tutorial a post-match overlay logika se presunula do `battle_overlay_presenter.gd`, selected panel a combat preview copy do `battle_preview_presenter.gd`. Kvuli kompatibilite verifieru zustal v controlleru tenky mirror `_current_reward_offers`, ale zdroj pravdy je presenter.
- Overeni: `verify_battle_layout.gd`, `verify_battle_feedback.gd`, `verify_battle_previews.gd`, `verify_lane_slot_view.gd`, `verify_run_flow.gd`, `verify_reward_flow.gd`, `verify_run_completion.gd`, `verify_run_failure.gd`
- Dalsi krok: Pokud budes chtit dalsi refaktor, dalsi rozumny rez je vytahnout i lane highlight orchestration do samostatneho presenteru nebo helperu bez sahani do battle rules.

### 2026-07-07 - Jednoduchy zaklad osekal defaultni obsah na cat-only core
- Oblast: game clarity, default content
- Soubory: `data/decks/starter_player.tres`, `data/decks/npc_smug_tabby.tres`, `data/decks/npc_ragclaw_brawler.tres`, `data/decks/npc_harbor_warden.tres`, `data/decks/npc_lantern_striker.tres`, `data/encounters/*.tres`, `scripts/card_game/systems/battle_controller.gd`, `scripts/card_game/systems/run_session.gd`, `scripts/card_game/systems/progression_system.gd`, `scripts/card_game/tools/verify_threat_progression.gd`, `docs/decisions.md`
- Zmena: Defaultni hra uz v prvnich bojich nepouziva itemy, hand-damage triky ani table powers. Starter, NPC decky a reward pool zustaly na kockach a citelnych keywordech; powers zustaly v kodu, ale nejsou zapnute v beznem jednoduchem zakladu.
- Overeni: cela sada `verify_*.gd` prosla (`verify_battle_feedback.gd`, `verify_battle_layout.gd`, `verify_battle_previews.gd`, `verify_encounter_select.gd`, `verify_enemy_ai_support.gd`, `verify_feast.gd`, `verify_item_steal_burn.gd`, `verify_lane_slot_view.gd`, `verify_life_floor.gd`, `verify_progression_navigation.gd`, `verify_progression_screen.gd`, `verify_reward_flow.gd`, `verify_run_completion.gd`, `verify_run_failure.gd`, `verify_run_flow.gd`, `verify_table_power_ai.gd`, `verify_threat_progression.gd`, `verify_trick_item.gd`)
- Dalsi krok: Po potvrzeni verifieru doplnit dalsi citelnostni vrstvu pro hrace, hlavne pocet karet v ruce soupere a explicitni log `kdo co zahral`.

### 2026-06-20 - Quick Paws je omezeno na jednu okamzite utocici novou kocku za tah
- Oblast: battle rules, AI fairness
- Soubory: `scripts/card_game/runtime/player_battle_state.gd`, `scripts/card_game/runtime/card_instance.gd`, `scripts/card_game/systems/battle_controller.gd`, `scripts/card_game/tools/verify_enemy_ai_support.gd`, `scripts/card_game/tools/verify_table_power_ai.gd`, `scripts/card_game/tools/verify_battle_feedback.gd`, `scripts/card_game/tools/verify_battle_previews.gd`, `scripts/card_game/tools/capture_battle_feedback.gd`, `scripts/card_game/tools/capture_battle_highlights.gd`, `data/cards/candlepaw_scout.tres`, `data/cards/wharf_cutthroat.tres`, `design/catnapped_master_notes.md`, `design/cat_table_mvp_checklist.md`, `design/cat_table_hearthstone_hybrid.md`, `design/cat_table_godot_schema.md`, `docs/decisions.md`
- Zmena: Battle stav si nove pamatuje, jestli uz byl v danem tahu spotrebovan okamzity vstupni utok. `Quick Paws` uz neumozni stejny tah utocit vsem nove vylozenym kockam, ale jen jedne; dalsi musi pockat. Stejne omezeni plati i pro `ready_attack`, aby neslo pravidlo obejit cilenym refreshem cerstve vylozene kocky bez prideleneho okamziteho utoku.
- Overeni: `verify_enemy_ai_support.gd`, `verify_table_power_ai.gd`, `verify_trick_item.gd`, `verify_battle_feedback.gd`, `verify_battle_previews.gd`
- Dalsi krok: Po potvrzeni verifieru rucne zkontrolovat, jestli je to tempo pro AI i hrace uz citelnejsi a jestli nepotrebuje dalsi upravu i text preview v pravem panelu.

### 2026-06-20 - Pravy panel uz neprekryva tlacitka pri dlouhem warningu
- Oblast: battle UI readability
- Soubory: `scenes/card_game/battle_scene.tscn`, `scripts/card_game/systems/battle_controller.gd`, `scripts/card_game/tools/verify_battle_layout.gd`
- Zmena: Spodni cast praveho panelu dostala vic prostoru, detail karty uvnitr pouziva scroll a smrtici warning byl zkracen. Info panel uz nepreteka pres `Hod pamlskem` a `Konec tahu`.
- Overeni: `verify_battle_layout.gd`, `verify_battle_previews.gd`, `verify_battle_feedback.gd`
- Dalsi krok: Rucne zkontrolovat v bezici hre, jestli je warning jeste dost srozumitelny i po zkraceni.

### 2026-06-20 - Preview uz neleze jako banner pres obsazenou kartu
- Oblast: battle UI readability
- Soubory: `scripts/card_game/ui/lane_slot_view.gd`, `scripts/card_game/tools/verify_lane_slot_view.gd`, `scripts/card_game/tools/verify_battle_previews.gd`
- Zmena: Preview event pro obsazeny slot se uz nekresli jako dalsi textured banner pres kartu. Vysledek preview zustava v pravem panelu a na stole zbyva jen highlight, aby karta nezmizela pod zelenou nebo cervenou plachtou.
- Overeni: `verify_lane_slot_view.gd`, `verify_battle_previews.gd`, `verify_battle_feedback.gd`, `verify_battle_layout.gd`
- Dalsi krok: Rucne overit, jestli jsou highlights obsazenych slotu uz dost citelne i bez preview banneru, nebo jestli bude potreba jemny kompaktni badge misto plneho overlaye.

### 2026-06-20 - Vylozeni karty uz nenechava velky support banner za kartou
- Oblast: battle UI readability
- Soubory: `scripts/card_game/systems/battle_controller.gd`, `scripts/card_game/tools/verify_battle_feedback.gd`
- Zmena: Bezny play kocky do lajny uz nevytvari genericky lane banner `VYLOZENO`, ktery vizualne rozbijel obsazeny slot a prekrival samotnou kartu. Akcni feedback zustava jen pro skutecne informacni stavy jako zasah, buff, KO nebo navrat.
- Overeni: `verify_battle_feedback.gd`, `verify_battle_previews.gd`, `verify_lane_slot_view.gd`
- Dalsi krok: Otestovat rucne, jestli se podobny vizualni sum nevraci jeste u nekterych battlecry nebo targeted efektu.

### 2026-06-20 - Board ma slabsi kontejnery a mensi signalni bannery
- Oblast: battle UI readability
- Soubory: `scenes/card_game/lane_slot_view.tscn`, `scripts/card_game/ui/lane_slot_view.gd`, `scripts/card_game/ui/selected_card_preview.gd`, `scenes/card_game/battle_scene.tscn`, `scripts/card_game/tools/verify_lane_slot_view.gd`, `scripts/card_game/tools/verify_battle_previews.gd`
- Zmena: Klidovy lane slot ma uz ve scene prazdny zaklad bez velkeho obdelnikoveho boxu, board preview karty je o neco mensi a ma slabsi vnitrni vypln, event bannery jsou uzsi a mensi a horni combat info panel byl stazen, aby tolik nebojoval s boardem.
- Overeni: `verify_lane_slot_view.gd`, `verify_battle_previews.gd`, `verify_battle_layout.gd`, `verify_battle_feedback.gd`
- Dalsi krok: Rucne v beziici hre posoudit, jestli je dalsi na rade zjednoduseni praveho panelu, nebo oprava AI readiness pravidla pri vylozeni kocky.

### 2026-06-20 - Obecne preview cedule na lane zmizely
- Oblast: battle UI readability
- Soubory: `scripts/card_game/systems/battle_controller.gd`, `scripts/card_game/tools/verify_battle_previews.gd`
- Zmena: Preview flow uz nezobrazuje obecne lane cedule jako `VYLOŽ`, `VYVOLA` nebo `UTOK X` na vlastni lajne. Zůstaly jen vysledkove a varovne preview, ktere hraci opravdu neco rikaji.
- Overeni: `verify_battle_previews.gd`, `verify_battle_layout.gd`, `verify_battle_feedback.gd`
- Dalsi krok: Pokud bude board porad vizualne tezky, dalsi krok je zmensit nebo zjemnit i nektere vysledkove bannery a nechat vic prace na prstencich/rinzich.

### 2026-06-20 - Highlight slotu uz netintuje cely obdelnik
- Oblast: battle UI readability
- Soubory: `scripts/card_game/ui/lane_slot_view.gd`, `scenes/card_game/lane_slot_view.tscn`, `scripts/card_game/tools/verify_lane_slot_view.gd`, `scripts/card_game/tools/verify_battle_previews.gd`
- Zmena: Full-slot highlight a glow byly odstraneny. Zvýraznění lajny se ted opira hlavne o centralni kruhovy ring, aby preview a threat stavy nepůsobily jako velky debug box kolem celeho slotu.
- Overeni: `verify_lane_slot_view.gd`, `verify_battle_layout.gd`, `verify_battle_previews.gd`, `verify_battle_feedback.gd`
- Dalsi krok: Pokud bude porad pusobit divne kombinace prazdneho kruhu a velke karty pri preview vylozeni, dalsi krok je schovat kruhovy placeholder behem hover preview a nechat tam jen ring plus samotnou kartu.

### 2026-06-20 - Vnejsi lane obdelnik je v klidovem stavu neviditelny
- Oblast: battle UI readability
- Soubory: `scripts/card_game/ui/lane_slot_view.gd`
- Zmena: Vnejsi panel lane slotu se v beznem stavu uz nekresli. Slot zustava klikaci, ale vizualne ho definují hlavne kruhove ramy, karta a combat highlight efekty misto velkeho obdelniku.
- Overeni: `verify_lane_slot_view.gd`, `verify_battle_layout.gd`, `verify_battle_previews.gd`
- Dalsi krok: Rucne v bezici hre overit, jestli jeste nekde nezustal dalsi obdelnik, ktery rusi cteni boardu.

### 2026-06-20 - Prazdne lajny pouzivaji kruhove slot ramy misto vnitriho boxu
- Oblast: battle UI readability
- Soubory: `scripts/card_game/ui/lane_slot_view.gd`, `scenes/card_game/lane_slot_view.tscn`
- Zmena: Vnitrni obdelnikovy slot panel uz v beznem stavu neni viditelny. Prazdna hracova lajna pouziva `combat_ready_badge` a prazdna nepratelska `combat_spent_badge`, aby slot pusobil jako skutecne misto pro kartu misto generickeho boxu.
- Overeni: `verify_lane_slot_view.gd`, `verify_battle_layout.gd`, `verify_battle_feedback.gd`, `verify_battle_previews.gd`
- Dalsi krok: Rucne v bezici hre zkontrolovat velikost kruhoveho placeholderu a podle potreby doladit text `Vyloz kocku` a `Primy zasah`.

### 2026-06-20 - Board sloty vic zduraznuji kartu misto bloku
- Oblast: battle UI readability
- Soubory: `scripts/card_game/ui/selected_card_preview.gd`, `scripts/card_game/ui/lane_slot_view.gd`, `scenes/card_game/lane_slot_view.tscn`
- Zmena: Board karta byla zvetsena v `DISPLAY_BOARD`, slot ma slabsi obdelnikovy podklad a prazdne lajny uz pouzivaji ghost verzi stejneho card frame misto velkeho placeholder bloku.
- Overeni: `verify_lane_slot_view.gd`, `verify_battle_layout.gd`, `verify_battle_feedback.gd`
- Dalsi krok: Rucne zkontrolovat ve hre, jestli placeholder frame neni uz moc velky a jestli text `Vyloz kocku` a `Primy zasah` sedi v bezovem poli.

### 2026-06-20 - Zalozeni projektove pameti
- Oblast: workflow projektu a navaznost mezi chaty
- Soubory: `docs/worklog.md`, `docs/decisions.md`, `C:\Users\voone\.codex\skills\catnapped-battle-workflow\SKILL.md`, `C:\Users\voone\.codex\skills\catnapped-battle-workflow\agents\openai.yaml`
- Zmena: Projekt ma od ted trvale misto pro zapis dulezitych zmen a rozhodnuti. Skill byl upraven tak, aby po vetsich zasazich tyto soubory aktualizoval.
- Overeni: manualni kontrola frontmatteru a struktury skillu; `quick_validate.py` v tomto runtime nejde spustit kvuli chybejicimu PyYAML
- Dalsi krok: Doplnovat nove zaznamy po kazde vyznamnejsi zmene funkcnosti nebo UX.

### 2026-06-20 - Oprava navratu z postupu na vyber souboje
- Oblast: progression navigation
- Soubory: `scripts/card_game/ui/encounter_select.gd`, `scripts/card_game/ui/progression_screen.gd`, `scripts/card_game/tools/verify_progression_navigation.gd`
- Zmena: Mutualni preload mezi obrazovkou vyberu a postupu byl nahrazen runtime `load()`, aby nevznikala cyklicka zavislost a tlacitko `Zpet na vyber` znovu fungovalo.
- Overeni: `verify_progression_navigation.gd`, `verify_encounter_select.gd`
- Dalsi krok: Pri dalsich zmenach progression UI znovu rucne overit navrat i otevreni obrazovky.

### 2026-06-20 - Threat se odemyka az po prvni vyhre
- Oblast: progression balance
- Soubory: `scripts/card_game/systems/progression_system.gd`, `scripts/card_game/tools/verify_threat_progression.gd`
- Zmena: Threat zustava na 0 do prvni hracovy vyhry. Teprve potom se zapina jeho dalsi rust a pokles.
- Overeni: `verify_threat_progression.gd`
- Dalsi krok: Dal vyvazovat rust nepratelskych decku po prvni serii playtestu.

### 2026-06-20 - Strop zivotu a odstraneni nechteneho leceni AI
- Oblast: battle state a table powers
- Soubory: `scripts/card_game/runtime/player_battle_state.gd`, `scripts/card_game/systems/battle_controller.gd`, `data/table_powers/smug_glare.tres`, `scripts/card_game/tools/verify_life_floor.gd`
- Zmena: Zivoty hrace i AI se drzi pod `max_life` a `Smug Glare` uz nepridava leceni. Tohle odstranuje stav, kdy AI v boji vylezla nad svuj startovni limit.
- Overeni: `verify_life_floor.gd`
- Dalsi krok: Hlidat dalsi zdroje leceni, ktere by obchazely stejny strop.
