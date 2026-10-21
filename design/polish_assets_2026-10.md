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
