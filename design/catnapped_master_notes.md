# Catnapped! Master Notes

## Účel dokumentu

Tenhle soubor je **hlavní textový zdroj pravdy** pro karetní hru `Catnapped!`.

Sem se má:

- dopisovat, co je hotové
- zapisovat důležitá rozhodnutí
- držet aktuální pravidla
- držet přehled systémů, assetů a otevřených problémů
- čerpat informace pro další návrhy, implementaci a AI handoffy

Důležité:

- `README.md` je už přepsaný na `Catnapped!`, ale detailní návrhová pravda je pořád hlavně tady
- starší dokumenty v `design/` jsou návrhová historie
- **aktuální stav je vždy křížený s kódem a daty**

---

## 1. Co ta hra je

`Catnapped!` je singleplayer karetní souboj v tavernovém kočičím světě.

Základní fantasy:

- hráč sedí u stolu
- proti němu si sedají NPC kočičí soupeři
- hrají se rychlé zápasy přes `3 lane` board
- hra stojí na tlaku do otevřených linek, tempu, čtení boardu a jednoduchých keywordech

Není to čistý klon Hearthstone.

Vzali jsme si z něj jen užitečné věci:

- mana curve
- čisté keywordy
- table power
- typy karet `Cat / Trick / Item`

Nevzali jsme:

- volné targetování každého útoku kamkoliv
- obří textové karty
- content-hungry 30card clone design

Identita hry stojí na:

- `3 lanes`
- tlak do prázdných linek
- krátké zápasy
- čitelné board pozici
- jednoduchém AI loopu, který se dá rozšířit

---

## 2. Jak jsme se k tomu dostali

Vývoj šel zhruba takhle:

### Fáze 1: hrubý koncept

První návrh byl jednoduchá lane-based karetní hra:

- `1v1`
- `20card deck`
- kočky místo klasických fantasy unitů
- singleplayer stůl s NPC protivníky

Tahle fáze je zachycená hlavně v:

- `design/cat_table_card_prototype.md`

### Fáze 2: porovnání s Hearthstone stylem

Pak se řešilo, co má smysl převzít z Hearthstone a co ne.

Výsledek:

- ponechat lane pressure
- přidat `Tuna` resource
- přidat `Table Power`
- přidat keywordy
- nepřecházet na úplně volný combat

Tohle je zachycené v:

- `design/cat_table_hearthstone_hybrid.md`

### Fáze 3: MVP lock

Pak se zamkl MVP rozsah:

- jedna plně hratelná battle scéna
- player hand
- 3 lane board
- card play
- attacks
- death
- end turn
- win/lose

To je v:

- `design/cat_table_mvp_checklist.md`

### Fáze 4: datový a technický model

Další důležitý krok byl správný technický základ.

Rozhodnutí:

- karty a decky budou data-driven
- UI nebude držet gameplay pravdu
- runtime stav bude oddělený od authoring dat

To je v:

- `design/cat_table_godot_schema.md`

### Fáze 5: art direction

Pak se začal stavět jednotný vizuální směr:

- tavern / dock fantasy
- antropomorfní kočky
- portrait art do karet
- samostatné frame assety
- selected preview / support frame / post-match frame

Základ art směru je v:

- `design/cat_table_first_art_batch.md`

### Fáze 6: reálná implementace

Potom se to převedlo do Godotu jako hratelný prototype battle scene:

- datové karty
- datové decky
- encounter
- runtime state
- AI
- support cards
- progression threat system
- post-match overlay

Tohle už není jen návrh. To je **skutečný aktuální stav v kódu**.

---

## 3. Aktuální stav projektu

Card game už není jen nápad. Má hotový základ, který je hratelný.

### Co je reálně hotové

- data-driven card system
- player a enemy deck loading
- `3 lane` board
- hand selection
- selected card panel
- card placement do lane
- útoky a direct damage
- smrt a discard
- `Battlecry`
- `Last Breath`
- `Quick Paws`
- `Guard`
- `Pounce`
- `Trick` cards
- `Item` cards
- player `Table Power`
- enemy `Table Power`
- funkční enemy AI pro units, tricks i items
- persistent `threat` progression
- post-match summary overlay
- screenshot a verification tooling

### Co hotové není

- full run struktura s více NPC za sebou
- reward draft po výhře
- deckbuilding menu
- shop
- collection
- plná menu integrace a polishing
- audio / VFX polish
- více encounterů
- víc NPC osobností

---

## 4. Kde je card game v projektu

Hlavní card game scéna:

- `res://scenes/card_game/battle_scene.tscn`

Hlavní řídící skript:

- `res://scripts/card_game/systems/battle_controller.gd`

Důležité:

- projekt už je vyčištěný na card game základ
- hlavní entry point je `res://scenes/card_game/battle_scene.tscn`
- z původního projektu zůstala schválně zachovaná jen obecná síťová vrstva `res://scripts/multiplayer_manager.gd`

---

## 5. Aktuální pravidla podle implementace

Tohle je důležité. Níž je **aktuální runtime chování**, ne starý wishlist.

### Battle formát

- `1v1`
- `3 lanes`
- player vs `The Smug Tabby`

### Life a resource

- start `Life = 10`
- resource je `Tuna`
- **ZAMČENO (2026-06-17): start `3 Tuna`** — konstanty `STARTING_TUNA / MAX_TUNA / STARTING_HAND` v `battle_controller.gd` (dříve `DEBUG_START_TUNA`)
- max Tuna se zvyšuje po tazích o `+1` až do `7` (`MAX_TUNA`)

### Start battle

Aktuálně v implementaci:

- oba hráči doberou na startu `3 karty`
- player začíná aktivní
- mulligan zatím není

To znamená:

