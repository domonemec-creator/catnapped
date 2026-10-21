# Decisions

Ucel: trvala rozhodnuti, ktera maji ovlivnit dalsi navrh hry nebo implementaci.
Zapisuj sem jen veci, ktere by se pri dalsi praci nemely potichu rozbit nebo otocit.

## Sablona rozhodnuti

### D-XXX - Nazev
- Datum:
- Stav: aktivni | nahrazeno
- Kontext:
- Rozhodnuti:
- Dopad:

## Rozhodnuti

### D-001 - Projekt ma trvalou pamet v repozitari
- Datum: 2026-06-20
- Stav: aktivni
- Kontext: Prace probiha po vice chatech a bez trvaleho zapisu se ztraci duvody zmen i posledni overeni.
- Rozhodnuti: Udrzovat `docs/worklog.md` pro vecny zapis zmen a `docs/decisions.md` pro dulezita pravidla a smer projektu.
- Dopad: Dalsi agent i clovek rychleji navaze a min casto vrati projekt o krok zpet.

### D-002 - Threat se pred prvni vyhrou nezveda
- Datum: 2026-06-20
- Stav: aktivni
- Kontext: Start hry byl zbytecne tvrdy, pokud se threat rozjizdel driv, nez hrac zvladl prvni vyhru.
- Rozhodnuti: Threat zustava na 0, dokud hrac neziska prvni vyhru. Az potom se odemyka bezny progression flow.
- Dopad: Uvodni run je citelnejsi a prvni uspech nespousti frustraci moc brzo.

### D-003 - Leceni nesmi jit pres max_life
- Datum: 2026-06-20
- Stav: aktivni
- Kontext: AI se v dlouhe hre dostala nad svuj startovni pocet zivotu, coz pusobilo jako chyba.
- Rozhodnuti: Leceni hrace i AI respektuje `max_life`. Pokud nejaka karta nebo efekt potrebuje tenhle strop porusit, musi to byt explicitni specialni pravidlo.
- Dopad: Stav zivotu je predvidatelny a hrac nevidi nahodne "pridane" HP.

### D-004 - Overflow damage neni globalni pravidlo
- Datum: 2026-06-20
- Stav: aktivni
- Kontext: Padl navrh, aby prebytecne poskozeni po zabiti karty slo automaticky do nepratele.
- Rozhodnuti: Overflow damage nebude globalni soucast zakladniho souboje. Muze existovat jen jako explicitni keyword nebo specialni efekt vybranych karet.
- Dopad: Zakladni boj zustava srozumitelny a overflow si nechava designovy prostor jako vyjimka.

### D-005 - Prechody mezi progression screeny nesmi stat na cyklickem preloadu
- Datum: 2026-06-20
- Stav: aktivni
- Kontext: Tlacitko `Zpet na vyber` vypadalo aktivne, ale navrat nefungoval kvuli vzajemnemu preloadu obou scen.
- Rozhodnuti: Prechody mezi encounter select a progression screen maji pouzivat runtime `load()` nebo centralni scene switching, ne vzajemny `preload()` obou scen.
- Dopad: Mensi riziko mrtvych tlacitek a snazsi debug scene navigace.

### D-006 - Prazdny board slot ma vypadat jako misto pro kartu, ne jako genericky blok
- Datum: 2026-06-20
- Stav: aktivni
- Kontext: Velke tmave placeholder bloky na lajnach utapely samotne karty a nepusobily jako jasne misto, kam karta patri.
- Rozhodnuti: Prazdne lajny maji pouzivat card-shaped nebo ghost frame placeholder ve stejnem vizualnim jazyce jako skutecne board karty. Obdelnikovy podklad slotu ma zustat jen jako jemna podpora, ne hlavni vizual.
- Dopad: Board je citelnejsi a sloty pusobi jako soucast hry, ne jako debug container.

