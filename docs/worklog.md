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

### 2026-10-22 - Hra ve dvou: vlastní balík ze všech karet (E5, Claude Opus 5.5)
- Oblast: postup, Balík a postup, lobby
- Soubory: `progression_system.gd` (`KEY_PVP_DECK`, `get_deck_card_ids/set_deck_card_ids(…, pvp)`, `get_all_collectible_card_ids()` přes `ResourceLoader.list_directory`, add/remove s parametrem `pvp`), `progression_screen.gd` (tlačítko „Přepnout na hru ve dvou / na trénink“, v režimu hry ve dvou kolekce = všechny karty bez žetonů a balík nejde zamknout výpravou), `net_lobby_overlay.gd` (posílá balík pro hru ve dvou), `capture_progression_hover.gd` (3. argument `pvp`), `verify_deck_building.gd`.
- Proč: D-025, ve hře ve dvou má každý všechny karty; trénink a jeho odemykání zůstávají beze změny. Dokud hráč balík pro hru ve dvou neupraví, je to kopie tréninkového.
- Ověření: 24/24 verifierů, `net_smoke` host+klient shodný výsledek, screenshot `artifacts/progression_pvp.png`.

### 2026-10-22 - Tuna karta: Sardinková konzerva (E2, Claude Opus 5.5)
- Oblast: karty, pravidla, AI
- Soubory: `data/cards/sardine_can.tres` (trik za 0: „Získáš 2 Tuny navíc v tomto tahu“), nová akce `gain_tuna` v `battle_controller._resolve_instant_card_effects`, AI `_gain_tuna_unlocks_card` (hraje ji jen když hned odemkne dražší kartu z ruky, jinak drží), odemyká ji výhra nad Věštkyní, `PROTOCOL_VERSION` 2 (jiná sada karet = starý build se nepřipojí), `tools/verify_sardine_can.gd`.
- Proč: Markův nápad na karty, které doplní Tunu během kola; dává skok na dražší kartu dřív.
- Art zatím chybí (karta má rub s tlapkou), prompt v `design/art_prompt_2026-10-22.md`.
- Ověření: 24/24 verifierů. Balanc v balících soupeřů zatím není (žádný ji nemá); měřit v simu balík proti balíku (E6).

### 2026-10-22 - Balanc: méně výměn 1:1 (E1, Claude Opus 5.5)
- Oblast: karty, balíky soupeřů, verifiery
- Soubory: 8 karet v `data/cards/` (viz D-025), `data/decks/npc_lantern_striker.tres` (méně Síťových nájezdníků, Rybokostěný → 3× Akrobat), `npc_fog_seer.tres` (Šedý veterán 2 → 1, +1 Svíčkotlapka), `npc_bilge_king.tres` (Lamač doků 2 → 1, +1 Mršinový slídil); 5 verifierů bralo Uličního rváče jako kočku se 2 životy, teď Trámový skokan nebo výpočet z `definition.attack`.
- Proč: Mark „pořád se to jen mlátilo dokola“; 26–48 % útoků na kočku končilo smrtí obou.
- Výsledek (sim 120): smrt obou 19,6 / 28,7 / 20,3 / 27,0 / 16,9 / 14,8 %. Žebříček výher AI hráče 68 → 32 → 23 → 17,5 → 9 → 1,3 % (pořadí sedí). Bez úprav balíků byla Lucernová útočnice moc lehká (61 %).
- Ověření: 23/23 verifierů.

### 2026-10-22 - Sim: měření výměn 1:1, pokus „útočník první“ (Claude Opus 5.5)
- Oblast: balanc, pravidla (D-025)
- Soubory: `card_game_constants.gd` (`attacker_first_strike`, počítadla), `battle_controller.gd` (`_apply_retaliation` počítá útoky a smrt obou), `tools/sim_ai_matches.gd` (argument `firststrike`, řádek „smrt obou“)
- Výsledek: základ 26–48 % smrt obou; útočník první 0 %, ale zbytečné kočky 55 % a rozbitý žebříček → zamítnuto. Ve hře se nic nemění (přepínač vypnutý).
- Ověření: sim 120 her obě varianty, 23/23 verifierů.