- starší návrhy s `4 card hand` a `start Tuna 1` **nejsou aktuální runtime stav**
- **ROZHODNUTO (2026-06-17): zamčeno na `3 Tuna / 3 karty`.** Důvod: krátké, tempem hnané zápasy s tlakem do linek od 1. tahu. Mulligan zatím stále není (možný pozdější přídavek).

### Turn flow

Na startu tahu:

- `tuna_max += 1`, cap `7`
- `tuna_current = tuna_max`
- dobírá se `1 karta`
- resetuje se `table_power_used_this_turn`
- ready kočky dostanou znovu možnost útočit

Během tahu:

- můžeš hrát karty
- můžeš použít `Table Power`
- můžeš útočit ready kočkami

Na konci tahu:

- čistí se dočasné buffy do konce kola
- přepne se soupeř

### Combat

- kočka útočí standardně do protější lane
- `Pounce` dovolí útok i do sousední lane
- když je cílová lane prázdná, jde direct damage do `Life`
- pokud direct damage může interceptnout `Guard`, zásah vezme guard
- direct damage teď dává **plný Attack unitky**, ne jen `1`

### Death a discard

- karta s `current_life <= 0` umírá
- jde do discardu
- předtím se triggeruje `Last Breath`

### Keywords

Aktuálně implementované:

- `Battlecry`
- `Last Breath`
- `Quick Paws`
- `Guard`
- `Pounce`

Význam:

- `Battlecry`: efekt po zahrání
- `Last Breath`: efekt při smrti
- `Quick Paws`: může útočit hned v tahu, kdy přišla
- `Guard`: interceptuje direct damage v lane a sousedních lanes
- `Pounce`: může útočit do opposite nebo adjacent lane

---

## 6. Typy karet

### 6.1 Cat

Unit karta:

- jde do jedné lane
- má `Attack` a `Life`
- může útočit podle pravidel

### 6.2 Trick

Jednorázový efekt:

- typicky buff, damage, bounce nebo refresh útoku
- po použití jde do discardu

### 6.3 Item

Attachment na friendly cat:

- buffuje cílovou kočku
- **PERSISTENTNÍ (2026-06-18):** item po zahrání **zůstane navázaný na kočce** (`CardInstance.attached_item` + `attached_item_instance_id`), NEjde rovnou do discardu. Tím je na boardu reálný objekt, který lze ukrást/zničit.
- 1 item na kočku (vynuceno v `battle_rules.is_valid_card_target`)
- buff se aplikuje jako dřív, ale je **reverzibilní** (přehrání efektů itemu s opačným znaménkem přes `_modify_host_by_item`)
- když kočka **umře** nebo je **vrácena do ruky**, její item jde do discardu

Filozofie (rozhodnuto 2026-06-18):

- **kočky** se řeší jen bojem — ubíráním Life (útoky + damage tricky). Žádná krádež, žádný instant-destroy kočky.
- **itemy na stole** se kradou a ničí (viz Sticky Paws / Pry Bar v sekci 7).
- plný „viditelný equip art" je zatím jen minimální značka; bohatší vizuál je další vrstva navíc.

---

## 7. Aktuální card pool

### Cat karty

| Karta | Cost | ATK | LIFE | Text |
|---|---:|---:|---:|---|
| Alley Scrapper | 2 | 3 | 2 | vanilla pressure |
| Candlepaw Scout | 1 | 1 | 2 | Quick Paws |
| Fishbone Skulker | 2 | 2 | 2 | Last Breath: Draw 1 card |
| Tavern Mouser | 2 | 1 | 4 | Guard |
| Rafter Pouncer | 3 | 4 | 1 | Pounce |
| Wharf Cutthroat | 3 | 3 | 2 | Quick Paws |
| Netclaw Raider | 3 | 3 | 1 | Pounce |
| Dockside Bruiser | 4 | 3 | 6 | Battlecry: Heal 1 Life. Last Breath: Draw 1 card |
| Boilerback Guardian | 4 | 2 | 6 | Guard. Last Breath: Heal 1 Life |
| Captain Ironmaw | 5 | 4 | 5 | Battlecry: Draw 1 card |
| Stray | 0 | 1 | 1 | token ze Table Power |

### Trick karty

| Karta | Cost | Efekt |
|---|---:|---|
| Catnip Burst | 1 | Give a friendly Cat +2 Attack this turn |
| Hidden Claws | 1 | Deal 2 damage to any Cat |
| Table Flip | 2 | Return enemy Cat with cost 2 or less to hand |
| Fish Toss | 2 | Friendly Cat may attack again this turn |
| Sticky Paws | 2 | Steal an item from an enemy Cat onto one of your Cats |
| Pry Bar | 1 | Destroy an item attached to an enemy Cat |

### Item karty

| Karta | Cost | Efekt |
|---|---:|---|
| Spiked Collar | 2 | Equipped Cat gets +1 Attack |
| Iron Bowl | 2 | Equipped Cat gets +2 Life |

Shrnutí:

- card pool aktuálně obsahuje `19` karet / tokenů
- unit část už má slušný základ
- support část už není fake placeholder, je funkční i pro AI
- ⚠️ **Sticky Paws / Pry Bar jsou zatím jen definované, NEjsou v žádném decku** (decky drží lock 20 karet — zařazení = samostatné content/balance rozhodnutí). Jsou **situační** (mrtvé proti decku bez itemů — pozor: Smug Tabby base itemy nemá, Ragclaw má Spiked Collar).

---

## 8. Decky a encountery

### 8.1 Player deck

Soubor:

- `data/decks/starter_player.tres`

Aktuální složení:

