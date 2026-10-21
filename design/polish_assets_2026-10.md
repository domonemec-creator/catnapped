# Finální polish: co je potřeba od majitele (2026-10-21)

Postup jako u nových karet: **arch 3×3**, obrázky v pořadí podle tabulky (po řádcích zleva doprava).
Rozřeže ho `slice_art_sheet.gd`. Společný styl je stejný jako v `art_prompts_2026-10.md`.
Samostatné obrázky (pozadí, logo) posílej zvlášť, protože nemají poměr 2:3.

## Priorita 1: vlastní portréty soupeřů
Teď si 3 ze 4 soupeřů půjčují obrázek karty (Lucernový útočník = Svíčkotlapý zvěd atd.).

| pořadí | id | prompt (postava) |
|---|---|---|
| 1 | `portrait_lantern_striker` | lean agile tabby duelist holding a lantern and a curved blade, confident smirk, rooftop at night |
| 2 | `portrait_ragclaw_brawler` | scarred one-eared street brawler cat with wrapped fists, torn vest, snarling grin, back alley |
| 3 | `portrait_harbor_warden` | imposing old harbor master cat in heavy coat and captain's hat, iron hook, docks and ships behind |
| 4 | `stray_token` | scrawny small stray kitten, big eyes, ragged fur, curious, cobblestone street |
| 5–9 | (rezerva pro nové soupeře / karty, viz D3) | |

## Priorita 2: samostatné obrázky
| soubor | formát | obsah |
|---|---|---|
| `logo_catnapped.png` | 1600×600, **průhledné pozadí** | nápis „Catnapped!“ ve stylu hospodské vývěsky, kočičí tlapka/ocas, zlato a tmavé dřevo |
| `board_background.png` | 1920×1080 | pohled shora na hospodský stůl: dřevo, svíčky po okrajích, střed prázdný a klidný (budou tam karty) |
| `menu_background.png` | 1920×1080 | interiér přístavní krčmy v noci, kočičí hosté v pozadí, volné místo vlevo pro menu |
| `card_back.png` | 1024×1536 | rub karty: ornament, kočičí tlapka uprostřed, zlatá a tmavě červená, symetrické |
| `app_icon.png` | 512×512 | hlava kočky s páskou přes oko, čitelná i v malé velikosti, bez textu |

## Priorita 3: kouzla a předměty (až se vrátí Tricky, C3)
13 karet má zatím zástupnou ikonu. Arch A: `catnip_burst, fish_toss, hidden_claws, sticky_paws, table_flip, gaff_hook, hunters_harness, iron_bowl, pry_bar`. Arch B: `spiked_collar, war_plate, watchmans_bell` + rezerva. Prompt = předmět nebo akce v kočičím světě, bez postavy, nebo kočka v akci.

## Co dělám já (bez assetů)
Animace karet (líznutí, smrt, zásah), sjednocení barev a rámečků, čitelnost textů, přechody, výsledková obrazovka, rozložení na menších monitorech, zvuky akcí.

## Co by pomohlo, ale není nutné
- Reference hry, jejíž vzhled se ti líbí (screenshot), kvůli směru UI.
- Hudba: teď běží volné CC0 smyčky. Vlastní hospodská hudba (2–3 smyčky po 1–2 min) by hře dodala charakter.

## Hotové prompty (Claude, 2026-10-21) — kopírovat 1:1

### Arch 1: postavy 3×3 (pořadí = id)
1 portrait_lantern_striker, 2 portrait_ragclaw_brawler, 3 portrait_harbor_warden,
4 stray_token, 5 portrait_fog_seer (budoucí soupeř 5), 6 portrait_bilge_king (budoucí soupeř 6, finální boss),
7 ship_lookout, 8 smuggler, 9 bell_ringer (nové karty pro D3).