### 2026-10-22 - UI: hrací stůl shora pod lajnami (Claude Opus 5.5)
- Oblast: UI souboje, art
- Soubory: `assets/card_game/ui/board_topdown.png` (generovaný), zdroj `design/art_src/board_topdown_source.webp` (.gdignore), nástroj `tools/build_board_texture.gd`, `battle_scene.tscn` (okraje lajn přes theme konstanty, mezery 40/36), `lane_slot_view.gd` (prázdné místo bez výplně, rámeček jen při zvýraznění)
- Proč: Mark dodal stůl shora se 6 vyrytými místy. Místa v obrázku mají jiné mezery než lajny, proto nástroj změří lajny ve scéně a obrázek po pásech přeškáluje (vodorovná prkna to snesou). Karty jsou o ~13 % užší, deformace místa 14 %.
- Pozn.: `offset_*` na MarginContaineru uvnitř PanelContaineru nic nedělaly (PanelContainer přepíše rect dětí), proto theme konstanty.
- Po změně rozložení lajn znovu: `build_board_texture.gd -- design/art_src/board_topdown_source.webp`.
- Ověření: `capture_midgame.gd` (screenshot: karty sedí ve vyrytých místech), 23/23 verifierů.

### 2026-10-22 - UI: pryč perspektivní stůl pod lajnami (Claude Opus 5.5)
- Oblast: UI souboje
- Soubory: `scenes/card_game/battle_scene.tscn` (BoardPanel/FrameArt skryt, okraje 84→12 px)
- Proč: Mark: stůl na pozadí a rámečky lajn přes něj = dvě plochy přes sebe. Stůl je kreslený v perspektivě, s rovnými kartami lícovat nejde. Nový stůl shora: prompt v `design/art_prompt_2026-10-22.md`.
- Ověření: `capture_midgame.gd` (screenshot), 23/23 verifierů.

### 2026-10-22 - Oprava: v exportu prázdné balíky (Claude Opus 5.5)
- Oblast: export / načítání dat
- Soubory: `battle_controller.gd`, `progression_screen.gd` (`_load_resources_by_id`)
- Příčina: knihovna karet se skládala z `DirAccess.get_files()` + filtr `.tres`. V exportu jsou soubory `*.tres.remap`, takže knihovna byla prázdná a oba hráči začali bez karet (Mark, první hra v .exe).
- Změna: `ResourceLoader.list_directory()` (vidí exportované názvy).
- Ověření: `verify_net_snapshot.gd` spuštěný proti exportovanému .pck (`--main-pack`): starý kód FAIL, nový PASS; 23/23 verifierů.

### 2026-10-22 - Export: Windows build (Claude Opus 5.5)
- Oblast: distribuce (test hry ve dvou)
- Změna: s Markovým souhlasem staženy oficiální export templates 4.6.2 (SHA512 ověřen), nainstalovány jen Windows x86_64. `build/Catnapped.exe` (v .gitignore) vyexportován headless.
- Ověření: exe naběhne (`--headless --quit-after 180`, exit 0, bez chyb).

### 2026-10-22 - Art: arch C ve hře (Claude Opus 5.5)
- Oblast: art
- Soubory: `assets/card_game/card_art/` (spiked_collar, war_plate, watchmans_bell, tavern_bouncer, portrait_rival, harbor_courier, net_mender, cannon_cat, fish_market)
- Změna: Markův arch C rozřezán `slice_art_sheet.gd`; soupeř ve hře ve dvou má vlastní portrét místo kopie Tuláka. Druhý zaslaný arch (4 kočky + rubové strany) zatím nepoužit.
- Ověření: řezy na tmavých linkách (x 343/680, y 475/1017), 23/23 verifierů.