- `2x Alley Scrapper`
- `2x Candlepaw Scout`
- `2x Fishbone Skulker`
- `2x Tavern Mouser`
- `2x Rafter Pouncer`
- `1x Wharf Cutthroat`
- `1x Dockside Bruiser`
- `1x Captain Ironmaw`
- `2x Catnip Burst`
- `1x Hidden Claws`
- `1x Table Flip`
- `1x Fish Toss`
- `1x Spiked Collar`
- `1x Iron Bowl`

Celkem:

- `20 karet`

### 8.2 NPC deck

Soubor:

- `data/decks/npc_smug_tabby.tres`

Base list:

- `2x Candlepaw Scout`
- `2x Alley Scrapper`
- `2x Fishbone Skulker`
- `3x Tavern Mouser`
- `2x Rafter Pouncer`
- `2x Wharf Cutthroat`
- `2x Netclaw Raider`
- `3x Dockside Bruiser`
- `1x Boilerback Guardian`
- `1x Captain Ironmaw`

Celkem:

- `20 karet`

### 8.3 Encounter

Soubor:

- `data/encounters/smug_tabby.tres`

Aktuálně:

- id: `smug_tabby`
- display name: `The Smug Tabby`
- deck: `npc_smug_tabby`
- table power: `smug_glare`
- starting life: `10`

### 8.4 Encounter — Ragclaw the Brawler (2026-06-18)

Soubor: `data/encounters/ragclaw_brawler.tres`

- id: `ragclaw_brawler`
- display name: `Ragclaw the Brawler`
- deck: `npc_ragclaw_brawler` (agresivní rush, 20 karet)
- table power: `treat_toss` (sdílená — AI ji umí; viz update log proč)
- starting life: `10`

Encountery se načítají přes `_load_resources_by_id("res://data/encounters")`; který se spustí řídí `battle_controller.startup_encounter_id` (prázdné = `smug_tabby`).

---

## 9. Table Powers

### Player: Treat Toss

Soubor:

- `data/table_powers/treat_toss.tres`

Efekt:

- cost `2`
- summon `1/1 Stray` do prázdné lane

Proč je to důležité:

- jednoduchý comeback / board-fill nástroj
- dobře se čte
- AI ho taky umí použít

### Enemy: Smug Glare

Soubor:

- `data/table_powers/smug_glare.tres`

Efekt:

- cost `2`
- reveal random card in player hand
- heal `1 Life`

Proč je to důležité:

- dává NPC osobnost
- je to mix info + sustain
- sedí to k “Smug Tabby” archetypu

---

## 10. Architektura a důležité soubory

### Data

- `scripts/card_game/data/card_definition.gd`
- `scripts/card_game/data/card_effect.gd`
- `scripts/card_game/data/deck_definition.gd`
- `scripts/card_game/data/deck_entry.gd`
- `scripts/card_game/data/encounter_definition.gd`
- `scripts/card_game/data/table_power_definition.gd`
- `scripts/card_game/data/card_game_constants.gd`

### Runtime state

- `scripts/card_game/runtime/card_instance.gd`
- `scripts/card_game/runtime/player_battle_state.gd`
- `scripts/card_game/runtime/lane_slot_state.gd`
- `scripts/card_game/runtime/battle_state.gd`

### Systems

- `scripts/card_game/systems/battle_controller.gd`
- `scripts/card_game/systems/battle_rules.gd`
- `scripts/card_game/systems/deck_system.gd`
- `scripts/card_game/systems/ai_controller.gd`
- `scripts/card_game/systems/progression_system.gd`

### UI

- `scenes/card_game/battle_scene.tscn`
- `scenes/card_game/card_view.tscn`
- `scenes/card_game/lane_slot_view.tscn`
- `scenes/card_game/selected_card_preview.tscn`
- `scripts/card_game/ui/card_view.gd`
- `scripts/card_game/ui/lane_slot_view.gd`
- `scripts/card_game/ui/selected_card_preview.gd`
- `scripts/card_game/ui/card_text_formatter.gd`

### Tools a testy

- `scripts/card_game/tools/verify_trick_item.gd`
- `scripts/card_game/tools/verify_enemy_ai_support.gd`
- `scripts/card_game/tools/verify_threat_progression.gd`
- `scripts/card_game/tools/capture_battle_scene.gd`
- `scripts/card_game/tools/capture_support_cards.gd`
- `scripts/card_game/tools/capture_postmatch_overlay.gd`

---

## 11. Co je na tom technicky důležité

### 11.1 Data-driven základ je správně

Nejdůležitější technické rozhodnutí bylo tohle:

- karty nejsou hardcoded v UI
- deck se skládá z dat
- encounter je datový
- table powers jsou datové

To je důležité, protože:

- přidávání karet nevyžaduje přepis scén
- AI i UI jedou nad stejnými daty
- hra se dá rozšiřovat bez rozbití architektury

### 11.2 UI nedrží gameplay pravdu

To je správně.

Pravda je v runtime state a systémech:

- `BattleState`
- `PlayerBattleState`
- `CardInstance`
- `BattleController`
- `BattleRules`

UI je jen renderer a input vrstva.

### 11.3 Effect vocabulary je zatím malá a čitelná

To je záměr a je to dobře.

Aktuálně používané akce:

- `modify_attack`
- `modify_life`
- `deal_damage`
- `ready_attack`
- `return_to_hand`
- `draw_cards`
- `heal_life`
- `summon_token`
- `reveal_random_hand_card`
- `steal_item` (přesun nasazeného itemu z nepřátelské kočky na vlastní)
- `destroy_item` (sundání + zničení nasazeného itemu nepřátelské kočky)

To je zatím správně malý rozsah.

### 11.4 AI je jednoduchá, ale už ne trapná

AI aktuálně umí:

- vybírat play lane pro unitky
- hodnotit tlak do open lane
- hodnotit block hodnotu
- používat `Trick` a `Item` support karty
- používat table power
- hledat lepší attack targety