### D-007 - Board hierarchie ma zvyraznit kartu, ne container
- Datum: 2026-06-20
- Stav: aktivni
- Kontext: I po nahrazeni placeholderu porad board pusobil prehlcene, protoze vedle samotne karty soutezily o pozornost velke lane boxy, siroke event bannery a dominantni stavovy panel.
- Rozhodnuti: V klidovem stavu ma byt nejsilnejsim prvkem karta nebo slot asset. Lane kontejnery maji zustat skoro neviditelne a preview nebo feedback bannery maji byt mensi a druhotne.
- Dopad: Dalsi UI prace ma preferovat cisteni hierarchie pred pridavanim dalsich ramecku nebo velkych overlay vrstev.

### D-008 - Preview obsazeneho slotu patri do praveho panelu, ne pres kartu
- Datum: 2026-06-20
- Stav: aktivni
- Kontext: Friendly target preview a nektere dalsi preview stavy kreslily textured bannery primo pres obsazenou kartu, takze hrac na stole videl spis zelenou nebo cervenou plachtu nez skutecnou kartu.
- Rozhodnuti: Pokud je slot obsazeny, preview text ma byt primarne v pravem panelu. Na samotnem stole ma preview pouzit nanejvys highlight nebo maly signal, ne velky overlay banner pres kartu.
- Dopad: Dalsi preview systemy by nemely vracet plne lane bannery na obsazene sloty, pokud k tomu nebude silny UX duvod.

### D-009 - Akcni tlacitka v pravem panelu maji prednost pred dlouhym textem
- Datum: 2026-06-20
- Stav: aktivni
- Kontext: Dlouhy lethal warning v selected panelu dokazal prerust pres `Hod pamlskem` a `Konec tahu`, takze hrac nemohl normalne dokoncit tah.
- Rozhodnuti: Pravy info panel ma byt prostorove omezeny a dlouhe texty se maji zkratit, skrolovat nebo orezat driv, nez zasahnou do akcni oblasti s tlacitky.
- Dopad: Pri dalsich zmenach copy nebo preview logiky se ma chranit klikatelnost akcnich tlacitek jako vyssi priorita nez zobrazeni celeho dlouheho textu bez omezeni.

### D-010 - Quick Paws dava okamzity utok jen jedne nove kocce za tah
- Datum: 2026-06-20
- Stav: aktivni
- Kontext: Kdyz AI nebo hrac vylozili vice karet s `Quick Paws` v jednom tahu, vsechny mohly hned utocit, coz pusobilo nefer a tezko citelne.
- Rozhodnuti: V jednom tahu muze okamzity utok ziskat jen jedna nove vylozena kocka s `Quick Paws`. Ostatni nove vylozene kocky se stejnym keywordem musi cekat do dalsiho tahu.
- Dopad: Tempo burst z vice `Quick Paws` karet je omezeny, AI je citelnejsi a texty karet i verifikace musi tohle pravidlo respektovat.

### D-011 - Zakladni hra se vraci na cat-only core bez defaultnich powers
- Datum: 2026-07-07
- Stav: aktivni
- Kontext: Pro noveho hrace byla hra neprehledna hlavne kvuli off-board trikum, itemum a powers, ktere zabijely nebo menily board bez jasneho modelu v hlave.
- Rozhodnuti: Defaultni starter, defaultni NPC decky, run reward pool a threat profily se v jednoduchem zakladu osekavaji na kocky a citelne keywordy. Defaultni encountery i hrac zacinaji bez `Sily stolu`; engine pro powers, itemy a triky zustava v projektu pro pozdejsi navrat.
- Dopad: Prvni hry jsou citelnejsi, smrt karty casteji plyne z viditelneho boardu a dalsi rozvoj muze znovu pridavat slozitost az nad stabilni jednoduchy zaklad.