### 2026-10-22 - MP: test pádu klienta uprostřed zápasu (Claude Opus 5.5)
- Oblast: síťová hra (D-024)
- Soubory: `tools/net_smoke.gd` (env `NET_DROP=N`), `battle_controller.gd` (`_on_net_disconnected` přepíše i stavový řádek)
- Změna: `NET_DROP=N` nechá klienta v N. kole tvrdě skončit (OS.kill, bez rozloučení). Host to pozná přes ENet timeout, ukončí zápas, ukáže „Konec hry / Soupeř se odpojil.“ a nečeká donekonečna na tah.
- Ověření: dvakrát (kolo 3 a 4) host vypsal `NET DROP host stav="Soupeř se odpojil." overlay=true`; všech 23 verifierů.
- Doplněno: `NET_DROP_ROLE=host` = spadne host; klient ukáže „Spojení s hostitelem se ztratilo.“ a výsledkovou obrazovku (ověřeno).

### 2026-10-22 - MP: verze protokolu a kontrola balíku klienta (Claude Opus 5.5)
- Oblast: síťová hra (D-024)
- Soubory: `multiplayer_manager.gd`, `net_battle.gd`, `tools/verify_net_snapshot.gd`
- Změna: `_rpc_hello` nese `PROTOCOL_VERSION` (=1, zvyšovat při změně RPC/snímku). Jiná verze nebo balík s neznámými kartami / mimo 20–30 karet → host pošle `_rpc_reject` s českou hláškou (klient ji dostane jako `join_failed`) a odpojí ho. Jméno ořezané na 24 znaků. Akce s ne-číselnými poli host zahodí.
- Proč: kamarád se starší verzí hry by poslal karty, které host nezná, a hra by spadla.
- Ověření: `verify_net_snapshot` testuje `_validated_deck`; `net_smoke` host+klient shodný výsledek; všech 23 verifierů. Odmítnutí jiné verze end-to-end netestováno (chce dva buildy).

### 2026-10-22 - MP: opravy z code review (Claude Opus 5.5, review Sonnet)
- Oblast: síťová hra (D-024)
- Soubory: `multiplayer_manager.gd`, `net_battle.gd`, `battle_controller.gd`
- Změna:
  - Odpojení soupeře: host zavře server (cizí klient se nepřipojí do mrtvé hry); po konci zápasu zmizí tlačítko Odveta a ukáže se hláška.
  - Klient pošle konec tahu jen jednou za tah (`_net_end_turn_sent`), refresh UI mohl tlačítko znovu povolit.
  - Odložený snímek po reloadu (odveta) kontroluje `is_instance_valid`.
  - Po odvetě se zahodí starý výběr karty (instance_id začínají znovu).
  - Pravý panel klienta pozná soupeřovu kartu podle id ze skryté ruky (dřív mohl ukázat spadlý předmět).
- Odloženo (hra mezi kamarády): validace balíku z `_rpc_hello` a typů v akcích proti upravenému klientovi.
- Ověření: `net_smoke` host+klient s `NET_REMATCH=1` (2 zápasy, shodný výsledek), všech 23 verifierů. Odpojení uprostřed hry netestováno automaticky.

### 2026-10-22 - Tutoriál: řádek o kouzlech a předmětech; smoke celé hry (Claude Opus 5.5)
- Oblast: onboarding
- Soubory: `ui/battle_overlay_presenter.gd`
- Změna: „Jak to hrát“ má 5. krok „TRIK a PŘEDMĚT: klikni na kartu a pak na kočku…“ (ikona battlecry). Dřív tutoriál kouzla vůbec nezmiňoval.
- Ověření: `capture_tutorial.gd` (okno), `smoke_full_flow.gd` v okně (výprava, zápas 15 kol, bez script errorů), lobby „Hra ve dvou“ screenshotem, všech 23 verifierů.

