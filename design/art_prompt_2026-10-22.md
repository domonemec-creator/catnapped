# Prompty na ilustrace (Claude, noc 21.→22. 10. 2026)

Jak minule: **jeden obrázek = arch 3×3**, políčka na výšku 2:3, tenké černé linky mezi nimi, bez textu.
Pořadí políček = po řádcích zleva doprava = pořadí id v tabulce. Arch rozřežu `slice_art_sheet.gd`.
Všechny karty z archů A–C už ve hře jsou, zatím s půjčeným obrázkem. Po nahrání se jen vymění art.

Stav 2026-10-22: **A a B hotové a ve hře**, zbývá **C**.

## Arch A: 9 nových karet (D3)

| # | id | karta | co je na obrázku |
|---|---|---|---|
| 1 | `harbor_kitten` | Kotě na hlídce (1, 1/2, Ochrana) | malé kotě s příliš velkou helmicí z plechového hrnku, drží dřevěný meč, stojí na stráži u sudu |
| 2 | `bait_fisher` | Rybářka s návnadou (2, 2/1, Poslední dech: 1 zranění soupeři) | hubená kočka-rybářka s prutem, na háčku se třpytí návnada, mokrá mola |
| 3 | `rat_hunter` | Lovec potkanů (3, 2/2, Bojový nástup: 2 zranění kočce naproti) | šlachovitý kocour s vrhacími noži a pytlem, číhá ve sklepě mezi sudy |
| 4 | `rope_acrobat` | Lanový akrobat (3, 3/2, Rychlé tlapy, Výpad) | mrštná kočka v letu na laně mezi stěžni, šavle v zubech |
| 5 | `helmsman` | Kormidelník (5, 3/5, Ochrana, sousedé +1 život) | statný starý námořní kocour u velkého kormidla, kabát, dýmka, bouře za ním |
| 6 | `dock_breaker` | Lamač z doků (5, 5/4, Výpad) | obrovský svalnatý kocour s řetězem kolem tlapy, rozráží bednu, třísky létají |
| 7 | `warm_milk` | Teplé mléko (kouzlo: +3 životy) | kouřící hrnek mléka na hospodském stole, kočičí tlapka po něm sahá, útulné světlo |
| 8 | `overboard` | Přes palubu! (kouzlo: vrátí kočku do ruky) | kočka letí přes zábradlí lodi do vln, překvapený výraz, šplouchnutí |
| 9 | `rusty_anchor` | Rezavá kotva (předmět: +1 útok, +2 životy) | rezavá kotva s řetězem opřená o bednu, přivázaná kočičí stužka, lucerna |

```
A 3x3 grid of nine separate fantasy card illustrations, each panel in portrait orientation 2:3, separated by thin solid black gutters, no text, no labels, no borders inside panels. Consistent style across all panels: painterly digital fantasy illustration, anthropomorphic cats, dark warm harbor tavern world, candlelight and lantern glow, deep browns and amber with muted red accents, detailed fur, dramatic rim lighting. Characters in three-quarter view with the head in the upper third of the panel. Object panels show the object large and centered.
Row 1, left: tiny brave kitten guard wearing an oversized tin cup as a helmet, holding a small wooden sword, standing watch beside a barrel, determined big eyes.
Row 1, center: thin cat fisherwoman holding a fishing rod, a glittering lure on the hook, wet wooden pier at night, lanterns reflecting in water.
Row 1, right: wiry rat hunter cat with throwing knives on a bandolier and a sack, crouching in a cellar between barrels, sharp focused eyes.
Row 2, left: agile acrobat cat swinging on a rope between ship masts, cutlass in its teeth, dynamic mid-air pose, night sky.
Row 2, center: sturdy old sailor cat at a big wooden ship wheel, heavy coat, smoking pipe, storm clouds and waves behind, calm protective look.
Row 2, right: huge muscular dock brawler cat smashing through a wooden crate, chain wrapped around one paw, splinters flying, warehouse.
Row 3, left: steaming mug of warm milk on a tavern table, a cat paw reaching for it, cozy warm candlelight, no full character.
Row 3, center: surprised cat being thrown over the railing of a ship into stormy waves, big splash, comedic and dramatic.
Row 3, right: rusty ship anchor with a heavy chain leaning on a crate, a red ribbon with a small cat paw charm tied to it, lantern light, no character.
```

## Arch B: kouzla a předměty (teď jen ikona na rubu karty)

| # | id | karta | co je na obrázku |
|---|---|---|---|
| 1 | `catnip_burst` | Kočičí máta (+2 útok do konce kola) | kočka ve víru zelených lístků máty, rozšířené zornice, euforie |
| 2 | `fish_toss` | Hod rybou (kočka útočí znovu) | ryba letí vzduchem, kočka po ní skáče |
| 3 | `hidden_claws` | Skryté drápy (2 zranění) | detail tlapky, z níž vyjíždějí ostré drápy, záblesk |
| 4 | `sticky_paws` | Lepkavé tlapky (ukradne předmět) | kočičí zloděj sahá po cizím obojku, stín, plíživě |
| 5 | `table_flip` | Převrácení stolu (vrátí levnou kočku) | kočka převrací hospodský stůl, karty a korbely létají |
| 6 | `gaff_hook` | Lodní hák (4 zranění) | velký lodní hák se zasekává do dřeva, jiskry |
| 7 | `hunters_harness` | Lovecký postroj (získá Výpad) | kožený lovecký postroj s přezkami na kočce, připravená ke skoku |
| 8 | `iron_bowl` | Železná miska (+2 životy) | železná miska použitá jako štít, promáčklá |
| 9 | `pry_bar` | Páčidlo (zničí předmět) | páčidlo vypáčí zámek truhly, kousky železa |