### D-012 - LoR inspirace bude selektivni, ne plny prepis combat modelu
- Datum: 2026-07-24
- Stav: aktivni
- Kontext: Padl pozadavek prozkoumat `Legends of Runeterra` a pouzit jeji principy pro dalsi smer Catnapped. Projekt ale uz ma zamceny `3 lane` board, kratke zapasy, jednosmerny tlak do otevrenych linek a zjednoduseny `cat-only core`.
- Rozhodnuti: Catnapped nebude prejimat plne sdilene roundy, volne blocker assignment ani plny spell stack. Pokud se z LoR bude neco brat, pujde hlavne o omezeny `Saved Tuna` bank pro Triky, uzky `Combat Trick` response window a formalni initiative/tie-break pravidla. Podrobny navrh je v `design/catnapped_runeterra_lite.md`.
- Dopad: Hra si neznici lane identitu ani citelnost, ale porad muze ziskat vic napeti, bluffu a resource planningu bez skoku do mnohem drazsi AI a UI complexity.

### D-013 - Nejdřív zábavné a čitelné core, Combat Trick window odložen
- Datum: 2026-10-20
- Stav: aktivni
- Kontext: Audit ukázal, že výchozí hra (D-011) neobsahuje žádný Trick, takže Saved Tuna i plánovaný Combat Trick window nemají ve skutečné hře využití. Zároveň byl board vizuálně nečitelný (karty bez artu a jména), takže nikdo nemohl hru reálně hodnotit.
- Rozhodnutí: Priorita je čitelnost a herní pocit core (art, animace, zvuk, tempo AI) a lidský playtest. Combat Trick window se odkládá, dokud se Tricky nevrátí do hry. Saved Tuna zůstává v enginu, ale UI ji ukazuje jen tehdy, když některý deck v zápase obsahuje Trick. Návrat malé sady čitelných Triků (přes reward draft, ne starter) se rozhodne po lidském testu.
- Dopad: Žádná další LoR-like pravidla, dokud core neprojde testem. Vývoj jde do UX a obsahu, které hráč opravdu uvidí.

### D-014 - Odveta: napadená kočka vrací úder
- Datum: 2026-10-20
- Stav: aktivni (nahrazuje „one-way lane combat“ z `design/catnapped_runeterra_lite.md`)
- Kontext: Lidský test #1: „vyložím kočky, další kolo umřou, a tak dokola, dokud neumřu“. Jednosměrný souboj dělal útok zadarmo. Kdo měl připravené kočky, zabíjel každou čerstvou kočku soupeře bez ztráty. Simulace: asi 35 % vyložených koček umřelo bez jediného útoku.
- Rozhodnutí: Při útoku na kočku (i na Ochranu, která zásah zachytí) vrací bránící kočka útočníkovi úder svým aktuálním útokem, současně (i když sama padne). Přímý zásah do soupeře odvetu nemá. AI hodnotí výměny (`_score_trade`) a nevýhodné útoky vynechá. Přepínač je `CardGameConstants.combat_retaliation` (static var kvůli A/B simulaci).
- Dopad: Ve hrách proti agresivním soupeřům klesl podíl „zbytečných“ koček z 35 na 25 %. Kočky s vysokými životy zesílily, proto prošly balancem 3-dropy (Síťodrápý nájezdník 3/3, Přístavní hrdlořez 3/3, Trámový skokan 4/2) a Dokový rváč (3/5).