To je důležité, protože:

- hra už není jen “NPC end turn”
- dá se ladit core gameplay
- support cards konečně něco znamenají i proti botovi

### 11.5 Threat progression je dobrý základ meta vrstvy

Po zápase:

- výhra snižuje `threat`
- prohra zvyšuje `threat`

Threat:

- se persistuje do `user://catnapped_progress.cfg`
- mění deck Smug Tabbyho
- mění post-match messaging
- dává rematchům smysl

Tohle je důležité, protože:

- i bez full run systému už zápasy mají následky
- NPC se umí “zostřit”, když hráč prohrává
- je to levná forma replayability

---

## 12. Threat systém detailně

Soubor:

- `scripts/card_game/systems/progression_system.gd`

Rozsah:

- `0` až `10`

Labely:

- `0 Calm`
- `1 Watchful`
- `2 Restless`
- `3 Sharper`
- `4 Loaded`
- `5 Dangerous`
- `6 Ruthless`
- `7 Vicious`
- `8 Predatory`
- `9 Brutal`
- `10 Nightmare`

Chování:

- prohra hráče: `threat +1`
- výhra hráče: `threat -1`
- zapisují se i `wins` a `losses`

Smug Tabby deck se podle threatu postupně mění:

- přidává support karty
- nahrazuje slabší cats za silnější
- na vysokém threatu je deck ostřejší a nepříjemnější

Konkrétní upgrade texty už jsou připravené přímo v systému a zobrazují se v post-match overlayi.

---

## 13. UI a vizuální stav

### Hotové UI vrstvy

- hand karty
- board lane sloty
- selected card panel
- support card frame styl
- trick/item selected preview layout
- post-match overlay

### Co je vizuálně důležité

Udělali jsme správný krok:

- obyčejné “programmerské” panely se začaly nahrazovat dedikovanými assety
- selected card preview používá jiný layout podle typu karty
- support cards mají vlastní frame jazyk
- post-match overlay už má vlastní ornate frame, result emblem a badge

### Důležité assety

Card frames:

- `assets/card_game/card_frames/cat_frame.png`
- `assets/card_game/card_frames/trick_frame.png`
- `assets/card_game/card_frames/item_frame.png`

Post-match UI:

- `assets/card_game/ui/postmatch_victory_emblem.png`
- `assets/card_game/ui/postmatch_defeat_emblem.png`
- `assets/card_game/ui/postmatch_threat_badge.png`
- `assets/card_game/ui/postmatch_smug_tabby.png`
- `assets/card_game/ui/postmatch_panel_frame.png`

Připravené pro pozdější použití:

- `assets/card_game/ui/board_frame_transparent.png`

### Artifact preview výstupy

Užitečné reference:

- `artifacts/postmatch_overlay_defeat.png`
- `artifacts/postmatch_overlay_victory.png`
- `artifacts/card_game_battle_screenshot.png`
- `artifacts/card_game_selected_preview_support.png`
- `artifacts/card_game_trick_item_visuals.png`

---

## 14. Co je funkčně ověřené

### 14.1 Trick + Item flow

Soubor:

- `scripts/card_game/tools/verify_trick_item.gd`

Ověřuje:

- cat placement
- temporary attack buff
- end-turn cleanup
- item attach
- damage trick
- return-to-hand trick

### 14.2 Enemy AI support karty

Soubor:

- `scripts/card_game/tools/verify_enemy_ai_support.gd`

Ověřuje:

- enemy umí použít `Hidden Claws`
- enemy umí použít `Fish Toss`
- enemy umí použít `Spiked Collar`

### 14.3 Threat progression

Soubor:

- `scripts/card_game/tools/verify_threat_progression.gd`

Ověřuje:

- threat roste po prohře
- threat klesá po výhře
- enemy header ukazuje `T0`, `T1`, atd.
- high-threat deck mění composition

Tohle je důležité:

- máme aspoň základní automatickou kontrolu
- nejedeme čistě “ručně klikám a doufám”

---

## 15. Co jsou dnes nejdůležitější silné stránky

### 1. Má to vlastní identitu

Nejsme zaseknutí mezi:

- úplně random custom pravidly
- a trapným Hearthstone klonem

`3 lane + cat tavern + table power + direct lane pressure` už je čitelný základ identity.

### 2. Architektura je rozšiřitelná

Data-driven přístup je správně.

Tohle nebude potřeba později celé rozkopat.

### 3. Support cards už nejsou fake

Tohle byl důležitý skok.

Dokud nefungovaly `Trick` a `Item`, hra byla jen unit trading.
Teď už vzniká tempo a zajímavější rozhodování.

### 4. Threat dává rematchi smysl

Bez full run systému už teď vzniká lehká meta vrstva.

To je levný a dobrý posun.

### 5. UI už začíná mít styl

Není to ještě hotová production prezentace, ale už je tam:

- vlastní frame language
- selected preview pro support cards
- post-match presentation

To je důležité i pro motivaci a čitelnost.

---

## 16. Co jsou dnes nejdůležitější slabiny / dluh

### 1. Runtime pravidla a staré návrhy nejsou úplně sjednocené

Příklady:

- staré docs mluví o jiném start hand count
- staré docs mluví o jiném start Tuna
- runtime teď používá `3 karty` a `3 Tuna`

To je potřeba časem zamknout.

### 2. Chybí run vrstva

Máme zatím:

- jeden encounter
- rematch escalation

Nemáme:

- sérii soupeřů
- reward volby
- route / progression menu

### 3. Chybí content economy

Momentálně je hra zábavná jako battle shell, ale ne jako plná hra.

Chybí:

- reward struktura
- economy
- deck editing
- více encounterů