### 2026-10-22 - Odměny: cena a co karta dělá přímo na tlačítku (Claude Opus 5.5)
- Oblast: UI odměny po výhře ve výpravě
- Soubory: `ui/battle_overlay_presenter.gd` (`_style_reward_button`)
- Změna: tlačítko odměny ukazuje cenu, statistiky (u kouzel/předmětů typ) a první větu pravidel; celé pravidlo zůstává v tooltipu. Písmo 15 a obrázek 150 px, aby se text vešel do pevné výšky tlačítka.
- Ověření: `capture_reward.gd` (okno), všech 23 verifierů.

### 2026-10-22 - Balík a postup: náhled karty při najetí myší (Claude Opus 5.5)
- Oblast: UI stavění balíku (D2)
- Soubory: `ui/progression_screen.gd`, nový `tools/capture_progression_hover.gd`
- Změna: najetí na řádek kolekce/balíku ukáže velkou kartu (`selected_card_preview.tscn`, full) nad protějším panelem, takže je vidět art i pravidla. Kouzla a předměty v řádku ukazují „Trik/Předmět · cena X“ místo nesmyslného „0/0“.
- Ověření: `capture_progression_hover.gd -- <png> [card_id]` (okno), všech 23 verifierů.

### 2026-10-22 - Balanc: Věštkyně těžší než Ragclaw (Claude Opus 5.5)
- Oblast: balanc tréninku (D-022: každý další soupeř těžší)
- Soubory: `data/decks/npc_fog_seer.tres`
- Změna: sim 120 her ukázal, že Věštkyně (4.) je lehčí než Ragclaw (3.): 25,8 % vs 14,6 % výher AI hráče. Svíčkotlapý zvěd 3→2, Šedý veterán 1→2. Zkoušeno a zamítnuto: Přístavní poslíček místo Myšolovce (38 %) i místo Rváče (32 %), Věštkyni chybí obrana, ne zranění.
- Výsledek sim 120 (výhry AI hráče): Smug 73,3, Lantern 34,2, Ragclaw 14,6, Fog 9,6, Harbor 7,9, Bilge 2,5 %. Pořadí sedí.
- Ověření: `sim_ai_matches.gd -- 120`, všech 23 verifierů.

### 2026-10-22 - Výsledková obrazovka: rodově neutrální texty, větší trasa (Claude Opus 5.5)
- Oblast: UI po zápase
- Soubory: `battle_controller.gd`, `battle_overlay_presenter.gd`
- Změna: „jsi dotáhl do konce“ → „máš za sebou“, „jsi nevyhrál“ → „nevyšel“ (hrát může kdokoli). Portréty trasy výpravy 54×40 → 80×60, byly nečitelné.
- Ověření: `capture_postmatch_modes.gd` (okno), všech 23 verifierů.

### 2026-10-22 - Pravý panel v tahu soupeře (Claude Opus 5.5)
- Oblast: UI souboje
- Soubory: `battle_controller.gd` (`_enemy_last_played`), `battle_preview_presenter.gd`
- Změna: místo prázdného panelu s větou „Soupeř je na tahu“ teď panel ukazuje velkou kartu, kterou soupeř právě zahrál, a pod ní „Tuhle kartu soupeř právě zahrál…“. Hover má přednost. V síťové hře to klient pozná z rozdílu snímků (`_find_net_enemy_play`: nová kočka na stole, nebo kouzlo v odhazování a menší ruka); při více kartách v jednom snímku ukáže poslední.
- Ověření: `capture_enemy_turn.gd` (okno, screenshot), `net_smoke` host+klient (shodný výsledek, `panel_soupeře=7` u klienta), všech 23 verifierů.