```
A 3x3 grid of nine separate fantasy card illustrations for spells and items, each panel in portrait orientation 2:3, separated by thin solid black gutters, no text, no labels. Same consistent style: painterly digital fantasy illustration, anthropomorphic cats, dark warm harbor tavern world, candlelight, deep browns and amber with muted red accents. Each panel shows one clear action or object, large and centered, readable at small size.
Row 1, left: a cat surrounded by a swirling burst of green catnip leaves, wide pupils, euphoric energy glow.
Row 1, center: a fish flying through the air across a tavern, a cat leaping after it with claws out.
Row 1, right: close-up of a cat paw with sharp claws extending, a bright slash of light.
Row 2, left: sneaky thief cat reaching for another cat's studded collar from the shadows.
Row 2, center: a cat flipping a tavern table, cards, coins and tankards flying in the air.
Row 2, right: a large iron ship gaff hook biting into a wooden beam, sparks.
Row 3, left: a leather hunting harness with brass buckles worn by a crouching cat ready to pounce.
Row 3, center: a dented iron food bowl held up like a shield by a cat paw, arrow bouncing off.
Row 3, right: a crowbar prying open the lock of a treasure chest, broken metal pieces flying.
```

## Arch C: zbytek předmětů, Vyhazovač, soupeř ve hře ve dvou a 4 nové karty

| # | id | karta | co je na obrázku |
|---|---|---|---|
| 1 | `spiked_collar` | Ostnatý obojek (+1 útok) | kožený obojek s kovovými ostny na tmavém sametu |
| 2 | `war_plate` | Válečný plát (+2 útok) | kus pancíře s vyrytou tlapkou, bojové škrábance |
| 3 | `watchmans_bell` | Hlídačův zvonec (Ochrana) | mosazný zvonec na stužce, zvoní, světlo lucerny |
| 4 | `tavern_bouncer` | Vyhazovač (6, 6/6, Ochrana) | obří kocour vyhazovač u dveří krčmy, zkřížené tlapy |
| 5 | `portrait_rival` | soupeř ve hře ve dvou | sebevědomý kocour hráč karet s kartou v tlapě, napůl ve stínu, „tvůj protivník“ |
| 6 | `harbor_courier` | Přístavní poslíček (4, 2/3) | rychlý poslíček s brašnou dopisů běží po mole |
| 7 | `net_mender` | Spravovačka sítí (2, 1/3, sousedé +1 útok) | starší kočka spravuje rybářskou síť, jehla a nit |
| 8 | `cannon_cat` | Dělová kočka (6, 4/5, 3 zranění naproti) | kocour dělostřelec u lodního děla, kouř, zapálená doutnák |
| 9 | `fish_market` | Rybí trh (kouzlo: lízni 2) | rušný rybí trh, stánky, kočky smlouvají, ryby na ledu |

```
A 3x3 grid of nine separate fantasy card illustrations, each panel in portrait orientation 2:3, separated by thin solid black gutters, no text, no labels. Same consistent style: painterly digital fantasy illustration, anthropomorphic cats, dark warm harbor tavern world, candlelight and lantern glow, deep browns and amber with muted red accents, detailed fur. Characters in three-quarter view with the head in the upper third.
Row 1, left: a leather cat collar with metal spikes lying on dark velvet, object only.
Row 1, center: a piece of battle armor plate engraved with a cat paw symbol, scratched from combat, object only.
Row 1, right: a brass bell on a ribbon ringing, motion lines, lantern light, object only.
Row 2, left: giant bouncer cat standing at a tavern door with crossed arms, scarred, intimidating, warm light from inside.
Row 2, center: confident rival card player cat holding one card up, half in shadow, smug challenging look, tavern table in front, portrait for an opponent.
Row 2, right: fast courier cat running along a pier with a satchel full of letters, papers flying.
Row 3, left: older cat mending a fishing net with a needle and twine, calm focused, nets hanging around.
Row 3, center: cat gunner beside a ship cannon, lit fuse, smoke and sparks, determined.
Row 3, right: busy fish market at night, stalls with fish on ice, cats haggling, lanterns.
```

## Hrací plocha shora (`board_topdown.png`, 1600×900, nahradí `board_frame_transparent.png`)
Starý stůl je v perspektivě, karty jsou rovné → nelícovaly. Potřeba přesně shora, bez perspektivy. Šest míst = 3 sloupce × 2 řady (horní řada soupeř, dolní hráč), mezi řadami tenký pruh.

```
Top-down orthographic view of a wooden tavern game table surface, perfectly flat, no perspective, no tilt, seen straight from above, filling the whole 16:9 frame. Dark worn oak planks with brass corner fittings. Six shallow rectangular card spots carved into the wood in a 3 columns x 2 rows grid, each spot portrait 2:3, evenly spaced, centered, all exactly the same size, with a thin brass inlay border. A thin carved divider line between the top row and the bottom row. Subtle paw print engraved in the center of each spot, very faint. Warm candlelight from above, soft vignette at the edges. Painterly digital fantasy style, deep browns and amber, muted red accents. No cards, no objects, no text, no characters.
```

## Co dál (není nutné hned)
- Pozadí souboje a menu (1920×1080) a logo: prompty v `design/polish_assets_2026-10.md`, platí dál.
- Vlastní hudba do krčmy (2–3 smyčky).