### D-015 - Startovní ruka 4 karty, starter a NPC balíky přeladěné
- Datum: 2026-10-20
- Stav: aktivni
- Kontext: Start na 3 Tunách s líznutím 1 karty za kolo vede k hladovění: kolem 3. a 4. kola dojdou karty a pak rozhoduje jen stůl. Starter (samé kočky 1/2 a 3/2) proti Smug Tabbymu (první soupeř runu) v simulaci vyhrával 2–6 %.
- Rozhodnutí: `starting_hand = 4` (líznutí zůstává 1, protože 2 líznutí příliš zvýhodnila prvního hráče). Nový starter: Svíčkotlapý zvěd ×3, Uliční rváč ×4, Hospodský myšolovec ×3, Rybokostěný plíživec ×3, Síťodrápý nájezdník ×2, Dokový rváč ×3, Kotelní strážce ×1, Kapitán ×1. Smug Tabby je teď „učitelský“ balík s menším počtem těžkých obránců. Harbor Warden je zmírněný a přesunutý na konec runu jako boss (pořadí Smug → Ragclaw → Lantern → Harbor). Save se starým starterem se migruje na nový (`ProgressionSystem.LEGACY_STARTER_2026_07`).
- Dopad: Simulace AI starter vs NPC (výhra hráče): Smug ~80 %, Ragclaw ~50 %, Lantern ~45 %, Harbor ~11 %. Člověk hraje líp než AI. Balanc je velmi citlivý na 2–3 karty, takže změny balíků vždy přeměř přes `sim_ai_matches.gd` (sloupce `wasted_pct`, `starved_pct`, `timeout_pct`).

### D-016 - Nové kočky přes rozšířené spouštěné efekty, art od majitele
- Datum: 2026-10-20
- Stav: aktivni
- Kontext: Hrálo se jen s 10 kočkami. Majitel chtěl nové karty. Malovaný art ve stejném stylu se nedá legálně stáhnout, majitel ho generuje sám.
- Rozhodnutí: `_resolve_triggered_effects` umí nově `deal_damage` (opposite_lane / enemy_player), `modify_attack` a `modify_life` (adjacent_lane) a `summon_token`. Poslední dech zná lajnu zemřelé kočky. Přibylo 7 koček (Lampářka, Harpunář, Kapsář, Toulavá máma, Kuchař z podpalubí, Přístavní bubeník, Šedivý veterán), všechny v reward poolu spolu s oběma Feast kartami. Karty bez artu ukazují rub karty (`_placeholder_back.png`) přes `CardArtCache`. Prompty jsou v `design/art_prompts_2026-10.md`.
- Dopad: Vlastní art stačí uložit jako `assets/card_game/card_art/<id>.png`. Verifier `verify_new_cards.gd`.

### D-017 - Hlad: prázdný balík bere životy
- Datum: 2026-10-20
- Stav: aktivni
- Kontext: Odveta (D-014) udělala ze zdí s vysokými životy pevné pozice. AI odmítá nevýhodné útoky, zápasy se táhly (mirror 35–39 půltahů) a 3–7 % skončilo v patu na limitu tahů. Pat je další forma „smyčky“, na kterou si majitel stěžoval.
- Rozhodnutí: Když má hráč líznout z prázdného balíku, ztratí `hunger_count` životů (1, 2, 3…). Hlášku dostane status i průvodce „Co teď?“. `PlayerBattleState.hunger_count`, `_draw_or_starve`.
- Dopad: Pat 0 %, zápasy kratší. Harbor Warden tím zeslábl (11 → 57 %), proto má zpět 2. Kotelního strážce (→ ~41 %, boss). Verifier v `verify_new_cards.gd`.

### D-018 - Podpisové karty soupeřů a pořadí runu podle obtížnosti
- Datum: 2026-10-20
- Stav: aktivni
- Rozhodnutí: Lucernový útočník má 2× Lampářku, Ragclaw 2× Kapsáře, Harbor 1× Harpunáře (zůstávají i při eskalaci hrozby). Pořadí runu je Smug → Lantern → Ragclaw → Harbor. Simulace (AI starter, výhra hráče): ~82 / ~59 / ~50 / ~29 %, tedy stoupající obtížnost. Menu u soupeře zmiňuje jeho podpisovou kartu.