### 2026-10-22 - Soupeři s novými kartami (Claude Opus 5.5)
- Mlžná věštkyně: 2× Lovec potkanů místo 2× Síťodrápý nájezdník. Stokový král: 2× Lamač z doků místo 2× Trámový skokan. (Tito dva nemají profil hrozby, ostatní balíky beze změny.)
- Sim 60 her/pořadí (AI hráč, startovní balík): Smug 70.8, Lantern 35.8, Ragclaw 20.0, Fog 23.3 (dřív 19.2), Harbor 10.0, Bilge 4.2 (dřív 2.5) %. Boss dál nejtěžší.
- Ověření: 23/23 verifierů.

### 2026-10-22 - Ruka: štítek TRIK / PŘEDMĚT (Claude Opus 5.5)
- Kouzla a předměty v ruce mají místo odznaků útoku a životů barevný štítek typu (trik červeně, předmět modře); keyword pilulka se v úzké ruce nezobrazuje, takže typ nebyl vidět.
- capture_midgame.gd: volitelný 2. argument = karty do ruky (kontrola nového artu). Screenshot artifacts/newart.png.
- Ověření: 23/23 verifierů.

### 2026-10-22 - Archy ilustrací A a B od majitele (Claude Opus 5.5)
- Arch A (9 nových karet D3) a arch B (9 kouzel a předmětů, dřív jen ikona) rozřezány `slice_art_sheet.gd`, zdroje v `assets/card_game/card_art_source/sheet_A/B_2026-10-22.webp`.
- Zbývá arch C (spiked_collar, war_plate, watchmans_bell, tavern_bouncer, portrait_rival, harbor_courier, net_mender, cannon_cat, fish_market) – Mark odpoledne.
- Ověření: kontrola výřezů, 23/23 verifierů.

### 2026-10-21 (noc) - MP: klient nedostává karty hosta (Claude Opus 5.5)
- Snímek posílá ruku a balík hosta jen jako počet (zástupná karta), klient tak nemůže nahlížet. verify_net_snapshot to kontroluje.
- Review síťového kódu (odpojení, dvojitý konec tahu, odveta po odchodu, návrat do menu): bez dalších nálezů.
- Ověření: net_smoke OK, 23/23 verifierů.

### 2026-10-21 (noc) - Celá obrazovka a mezerník (Claude Opus 5.5)
- Nastavení: přepínač „Celá obrazovka (F11)“, F11 funguje všude (Sfx autoload, ukládá se do settings.cfg). Souboj: mezerník = Konec tahu; tlačítka v pravém panelu nedrží focus (mezerník by jinak mačkal naposled kliknuté).
- Ověření: artifacts/settings.png, 23/23 verifierů. Ruční test kláves jen člověk.

### 2026-10-21 (noc) - Výsledek zápasu a stůl: úklid po Hrozbě (Claude Opus 5.5)
- Výsledek: skrytá prázdná plaketa hrozby, texty vycentrované, výhra „X je poražen. Stůl je tvůj.“, prohra „X si stůl drží. Zkus jiný balík nebo jinou taktiku.“ (místo hrozby).
- Stůl: indikátor vpravo nahoře jen u připravené kočky (UI rozbor bod 7).
- Ověření: artifacts/reward_v2.png, rp_mid.png, 23/23 verifierů.

### 2026-10-21 (noc) - Čitelnost ruky (UI rozbor bod 4/6) (Claude Opus 5.5)
- Karta v ruce: jméno na vlastním pruhu nad odznaky (dřív useknuté „Svíčkotlap…“), 15/13/12 px podle délky. Nehratelná karta ztlumená jen na 0.8 (dřív 0.62, nešla číst). Ruka/Balík soupeře 16 px.
- Export: připraven `export_presets.cfg` (Windows, build/Catnapped.exe, v .gitignore); chybí šablony 4.6.2 (jsou jen 4.7.1) → stáhnout v editoru.
- Ověření: screenshot artifacts/rp_mid.png, 23/23 verifierů.