```
A 3x3 grid of nine separate fantasy character portraits, each panel in portrait orientation 2:3, separated by thin solid black gutters, no text, no labels, no borders inside panels. Consistent style across all panels: painterly digital fantasy illustration, anthropomorphic cats, dark warm harbor tavern world, candlelight and lantern glow, deep browns and amber with muted red accents, detailed fur, dramatic rim lighting, three-quarter view, head and shoulders in the upper third of each panel, clean dark background near the head for readability.
Row 1, left: lean agile tabby duelist cat holding a brass lantern in one paw and a curved blade in the other, confident smirk, red scarf, wet rooftops at night behind.
Row 1, center: scarred one-eared street brawler cat with cloth-wrapped fists raised, torn leather vest, snarling grin, dim back alley with crates.
Row 1, right: imposing old harbor master cat, massive grey maine coon, heavy navy coat, captain's hat, iron hook hand, foggy docks and ship masts behind, stern authority, boss presence.
Row 2, left: scrawny small stray kitten, oversized curious eyes, ragged fur, sitting on wet cobblestones, soft lantern light, innocent.
Row 2, center: mysterious fog seer cat, white fur, hooded grey cloak, glowing pale blue eyes, holding tarot-like cards fanned out, swirling harbor mist, candle smoke.
Row 2, right: grotesque huge sewer king cat on a throne of crates and fish bones, crooked rusted crown, greasy fur, golden rings, sinister grin, green lantern light from below, final boss.
Row 3, left: young ship's lookout cat climbing a mast rope, spyglass raised, wind in fur, striped shirt, dusk sky with seagulls.
Row 3, center: sly smuggler cat in a dark long coat half-opened to reveal hidden bottles and fish, wide brimmed hat, side glance, lantern-lit warehouse.
Row 3, right: hunched old bell ringer cat pulling a thick rope of a bronze harbor bell, motion in the rope, deaf-looking squint, tower window with moonlight.
```

### Pozadí souboje (`board_background.png`, 1920×1080)
```
Top-down view of a large dark wooden tavern table, 16:9 widescreen, game board background. Center area is calm, evenly lit, low detail worn oak planks with subtle wood grain, no objects in the middle two thirds. Around the edges only: melted candles, a few scattered fish bones, a tankard, coins, playing cards stacked, a rolled map corner, a cat paw print in spilled ale. Warm candlelight from the edges, strong dark vignette at corners, deep browns and amber, painterly digital illustration, no text, no characters, no UI.
```

### Pozadí menu (`menu_background.png`, 1920×1080)
```
Wide interior of a cozy but shady harbor tavern at night, 16:9, painterly digital fantasy illustration. Anthropomorphic cat patrons in the background playing cards, drinking, arguing, all slightly out of focus. Hanging lanterns, ship ropes, a big window with a foggy harbor and ship masts. The left 40 percent of the image is darker and less detailed (space for menu buttons), the right side has a card table with a smug tabby cat dealer as focal point. Deep browns, amber light, muted reds, no text.
```

### Logo (`logo_catnapped.png`, 1600×600, průhledné pozadí)
```
Game logo text "Catnapped!" on a transparent background, styled like a carved and gilded wooden tavern sign, bold playful serif lettering, gold leaf with dark wood edges, a cat tail curling from the letter C, a small paw print as the dot of the exclamation mark, subtle warm glow, centered, isolated, no background scene.
```

### Rub karty (`card_back.png`, 1024×1536)
```
Ornate playing card back design, portrait 2:3, perfectly symmetrical, dark burgundy velvet background with gold filigree border, a large golden cat paw emblem in the center surrounded by a ring of small fish and anchor motifs, aged gold, subtle worn texture, flat front view, no text.
```

### Ikona hry (`app_icon.png`, 512×512)
```
Game app icon, square, bold simple shape readable at small size: head of a mischievous tabby cat with an eyepatch and a red bandana, front view, strong silhouette, warm amber background circle with dark outline, painterly but clean, high contrast, no text.
```
