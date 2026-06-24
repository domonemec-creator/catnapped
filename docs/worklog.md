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