### 4. Některé hodnoty jsou zjevně MVP/debug

Například:

- `DEBUG_START_TUNA := 3`

To je potřeba časem buď potvrdit jako záměr, nebo vrátit na čistější economy.

### 5. Multiplayer je zachovaný, ale zatím není napojený na card game

Tohle je současný stav:

- starý FPS obsah je pryč
- `MultiplayerManager` zůstal
- samotná card game battle scéna ale zatím multiplayer flow nepoužívá

To je v pořádku. Síťový základ je uložený bokem pro pozdější použití.

---

## 17. Doporučené další kroky

Tady je pořadí, které dává smysl.

### Krátkodobě

1. Zamknout start economy:
   `3 Tuna / 3 cards` vs `1 Tuna / 4 cards`

2. Dodat další UI polish hlavní board scény:
   hlavně využít lepší `board_frame_transparent.png`

3. Přidat další encounter nebo druhou NPC osobnost:
   ať se ověří, že architektura není přeučená jen na Smug Tabbyho

### Střednědobě

4. Udělat post-battle reward flow

5. Udělat run skeleton:
   série soupeřů, přechod mezi zápasy, persistence v rámci runu

6. Udělat jednoduchý deck/progression screen

### Později

7. Rozšířit AI personality layer

8. Dodělat audio, VFX a přechody

9. Rozšířit card pool a encounter pool

---

## 18. Důležitá rozhodnutí, která bych zatím neměnil

Tohle jsou podle mě správná rozhodnutí a nemá smysl je teď rozbíjet:

- držet `3 lanes`
- držet `20card deck`
- držet `Cat / Trick / Item`
- držet `Table Power`
- držet lane-based combat místo full free targeting
- držet data-driven karty
- držet jednoduché keywordy
- držet threat progression jako levný meta layer

Kdybys chtěl otočit některý z těch bodů, musí být jasný důvod, protože by to rozbilo jádro toho, co už funguje.

---

## 19. Praktické poznámky pro další práci

Když budeme pokračovat:

- nejdřív ověřit, jestli je změna designová nebo jen polish
- pravidla psát sem, ne do chatu rozhozeně
- pokud se změní runtime pravidlo, přepsat ho i tady
- pokud přibude nový encounter nebo systém, dopsat sem sekci
- pokud se změní start economy nebo run struktura, tohle je první dokument, který má být přepsaný

---

## 20. Update log

### 2026-06-18 - Run skeleton

- `scripts/card_game/systems/run_session.gd` added as an autoload singleton to hold the in-run encounter route.
- Encounter select now has a `Start Run` button that seeds a 5-fight route from the selected encounter.
- `battle_controller.gd` now advances to the next run encounter instead of always dumping back to the selector.
- Verification added: `scripts/card_game/tools/verify_run_flow.gd`.

### 2026-06-18 — Persistentní itemy + krádež/pálení (Sticky Paws, Pry Bar)

- **Itemy předělané na persistentní equip.** Po zahrání item zůstane navázaný na kočce (`CardInstance.attached_item`), ne do discardu. Buff reverzibilní přes `_modify_host_by_item`. Při smrti/bounce kočky jde item do discardu. Detail v sekci 6.3.
- **Nová pravidlová filozofie (rozhodnuto):** kočky se řeší jen bojem/damage (žádný steal/instant-destroy kočky); kradou a ničí se jen **itemy na stole**.
- **2 nové Tricky:** `data/cards/sticky_paws.tres` (Tuna 2 — ukradne item nepřátelské kočky na tvou nejnižší kočku bez itemu) a `data/cards/pry_bar.tres` (Tuna 1 — zničí item nepřátelské kočky). Nové efekty `steal_item` / `destroy_item`.
- **Cílení:** `battle_rules.is_valid_card_target` — obě cílí nepřátelskou kočku, která **má item**; krádež navíc vyžaduje volného hostitele (`_has_free_item_host`). Obě jsou **situační** (mrtvé proti decku bez itemů).
- **AI parita:** `ai_controller._score_support_target` skóruje krádež (deny + arm) i zničení podle hodnoty itemu (`_score_item_value`).
- **Ověřeno headless (exit 0):** nový `tools/verify_item_steal_burn.gd` (krádež přenese item+staty, zničení odstraní+discard, sundání bowlu může zabít, neplatné proti kočce bez itemu). Přeběhly i `verify_trick_item`, `verify_enemy_ai_support` (aktualizován na persistentní equip), `verify_threat_progression`.
- ⚠️ **Zatím nezařazeno do decků** (lock 20 karet) — viz sekce 7. Bez UI značky nasazeného itemu (čitelnost zatím přes staty kočky).

### 2026-06-18 - Encounter select start screen

- New `res://scenes/card_game/encounter_select.tscn` is the main entry point.
- It lists the current encounters and launches `battle_scene.tscn` with the selected `startup_encounter_id`.
- `battle_controller.gd` now has a post-match "Choose Encounter" path back to the selector.
- Verification added: `scripts/card_game/tools/verify_encounter_select.gd`.

### 2026-06-18 — Life floor clamp

- `battle_controller.gd` už nenechává `Life` spadnout pod `0`. Přidané helpery `_adjust_player_life()` a `_adjust_card_life()` clampují všechny damage cesty včetně direct damage, `deal_damage` support efektů a end-turn removal temporary life bonusu.
- Přidaná regression kontrola `scripts/card_game/tools/verify_life_floor.gd` pokrývá player Life floor i cleanup karty po odečtu temporary life bonusu.
- Verifikace po změně: `verify_life_floor.gd`, `verify_trick_item.gd`, `verify_enemy_ai_support.gd`, `verify_table_power_ai.gd`, `verify_threat_progression.gd` prošly.

