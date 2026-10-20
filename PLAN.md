# PLAN.md – roadmapa (2026-10-20, vede Claude Opus 5.5 jako hlavní jednatel)

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
- [ ] A1 Board token: art karty, jméno, cost/útok/životy v odznacích; oprava roztaženého StatusBadge
- [ ] A2 Karty v ruce: velký art, čitelné jméno a staty
- [ ] A3 Pravý panel (vybraná karta): art, bez překryvů
- [ ] A4 Diakritika ve jménech NPC a UI textech
- [ ] A5 `capture_midgame.gd` (rozehraná hra bez tutorialu) pro vizuální kontrolu
- [ ] A6 Skrýt „Rez.“ (Saved Tuna) v UI, když žádný deck nemá Trick (D-013)
- [ ] **Lidský test #1** (Mark): odehrát 1 run, checklist v HANDOFF.md

## Fáze B – Herní pocit
- [ ] B1 Animace útoku (výpad tokenu), poškození (otřes + plovoucí číslo), smrt (fade)
- [ ] B2 Zpomalit tah AI, aby šlo sledovat, co soupeř dělá
- [ ] B3 Jednoduché zvuky (procedurálně generované, bez externích assetů)
- [ ] B4 Přechody mezi scénami (fade)

## Fáze C – Obsah a hloubka core
- [ ] C1 Feast karty (Mrchožravý slídil, Hřbitovní hodovník) do reward poolu s placeholder artem
- [ ] C2 Balanc podle `sim_ai_matches.gd` po změnách
- [ ] C3 Po lidském testu: rozhodnout návrat malé sady čitelných Triků do rewardů (oživí Saved Tuna)

## Odloženo (vědomé rozhodnutí, D-013)
- Combat Trick window: až budou Tricky zpátky ve hře a core projde lidským testem
- Deckbuilding / shop / collection: až po stabilním a zábavném core
- Multiplayer

## Čeká na majitele
- Lidské testování (průběžně, checklisty v HANDOFF.md)
- Art pro Feast karty a Tricky/Itemy (do té doby placeholder)
- Rámy slot highlight / counter s průhledným středem (volitelné)