### D-019 - Bez léčení hráče; Ochrana dál kryje sousední lajny
- Datum: 2026-10-21
- Stav: aktivni
- Kontext: Lidský test #2 (krátký): „často jsme se healovali, hra neměla konce“. Léčení měly Dokový rváč (Bojový nástup: vyleč 1, 3× ve starteru a 3–4× u soupeřů) a Kotelní strážce (Poslední dech: vyleč 1). Při 10 životech je to 10 % zdraví za kartu.
- Rozhodnutí: Léčení z obou karet odstraněno. Dokový rváč je teď 4/5 a „Poslední dech: lízni 1 kartu“, Kotelní strážce 2/6 a „Ochrana“. Ochranu jen pro vlastní lajnu jsem otestoval (`guard_covers_adjacent`, sim arg `guardlane`): zápasy zkrátí jen málo (28 → 26 půltahů) a rychlé soupeře udělá příliš silnými, proto zůstává krytí sousedů. Harbor má 2× Harpunáře, aby zůstal nejtěžší.
- Dopad (sim, hráč táhne první jako ve hře): Smug ~90 %, Lantern ~55 %, Ragclaw ~55 %, Harbor ~48 %. Simulace neměří pocit z délky hry, ten ověří jen člověk.

### D-020 - „Objednat rundu“ a jasnější útok čerstvých koček
- Datum: 2026-10-21
- Stav: aktivni (částečně mění D-011: hráč má Sílu stolu, soupeři zatím ne)
- Kontext: Záznam lidského testu (Lantern, prohra 0:1, 9 kol): hráč 8× zkoušel útočit čerstvě vyloženou kočkou („teď nemůže útočit“ bez vysvětlení). Od 6. kola měli oba ruku 0–1, ale hráč nechával 5–7 Tun nevyužitých.
- Rozhodnutí: (1) Čerstvá kočka hráče má štítek „Útočí příští kolo“ a hláška vysvětluje proč. (2) Hráč má Sílu stolu „Objednat rundu“: 3 Tuny = lízni 1 kartu, jednou za tah. Nejde použít s prázdným balíkem (Hlad). AI ji používá jen s malou rukou a s balíkem nad 9 kartami. Průvodce „Co teď?“ ji nabízí.
- Dopad: Pro AI hráče je síla v simulaci zhruba neutrální (dlouhé simulované hry ji trestají Hladem). Člověk hraje kratší zápasy, kde pomáhá využít zbylou Tunu. Ověří lidský test.

### D-021 - Myšolovec 2/3 a sílící soupeři v runu
- Datum: 2026-10-21
- Stav: aktivni
- Kontext: Lidský test #3: celý run vyhrán 5:0, „bavil jsem se, chápal jsem to, přemýšlel jsem“. Záznamy: Lantern 4 kola a Ragclaw 5 kol (moc lehcí), Smug 13–14 kol, přičemž 11 kol nikdo nedostal zranění (plné lajny, myšolovci 1/4 s Ochranou).
- Zkoušeno a zamítnuto: Ochrana jen na vlastní lajně. Tím Ochrana ztratí smysl, protože do obsazené lajny útok stejně jde na kočku. Smug s menším počtem myšolovců zkrátil zápas jen nepatrně.
- Rozhodnutí: Hospodský myšolovec 1/4 → 2/3 (obránce, který i kousne, takže výměny končí dřív). V runu sílí každý další soupeř o jeden stupeň hrozby (`run step - 1` k hrozbě při skládání balíku).
- Dopad (sim, hráč první): Smug 25,7 půltahu (dřív 27), Smug ~90 %, Lantern ~48 %, Ragclaw ~48 %, Harbor ~33 %. Run ramp sim neměří (sim hraje bez runu).