### 2026-10-21 (noc) - D3: 13 nových karet (47 sběratelných), kouzla bez cíle (Claude Opus 5.5)
- Kočky: Kotě na hlídce, Rybářka s návnadou, Lovec potkanů, Lanový akrobat, Kormidelník, Lamač z doků, Přístavní poslíček, Spravovačka sítí, Dělová kočka. Kouzla: Teplé mléko, Přes palubu!, Rybí trh. Předmět: Rezavá kotva. Vše jen ze stávajících mechanik.
- Odemykání v tréninku 4–6 karet za soupeře; nové kočky v odměnách výprav. Dělová kočka max 1 kopie.
- Oprava: kouzlo bez cíle (Rybí trh) hráč dřív zahrát nemohl (hláška „spustí se hned“, ale nic). Teď druhý klik na kartu nebo klik na stůl; v síti akce `play_instant`.
- Art: zatím kopie podobných obrázků; prompt na 3 archy `design/art_prompt_2026-10-22.md`. Překlep „získa“ → „získá“.
- Ověření: verify_new_cards rozšířen (všech 13), 23/23 verifierů, net_smoke OK. NPC balíky beze změny (balanc tréninku stejný).

### 2026-10-21 (noc) - MP: odveta (Claude Opus 5.5)
- Po zápase „Chci odvetu“ (klient pošle žádost) / „Odveta“ (host znovu načte scénu, nový los, kdo začíná). Klient po prvním snímku nového stolu schová výsledek.
- Ověření: `NET_REMATCH=1` net_smoke: dva zápasy po sobě, výsledky obou stran sedí; 23/23 verifierů.

### 2026-10-21 (noc) - MP: klient vidí efekty a slyší zvuky soupeřových akcí (Claude Opus 5.5)
- Host si zapisuje `_queue_lane_fx` a `_play_sfx` (net_battle.gd `record_fx/record_sfx`), pošle je se snímkem, klient je přehraje (`_replay_net_events`). Výhra/prohra se nesdílí (každý má svou).
- Ověření: net_smoke v okně (host i klient), bez chyb; 23/23 verifierů.

### 2026-10-21 (noc) - Incident: síťový test v okně přepsal skutečný save (Claude Opus 5.5)
- Co: `net_smoke.gd` spuštěný v okně (kvůli screenshotu) volal `reset_state()`; testovací save se volil jen podle headless, takže se smazal Markův postup (6 výher, 2 prohry, balík 23 karet).
- Náprava: save obnoven ze screenshotů artifacts/c_prog.png a deckbuild.png (záloha artifacts/save_backup_2026-10-21.cfg; hrozba 0, trénink 0, tutoriál viděn). Hrozba ani pořadí nemusí sedět na 100 %.
- Prevence: `ProgressionSystem._save_path()` vrací testovací save i pro každý běh s `--script` (i v okně); net_smoke save jen čte.

### 2026-10-21 (noc) - D4 multiplayer 1v1 přes IP / Radmin (Claude Opus 5.5)
- Oblast: síťová hra, D-024. Menu má tlačítko „Hra ve dvou“ (hostovat / připojit přes IP, ukáže IP adresy PC, Radmin 26.x první).
- Soubory: multiplayer_manager.gd (přepsán: lobby, RPC hello/start/snapshot/action/leave), nový net_battle.gd (snímek stavu, host přijímá akce, klient je zachytává), battle_controller.gd (_net háčky, _run_opponent_turn místo AI části v konci tahu, konec zápasu bez postupu), nový ui/net_lobby_overlay.gd, encounter_select.gd (tlačítko), capture_scene.gd (volitelná metoda před snímkem).
- Testy: verify_net_snapshot.gd (nový), net_smoke.gd: 10 zápasů host+klient na 127.0.0.1 dohráno, výsledky obou stran se shodují; screenshot klienta artifacts/net_client.png. 23/23 verifierů.
- Neověřeno: dva různé PC přes Radmin VPN (firewall, latence) → test s Markem.

