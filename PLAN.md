# PLAN.md – roadmapa (2026-10-20, vede Claude Opus 5.5 jako hlavní jednatel)

## Priorita od 2026-10-23 (Mark: multiplayer až na konec)
1. Vizuální úpravy: audit všech obrazovek screenshotem, opravy po jedné ose.
2. E4 sbírka ~60 karet (+12 karet a art).
3. E3 dokončit obchod (zkrátit automatické odemykání).
4. Až na konci: hra ve dvou – test přes Radmin, balanc tanků při 30 životech, doladění.

## Hotovo (stav k 2026-10-07)
- Cat-only core, 3 lane board, run se 4 NPC, reward draft, progression, threat
- Split battle controlleru na presentery (07-16), oprava češtiny (07-17)
- Saved Tuna (07-24), všech 19 verify skriptů prochází (ověřeno znovu 2026-10-20)

## Klíčová zjištění auditu 2026-10-20
1. **Stůl je nečitelný:** karty na boardu nemají obrázek ani jméno. `StatusBadge` je v `PanelContainer`u, takže ho roztáhne přes celý slot (velký medailon) a překryje jméno.
2. **Karty v ruce:** art je malá ikonka uprostřed modrého boxu.
3. **Pravý panel:** prázdný rám a překrývající se texty.
4. **Diakritika:** chybí ve jménech NPC („Namysleny kocour“) a v některých textech.
5. **Saved Tuna je mrtvá mechanika:** výchozí hra (starter, NPC decky, reward pool) neobsahuje žádný Trick, Saved Tuna jde utratit jen za Trick. Combat Trick window by dopadl stejně.
6. **Obsah:** reálně se hraje s 10 kočkami (jen ty mají art). Feast karty jsou hotové v enginu, ale bez artu a mimo pool.

## Fáze A – Čitelnost (blokuje lidské testování)
- [x] A1 Board token: art karty, jméno, cost/útok/životy v odznacích; oprava roztaženého StatusBadge
- [x] A2 Karty v ruce: velký art, čitelné jméno a staty
- [x] A3 Pravý panel (vybraná karta): art, bez překryvů
- [x] A4 Diakritika ve jménech NPC a UI textech (+ texty rozbité na „?“)
- [x] A5 `capture_midgame.gd` + `capture_enemy_turn.gd` pro vizuální kontrolu
- [x] A6 Skrýt „Rez.“ (Saved Tuna) v UI, když deck nemá Trick (D-013)
- [x] **Lidský test #1**: přehlednější, ale smyčka smrti → D-014, D-015

## Fáze B – Herní pocit
- [x] B1 Výpad útočníka, otřes + záblesk + plovoucí číslo, dopad vyložené karty (smrt: zatím jen KO zvuk)
- [x] B2 Tah AI po krocích (0,75 s/akce), zámek vstupu
- [x] B3 Zvuky + hudba (Kenney CC0, RandomMind CC0), cvaknutí tlačítek, font Alegreya
- [x] B4 Přechody mezi scénami (fade), banner tahů, mizení padlé kočky
- [x] B5 Pravý panel: průvodce „Co teď?“ + náhled karty pod myší
- [x] B6 Nastavení hlasitosti + titulky (CC BY)

## Fáze C – Obsah a hloubka core
- [x] C0 Odveta + ruka 4 + balanc starteru a NPC (D-014, D-015)
- [x] C1 Feast karty + 7 nových koček v reward poolu, placeholder art, prompty (D-016)
- [x] C1b Art nových karet (arch od Marka rozřezán `slice_art_sheet.gd`)
- [x] C1c Ikony keywordů (game-icons CC BY) u štítků na stole
- [x] **Lidský test #2** (24. 10. Mark: „zajímavější, hezčí“, vzhled „ještě to není ono“, nespěchá; Pašerák matoucí text → opraveno)
- [x] C2 Balanc podle `sim_ai_matches.gd` (D-015, D-017 Hlad proti patu)
- [x] C2b Záznamy zápasů pro analýzu lidských testů (`user://match_logs/`)
- [ ] C3 Po lidském testu: rozhodnout návrat malé sady čitelných Triků do rewardů (oživí Saved Tuna)