### 2026-06-18 — Enemy portrait + turn indikátor (portrait_frame_* zapojeny)

- **NPC portrét v enemy headeru.** Do `EnemyHeader` (`battle_scene.tscn`) přidán `EnemyPortrait` (Control 96×96): `PortraitArt` (NPC art, `stretch_mode` KEEP_ASPECT_COVERED, inset 15px) vzadu + `PortraitFrame` (rám s průhledným středem) vepředu. Labely headeru dostaly `vertical_alignment = 1` (vycentrované vedle portrétu).
- **Frame barva = turn indikátor.** `portrait_frame_gold/green/red.png` zapojeny přes `battle_controller.gd`: 🟢 green = hráčův tah, 🔴 red = tah NPC, 🟡 gold = konec bitvy. Nové konstanty `PORTRAIT_FRAME_*_PATH`, textury loadované v `_ready`, `@onready` `enemy_portrait_art/frame`, art set v `_setup_battle` (`_get_post_match_backdrop_texture()`), barva přepínaná `_update_turn_indicator()` volaným z `_refresh_ui()`.
- **ZNÁMÉ OMEZENÍ:** červený rám se reálně NEVYKRESLÍ — tah NPC běží synchronně v `_on_end_turn_pressed()` a `_refresh_ui()` se volá až po návratu k hráči. Prakticky tedy green/gold; red je zapojená a čeká na enemy-turn pacing (refresh s `active = ENEMY` + krátký `await` před spuštěním AI). **Rozhodnuto (vlastník): zatím nechat bez beatu**, game feel zůstává okamžitý.
- **Ověřeno** `tools/capture_battle_scene.gd` (real-window, exit 0, bez parse/script chyb): portrét se vykreslil, green rám = hráčův tah na startu = korektní, art Smug Tabbyho sedí do průhledného středu, jméno vycentrované. Screenshot `artifacts/enemy_portrait_turn_indicator.png`.

### 2026-06-18 — Stabilizace exportu + encounter systému

- **Export-safe frame loading hotovo.** `card_view.gd`, `selected_card_preview.gd` a `battle_controller.gd` už nenačítají UI textury přes `Image.load_from_file`, ale jako normální importované `Texture2D` resourcy. Tím zmizel export warning u card frame assetů a loading je konzistentní s Godot pipeline.
- **Encounter backdrop už není natvrdo Smug Tabby.** `EncounterDefinition.portrait_path` se skutečně používá pro post-match backdrop; `smug_tabby.tres` ukazuje na `postmatch_smug_tabby.png`, `ragclaw_brawler.tres` má vlastní dočasný portrait (`dockside_bruiser.png`) dokud nebude dedikovaný art.
- **Threat progression už platí i pro Ragclawa.** `progression_system.gd` dostal vlastní `RAGCLAW_BRAWLER_UPGRADE_LINES` a profil modifikace decku podle threatu. Threat už u něj není jen číslo v headeru, ale skutečně mění composition a post-match messaging.
- **AI table power už není hardcoded jen na dvě ID.** `ai_controller.gd` teď skóruje table power podle efektů (`summon_token`, `reveal_random_hand_card`, `heal_life`, `draw_cards`, `deal_damage enemy player`) a podle toho se rozhoduje, jestli power použít a případně do kterého lane. `treat_toss` a `smug_glare` jsou tím pokryté bez speciální větve na ID.
- **Verifikace rozšířena.** Přibyl `scripts/card_game/tools/verify_table_power_ai.gd`; znovu prošly `verify_trick_item.gd`, `verify_enemy_ai_support.gd`, `verify_threat_progression.gd` i real-window capture druhého NPC. Referenční screenshot po fixech: `artifacts/second_npc_verify_v2.png`.

### ▶ ODSUD POKRAČOVAT (příště)