### 2026-10-21 (noc) - D2 stavění balíku (Claude Opus 5.5)
- Oblast: kolekce a úprava balíku, D-023.
- Soubory: progression_system.gd (KEY_COLLECTION, TRAINING_CARD_UNLOCKS, limity, add/remove), progression_screen.gd (levý panel Kolekce s +, balík s −, řazení podle ceny, statistiky v jednom řádku), battle_controller.gd (výhra v tréninku vypíše nové karty v kolekci), nový verify_deck_building.gd.
- Ověření: 22/22 verifierů, screenshot artifacts/deckbuild.png.

### 2026-10-21 (noc) - Pravý panel: velký náhled karty; Stokový král ověřen jako nejtěžší (Claude Opus 5.5)
- Oblast: UI rozbor bod 3. SelectedCardPreview má režim `large` (měřítko 1.28), battle_layout.gd ho zapne v pravém panelu, schová zdvojené jméno (TitleBanner) a řádek statistik (SelectedMeta), detail 16 px.
- Balanc: sim 60 her/pořadí: Smug 70.8, Lantern 35.8, Ragclaw 20.0, Fog 19.2, Harbor 10.0, Bilge 2.5 % (AI hráč se startovním balíkem). Stokový král už je nejtěžší; 11–12 životů ho srazilo na ~1 %, proto zůstává 10. Dřívější „Bilge = Harbor“ byl šum 40 her.
- Ověření: 21/21 verifierů, screenshot artifacts/rp_mid_hover.png.

### 2026-10-21 (noc) - Hrozba pryč z UI, Balík a postup bez nebezpečného resetu (Claude Opus 5.5)
- Oblast: UI rozbor body 5–6. Obtížnost hráči ukazuje jen žebříček tréninku; hrozba dál interně volí sestavu balíku soupeře (tooltip pro ladění).
- Soubory: battle_controller.gd (úvodní a koncové hlášky), battle_overlay_presenter.gd (řádek hrozby ve výsledku skrytý), encounter_select.gd („výprava“ místo „run“), progression_screen.gd (Trénink X/6, „Smazat postup“ malé vlevo s potvrzením druhým klikem, hlavička bez černého pruhu).
- Oprava: verify_reward_flow čekal staré texty „Přidat X“; minulý push proběhl jen se dvěma verifiery (chyba procesu, teď zase všech 21).
- Ověření: 21/21 verifierů, screenshoty artifacts/menu_v2.png a prog_v2.png.

### 2026-10-21 (noc) - Layout souboje v2 (UI rozbor body 1–3) (Claude Opus 5.5)
- Zmena: `ui/battle_layout.gd` přeskládá scénu za běhu: levý sloupec (portrét soupeře s okrajem v barvě tahu, jméno Cinzel, životy, ruby karet / hlášení a záznam / tvoje životy, balík, odhazování), stůl uprostřed, ruka pod stolem s kartami na výšku (136×188), pravý panel beze změny. Art na stole i v ruce výřezem na postavu (`get_cropped_aspect`), prázdné lajny tichý obrys místo mosazného medailonu, „Přímý zásah“ jen při útoku. Hrozba z hlavičky pryč (zůstala v tooltipu). Inspirace: Marvel Snap (3 lokace, karty na výšku), Hearthstone (portrét soupeře).
- Overeni: 21/21 PASS (verifiery přepnuty na `is_empty_target_highlighted()` a nové cesty), screenshoty `artifacts/v2_*.png`.
- Další: pravý panel (velký náhled, méně textu), menu se dvěma režimy, odměny (skloňování, šipka).