## Fáze D – Trénink + multiplayer (D-022)
- [x] D1 Trénink: žebříček soupeřů, každý těžší, odemykání postupně
- [x] D2 Stavění vlastního balíku (z odemčených karet), D-023
- [x] D2b Hra ve dvou: balík přesně 30 karet / 3 kopie, Doplnit, křivka ceny, filtry (D-029)
- [ ] Balanc tanků při 30 životech (sim: Stokový král dominuje)
- [x] D3 Víc karet: 47 sběratelných (2026-10-21), art čeká na archy A–C (`design/art_prompt_2026-10-22.md`)
- [x] D4 Multiplayer 1v1 LAN/přímá IP (host je autorita, snímky stavu), D-024; čeká na test ve dvou přes Radmin
- [ ] D5 Hra přes internet (relay/Steam), až po D4

## Fáze E – Hloubka a sbírka (D-025, Markovy nápady 2026-10-22)
- [x] E1 Méně výměn 1:1 (Mark: „pořád se to jen mlátilo dokola“): přeladit statistiky koček, víc koček s životy nad útokem stejné ceny; měřit `smrt obou` v `sim_ai_matches.gd` (teď 26–48 %, cíl pod 30 %)
- [x] E2 Tuna karty: trik „Sardinková konzerva“ (+2 Tuna jen v tomto kole) a podobné; umožní dřív větší kočky = méně zrcadlových výměn
- [ ] E3 Obchod: měna za výhry (trénink i hra ve dvou), 3 nabídky po každém zápase; nahradí část automatického odemykání
  - Hotovo 22. 10.: logika, šupiny po zápase proti AI, obchod nad kolekcí v Balík a postup (`verify_shop.gd`). Zbývá: šupiny ve hře ve dvou, zkrátit automatické odemykání. Zatím Mark otestuje. Návrh (Claude 22. 10.): měna „rybí šupiny“ v save (`KEY_SCALES`). Výhra v tréninku 10 + 5 × stupeň soupeře, prohra 3, hra ve dvou 5 za zápas. Po zápase 3 náhodné karty mimo tréninkovou kolekci, cena 5 + 5 × cena karty, nákup = karta do `KEY_COLLECTION`. Automatické odemykání (`TRAINING_CARD_UNLOCKS`) zkrátit na 2 karty za soupeře, zbytek jen obchodem.
  - Kde: logika v `progression_system.gd` (get/add šupin, `roll_shop_offers(state, seed)`, `buy_card`), UI na výsledkové obrazovce (`battle_overlay_presenter`) a stav šupin v Balík a postup. Verifier `verify_shop.gd` jen na testovacím save.
- [x] E4 Sbírka v1 kolem 60 karet: 59 (40 koček, 12 triků, 8 předmětů), 24. 10. Zbývá art (prompt `design/art_prompt_2026-10-24_e4.md`)
- [x] UX audit stolu v3 (barva strany, světlo tahu, méně textu), 24. 10.
- [ ] UX: vějíř ruky s vyjetím po najetí; pravý panel na vyžádání (viz `design/ux_audit_2026-10-24.md`)
- [ ] Agresivní balíky levných koček jsou slabé (sim 5 % i proti startéru): posílit 1–2 drop kočky nebo dát agru nástroj
- [x] E5 Hra ve dvou: každý má všechny karty (balík z celé sbírky); obchod a odemykání jen v tréninku
- [x] E6 Sim balík proti balíku (hráčské balíky, ne NPC): hlídat, že žádná karta ani balík nedominuje. Nové karty po sadách 15–20, každá sada projde simulací

## Odloženo (vědomé rozhodnutí, D-013)
- Combat Trick window: až budou Tricky zpátky ve hře a core projde lidským testem
- Deckbuilding / shop / collection: deckbuilding hotový (D2), obchod naplánovaný jako E3
- Multiplayer

## Čeká na majitele
- Lidské testování (průběžně, checklisty v HANDOFF.md)
- Art pro Feast karty a Tricky/Itemy (do té doby placeholder)
- Rámy slot highlight / counter s průhledným středem (volitelné)