UI asset pass je rozdělaný. Čisté produkční assety připravené k zapojení (viz sekce 21):
- `name_banner_small` → enemy name header („Ragclaw the Brawler [T1]" je teď holý text)
- `header_panel_drapes`, `label_frame_brass` → header / counter / tooltip
- ✅ HOTOVO: `portrait_frame_gold/green/red` → NPC portrét + turn indikátor (update log 2026-06-18)
- (volitelně) enemy-turn beat, aby se červený rám reálně ukázal — vlastník zatím odložil

**Čeká na majitele:** čisté individuální slot-highlight + counter rámy s PRŮHLEDNÝM středem (ty z `ui_states_composite.png` nejdou použít jako overlay). Bez nich zůstává slot highlight jako plochý ColorRect (funguje).

Postup integrace rámu: sekce 21 „Tři techniky". Capture jen s reálným oknem (ne --headless), nové image assety nejdřív `--import`.

### 2026-06-18 — UI asset pass (probíhá)

- Zapojen `selected_card_panel_frame` na Selected Card panel (anchored zóny: preview / banner „Selected Card" / detail+tlačítka). SelectedPanel přestrukturován, 5 `@onready` cest opraveno. Detail v sekci 21.
- Naimportováno 8 nových UI rámů do `assets/card_game/ui/`. Plný inventář, techniky a kritická zjištění → **sekce 21**.
- Zbývá: slot highlighty, počítadla, tlačítka.

### 2026-06-18 — Druhý NPC encounter: Ragclaw the Brawler

- Nové NPC **„Ragclaw the Brawler"** — agresivní rush archetyp (opak Smug Tabbyho control/sustain). Data-only, jen existující karty.
- Soubory: `data/decks/npc_ragclaw_brawler.tres` (20 karet: levné kočky, Pounce/Quick Paws, burst přes catnip/fish_toss, hidden_claws na blokera, spiked_collar), `data/encounters/ragclaw_brawler.tres` (table power `treat_toss`, life 10).
- **Table power = `treat_toss`** byl původně pragmatický krok kvůli tehdejší AI podpoře jen pro `treat_toss` a `smug_glare`. To už neplatí; table power AI je od 2026-06-18 zobecněná podle efektů.
- **Integrace:** `battle_controller.gd` teď načítá encounter library přes `_load_resources_by_id("res://data/encounters")` + `startup_encounter_id` přepínač (default `smug_tabby` → beze změny chování). Nastav `startup_encounter_id` před `_ready()` pro jiné NPC. Připraveno pro budoucí run systém.
- **Ověřeno** `tools/capture_second_npc.gd` (real-window Godot, volitelný počet tahů jako 2. user arg): encounter+deck+power se vyřešily, AI deck reálně hraje (položila Wharf Cutthroat, srazila pasivního hráče 10→0 za 3 tahy = potvrzená agrese), post-match korektně použil jméno NPC. Screenshot `artifacts/second_npc.png`.
- **Známé follow-upy po stabilizaci:** Ragclaw už má threat-scaling i vlastní backdrop pipeline, ale pořád nemá dedikovaný portrait asset a není výběr encounteru v UI/run vrstvě.

### 2026-06-17 — Start economy zamčena (3 Tuna / 3 karty)

- `DEBUG_START_TUNA := 3` → pojmenované konstanty `STARTING_TUNA := 3`, `MAX_TUNA := 7`, `STARTING_HAND := 3` v `battle_controller.gd`. Hardcoded `draw_cards(..., 3)` a `mini(..., 7)` nahrazeny konstantami.
- **Hodnoty se nezměnily** — čistě oddebugování + pojmenování záměru, takže žádná balance regrese. Ověřeno capturem: Tuna 3/3, Hand 3, Deck 17.
- Rozhodnutí zdůvodněno v sekci 5. Mulligan zůstává nedořešený (možný pozdější přídavek).

### 2026-06-17 — Board UI polish: frame integrace

- `board_frame_transparent.png` je konečně zapojený jako pozadí boardu v `battle_scene.tscn` (ornátní dřevěný stůl, crest, mosazné rohy). Předtím se nepoužíval.
- Asset musel být nejdřív naimportován (`--import` pass) — chyběl mu `.import`, scéna házela parse error. Card frames už dnes jedou přes normální importované textury; původní runtime `Image.load_from_file` flow byl později odstraněn kvůli export warningu.
- `BoardPanel` má teď prázdný StyleBox (plochý hnědý rect pryč), lanes zasazené do malovaných panelů přes okraje `MarginContainer`.
- Lane sloty (`lane_slot_view.tscn`) zprůhledněny (alpha ~0.55), aby prosvítal stůl a text zůstal čitelný; lane sloupce + sloty dostaly `size_flags_vertical = 3`, takže vyplní výšku panelů.
- `StatusLabel` přesunut z vnitřku board panelu nad něj (`BoardColumn/StatusLabel`); odpovídající `@onready` cesta v `battle_controller.gd` upravena.
- Tlačítka zviditelněna: `End Turn` akcentní amber (primární), `Table Power` sekundární s rámečkem. Předtím tmavý text na tmavém = vypadala disabled.
- Verifikace: `tools/capture_battle_scene.gd` se MUSÍ spouštět s reálným oknem (NE `--headless` — dummy renderer visí na `frame_post_draw`). Before/after v `artifacts/board_after.png`. Přidán `artifacts/.gdignore`, ať Godot nereimportuje screenshoty jako textury.

Navazující úpravy ve stejném sezení:
- **Enemy vs player rozlišení** hotovo — `lane_slot_view.gd::_apply_side_accent()` tintuje slot podle `owner_id`: enemy (nahoře) červený okraj = nebezpečí, player (dole) zelenozlatý = friendly.
- **Textový šum zkrácen** — hinty v `battle_controller.gd` z „Open lane: direct damage goes through." → „Open — direct hit", „Play a cat here." → „Play a cat"; lane labely „Enemy Lane 1" → „Enemy 1".
- **Okraje doladěny** (`MarginContainer` 96/84/-96/-62), lanes teď lícují uvnitř malovaných panelů.

**Zbývá k boardu (nice-to-have):** sub-pixel lícování lane předělů; případně vlastní display font pro tavern feel; paw printy panelů jsou teď překryté poloprůhledným slotem (kdyby měly prosvítat víc, ztmavit text místo pozadí).

### Stav k dnešku

- card game battle shell je hratelný
- player a enemy decky jsou data-driven
- support cards fungují pro hráče i AI
- threat progression funguje a persistuje se
- post-match overlay má nový ornate frame a čisté výsledkové badge
- existují verifikační a capture skripty

### Co sem příště doplnit

- nové encountery
- změny v economy
- reward systém
- run flow
- board UI refactor

---

## 21. UI assety a integrace rámů (2026-06-18)

Živá referenční sekce pro UI frame assety (kočičí tavern styl) a jak se zapojují.

### Kde assety jsou — POZOR: původní názvy ze Stažených byly ŠPATNÉ

QA (2026-06-18) zjistilo, že `*-removebg-preview.png` soubory měly názvy NEodpovídající obsahu. Přejmenováno v projektu na pravdu:

| Soubor v projektu (pravdivý název) | Obsah | Produkční? |
|---|---|---|
| `board_frame_transparent.png` | 3-lane board stůl | ✅ použito |
| `selected_card_panel_frame.png` | vysoký 2-panel+banner rám | ✅ použito |
| `portrait_frame_gold.png` (býv. slot_selected) | zlatý portrétový rám (cat crest, lucerna) | ✅ |
| `portrait_frame_green.png` (býv. slot_valid_target) | portrétový rám se zeleným akcentem | ✅ |
| `portrait_frame_red.png` (býv. slot_invalid) | portrétový rám s červeným akcentem | ✅ |
| `name_banner_small.png` (býv. small_button_frame) | horizontální dřevěný nameplate | ✅ |
| `header_panel_drapes.png` (býv. reward_panel_frame) | široký rám s drapériemi/lucernami | ✅ |
| `label_frame_brass.png` (býv. keyword_tooltip_frame) | malý kožený/mosazný štítek | ✅ |
| `ui_states_composite.png` (býv. hud_counter_frame_small) | LOW-RES koncept list 2×2 (slot highlighty + counter, s popisky) | ⚠️ ne |
| `slot_hl_valid/selected/attack.png`, `counter_frame.png` | výřezy z composite listu | ⚠️ neprůhledný střed + zbytky popisků → NEvhodné jako overlay |

**Staging v Downloads (k vytažení dle potřeby):** heraldické znaky (`priorita_1` gold, `priorita2` dark), kulatý modrý portrét (`priorita3`), landscape rám (`priorita5`), nameplate (`tlačítko`). `443a6cb1` = duplikát board framu.

### Stav integrace

- ✅ **board_frame_transparent** → pozadí boardu (sekce 13 / update log 2026-06-17)
- ✅ **selected_card_panel_frame** → Selected Card panel (anchored zóny)
- ✅ **portrait_frame_gold/green/red** → NPC portrét v enemy headeru + turn indikátor (gold=konec, green=hráč, red=NPC; red zatím nevykreslena, viz update log 2026-06-18). NEpoužity na lane sloty — špatný poměr stran.
- 🟡 **name_banner_small** → enemy name header banner (čistý kandidát)
- 🟡 **header_panel_drapes / label_frame_brass** → header / counter / tooltip
- ❌ **slot highlighty z composite listu** → NEPOUŽITELNÉ jako overlay (neprůhledný střed). Potřeba čisté individuální assety s průhledným středem (jen glow border) → požádat o re-export.
- ⏸ heraldické znaky, kulatý portrét → threat badge, portrét (až bude potřeba)

### Tři techniky integrace rámu (ověřené)

1. **Frame jako pozadí** (board): `PanelContainer` s prázdným StyleBox, `TextureRect` (frame) jako první dítě (renderuje se vzadu), content v `MarginContainer` s okraji zasazenými do malované plochy. Funguje pro ploché rámy.
2. **Anchored zóny + pevná velikost** (selected panel): když má rám pevné vnitřní zóny (panely/banner), dej panelu `custom_minimum_size` = nativní rozměr textury (žádná distorze) a umísti prvky `Control`em s `anchor_*` zlomky do zón. Nespoléhej na container výšku — byla nedeterministická.
3. **StyleBoxTexture nine-slice** (plán pro počítadla/tlačítka): pro malé škálovatelné panely/tlačítka udělej `StyleBoxTexture` s `texture_margin_*` (nine-slice okraje) — rám se roztáhne na libovolnou velikost bez deformace rohů.

### KRITICKÁ technická zjištění (neopakovat chyby)

- **Nové image assety MUSÍ projít importem** než je scéna může `ext_resource`-ovat: `Godot --path <proj> --import --headless`. Jinak parse error „referenced non-existent resource". (`.tres` resourcy import nepotřebují.)
- **Capture/verify tooly spouštět s REÁLNÝM oknem, NE `--headless`** — headless dummy renderer visí navždy na `RenderingServer.frame_post_draw`. Godot exe: `C:\Users\voone\Desktop\Godot_v4.6.2-stable_win64_console.exe`.
- Card frames (`cat/trick/item_frame.png`) už jsou načítané jako normální importované textury; starý `Image.load_from_file` flow byl odstraněn kvůli export warningu.
- Screenshoty jdou do `artifacts/` (má `.gdignore`, aby je Godot nereimportoval). Pro inspekci detailu crop přes PowerShell `System.Drawing`.
- Capture s reálným oknem může nechat viset proces — po dávce capture zkontrolovat a killnout `Godot*` procesy.

### 2026-06-18 - Reward draft

- `run_session.gd` now also holds the persistent run deck and reward offers. The run deck starts from `starter_player` and survives scene reloads inside the run.
- Victory in a run now shows a 3-choice reward draft: `Add`, `Remove`, `Upgrade`. The chosen reward mutates the persistent run deck before the next fight loads.
- `battle_scene.tscn` got a dedicated reward button block under the post-match overlay.
- Verification added: `scripts/card_game/tools/verify_reward_flow.gd`.

### 2026-06-18 - Progression screen + new NPC roster

- Added a dedicated `Deck & Progress` screen from encounter select. It shows threat, wins, losses, run state, and the saved player deck.
- Player deck progress is now persisted in `user://catnapped_progress.cfg` through `progression_system.gd`.
- `encounter_select.gd` now seeds runs from the saved deck and the run roster is expanded to `smug_tabby -> ragclaw_brawler -> harbor_warden -> lantern_striker`.
- Added two new encounters and enemy decks: `harbor_warden` and `lantern_striker`.
- Verification updated: `verify_progression_screen.gd`, `verify_encounter_select.gd`, `verify_run_flow.gd`, `verify_reward_flow.gd`, `verify_threat_progression.gd`.

### 2026-06-18 - Lantern Striker balance pass

- `npc_lantern_striker.tres` was tightened back to 20 cards and shifted toward a stronger late-game top-end.
- The deck now leans harder on `Dockside Bruiser` and `Captain Ironmaw` instead of extra low-end filler.
- `verify_threat_progression.gd` now checks Lantern Striker's threat 10 profile more tightly, including the extra `Captain Ironmaw`.