### 2026-10-21 (noc) - Soupeři 5 a 6, karty Lodní hlídka a Pašerák (Claude Opus 5.5)
- Zmena: Mlžná věštkyně (`fog_seer`, zranění při vyložení, Lampářky, Hlídky) a Stokový král (`bilge_king`, finální boss, Hodování, Pašeráci). Žebříček i run: Smug → Lantern → Ragclaw → Věštkyně → Harbor → Král; run má 6 soubojů. Karty: Lodní hlídka 2 Tuny 1/3 (při vyložení lízni), Pašerák 4 Tuny 3/4 (při vyložení 2 zranění soupeři), obě v poolu odměn. Bonus životů za stupeň je omezen na 3. stupeň (+6), protože soupeř se +8/+10 byl v simu neporazitelný.
- Overeni: 21/21 PASS (3 verifiery navázány na velikost rosteru), sim p_first Smug 90 / Lantern 42,5 / Ragclaw 27,5 / Věštkyně 32,5 / Harbor 12,5 / Král 12,5 %.
- Otevřené: Král by měl být nejtěžší, je na úrovni Harboru. Doladit po lidském testu.

### 2026-10-21 (noc) - Arch portrétů od majitele (Claude Opus 5.5)
- Zmena: Vlastní portréty soupeřů Lantern/Ragclaw/Harbor (dřív půjčené karty), art Tuláka, rub karty (`card_back.png`, soupeřova ruka), ikona hry `icon.png` vyříznutá z Ragclawa (`make_app_icon.gd`). Připravené pro budoucnost: `portrait_fog_seer`, `portrait_bilge_king`, `ship_lookout`, `smuggler`. `slice_art_sheet.gd` nově odřezává tmavé okraje (arch s vnějším rámem).
- Overeni: 21/21 PASS, screenshot menu.

### 2026-10-21 (noc) - D1 žebříček tréninku (Claude Opus 5.5)
- Zmena: Soupeři v menu jsou žebříček: další se odemkne až výhrou nad předchozím (`training_cleared` v save). Stupeň N (0–3) = soupeř má +2N životů, od 3. stupně kartu navíc do ruky, hrozbu +2N. Stejný stupeň platí i pro kroky runu. Sim ukázal, že samotná hrozba obtížnost skoro nemění (Harbor s vyšší hrozbou dokonce lehčí), proto páka přes životy a kartu.
- Soubory: progression_system (TRAINING_ORDER, mark_training_win…), battle_controller (`_get_difficulty_tier`, `_get_threat_bonus`, `_record_training_win`), encounter_select (zamčeno, životy podle stupně), sim arg `noladder`, nový `verify_training_ladder.gd`.
- Overeni: 21/21 verifierů PASS (nový test odhalil chybu: výhra nad zamčeným soupeřem odemykala), sim p_first Smug 90 → Lantern 42,5 → Ragclaw 27,5 → Harbor 12,5 % (AI hráč, člověk je silnější). Screenshot menu.

### 2026-10-21 (noc) - Art 9 nových karet od majitele (Claude Opus 5.5)
- Zmena: Mark dodal arch 3×3; nový nástroj `tools/slice_art_sheet.gd` najde tmavé linky mezi políčky, ořízne na 2:3 a uloží 1024×1536 do `card_art/<id>.png`. Zdroj archu v `assets/card_game/card_art_source/`. Karty: lamplighter, dock_harpooner, pickpocket, stray_mother, galley_cook, harbor_drummer, grey_veteran, carrion_prowler, graveyard_glutton.
- Overeni: 20/20 verifierů PASS, screenshot `capture_midgame` (ruka: Harpunář, Šedivý veterán, Kapsář).

### 2026-10-21 (večer) - Lidský test #3: celý run vyhrán, ladění (Claude Opus 5.5)
- Zpětná vazba: „bavil jsem se, chápal jsem to, přemýšlel jsem; nevím úplně, jestli to fungovalo, jak mělo“. Záznamy: 5/5 výher, Smug 13–14 kol (11 kol bez zranění), Lantern 4, Ragclaw 5, Harbor 10.
- Změna: D-021 (myšolovec 2/3, sílící soupeři v runu). Hlášky: Ochrana ze sousední lajny říká „přiskočí ze sousední lajny N“; místo „Sem X nejde“ důvod (obsazeno / málo Tuny).
- Ověření: 20/20 verify PASS, sim (D-021).

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