### D-022 - Směr: singleplayer jako trénink, hlavní cíl multiplayer
- Datum: 2026-10-21
- Stav: aktivni (směr, detaily multiplayeru čekají na majitele)
- Kontext: Mark: „víc karet a multiplayer, postavy nechat jako singl trénink, každý těžší“.
- Rozhodnutí: (1) Soupeři z menu tvoří žebříček tréninku. Každý další je těžší a odemkne se až po porážce předchozího. (2) Víc karet, aby bylo z čeho stavět vlastní balík. (3) Multiplayer 1v1. Host je autorita (drží stav i pravidla), klient posílá jen akce. Využije stávající `MultiplayerManager` (ENet).
- Pořadí: trénink → stavění balíku → víc karet → multiplayer přes LAN / přímou IP → hra přes internet (relay/Steam) až po ověření.
- Doplněk: Testovat se bude přes Radmin VPN (virtuální LAN), takže stačí D4 (přímá IP přes ENet, port 7000 povolit ve firewallu). D5 (internet/relay) zatím ne.
- D1 provedení: stupeň = pořadí v žebříčku (i krok runu − 1): +2 životy za stupeň, od 3. stupně +1 karta do ruky, hrozba +2 za stupeň. Samotná hrozba se v simulaci ukázala jako slabá páka.
- Riziko: Multiplayer je největší kus práce (synchronizace, skryté ruce, odpojení, testování ve dvou). Hra přes internet bez vlastního serveru vyžaduje přesměrování portů nebo relay.

### D-023 - Stavění balíku (D2) a Hrozba mimo UI
- Datum: 2026-10-21
- Stav: aktivni
- Rozhodnutí: Kolekce = startovní karty + 3 karty za každého poraženého soupeře v tréninku (`TRAINING_CARD_UNLOCKS`) + vše, co kdy bylo v balíku (odměny výprav; ukládá se `collection_card_ids`). Balík 20–30 karet, max 4 kopie, Kapitán Železná tlama a Vyhazovač max 1. Úpravy v obrazovce Balík a postup (+/−), ukládají se hned, takže balík je vždy platný. Během výpravy je úprava zamčená (balík mění odměny).
- Hrozba: hráči ji už neukazujeme (obtížnost = žebříček tréninku). Interně dál volí sestavu balíku soupeře; je vidět jen v tooltipu pro ladění.
- Proč: limit 4 kopií odpovídá startovnímu balíku (4× Uliční rváč); okno 20–30 snese odměny výprav, které balík zvětšují.
- Otevřené: karty mimo trénink (Mrchožravý slídil, Bubeník, Toulavá máma, kouzla a vybavení navíc) zatím jen z odměn výprav.

### D-024 - Multiplayer 1v1: host autorita + snímky stavu (D4)
- Datum: 2026-10-21
- Stav: aktivni (ověřeno automaticky na jednom PC; čeká na test ve dvou přes Radmin)
- Rozhodnutí: Host simuluje celý souboj stávajícím `battle_controller.gd` (on = PLAYER_ID, klient = ENEMY_ID; místo AI tahu čeká na akce klienta). Po každé změně pošle klientovi snímek stavu (`net_battle.gd`, prohozené strany). Klient nic nesimuluje: akce (vylož, cílená karta, útok, Síla stolu, konec tahu) zachytí a pošle hostovi, který je ověří stejnými pravidly. RPC jsou v autoloadu `MultiplayerManager` (ENet, port 7000, 1 klient).
- Proč ne lockstep: controller je provázaný s UI a náhodou; dvě simulace by se rozjely. Snímek je malý (desítky karet) a pro tahovou hru stačí.
- Pravidla zápasu: oba 10 životů, Síla stolu Objednat rundu, vlastní balík z Balík a postup; kdo začne, se losuje (začínající si v 1. tahu nelízne). Bez postupu, hrozby a odměn.
- Známé limity v1: hlášky v záznamu jsou ve 3. osobě, žádné odvety (zpět do menu), žádná ochrana proti podvádění (klient dostává i ruku hosta).
- Test: `verify_net_snapshot.gd` (headless) + `net_smoke.gd` (dva procesy, za oba hraje AI, výsledek musí sedět otočeně).
