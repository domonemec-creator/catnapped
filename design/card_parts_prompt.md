# Prompt: díly karet (držáky čísel + rámy) – 2026-10-23

Dva obrázky, oba se zeleným pozadím (#00FF00) jako minule. Rozřežu je stejným nástrojem (`slice_ui_sheet.gd`).
Karty teď mají obrázek přes celou plochu a čísla v obyčejných barevných kolečkách. Nové díly nahradí kolečka a dají každému typu karty vlastní rám.

## Arch 1: držáky čísel a pásky (mřížka 4×2 = 8 kusů)

```
A game UI asset sheet, 4x2 grid of 8 separate items, each item centered in its own equal cell with generous empty margin, nothing touching or overlapping cell borders. Background of the whole image is a flat solid pure chroma green (#00FF00), no gradient, no texture, no shadows on the background, no grid lines.

Style: painterly hand-painted fantasy game UI for a cozy-dark pirate harbor tavern card game about cats. Aged brass and gold trim, enamel colors, warm candlelight from top-left, subtle wear, clean readable silhouettes, flat front view. Absolutely no text, no letters, no numbers anywhere: every holder has an EMPTY smooth center where a number will be placed later.

Row 1:
1. Mana cost holder: round deep-blue enamel medallion with a brass rim and a tiny tuna fish engraved on the rim, empty smooth center.
2. Attack holder: round amber-orange enamel medallion with brass rim and three small claw marks engraved on the rim, empty smooth center.
3. Health holder: deep-red enamel heart-shaped medallion with brass rim, empty smooth center.
4. Armor/shield-style holder: steel-grey enamel shield medallion with brass rim, empty smooth center (for special stats).

Row 2:
5. Card name banner: wide horizontal dark red cloth ribbon with brass end caps, empty, flat.
6. Keyword tag: small rounded dark-blue enamel plate with thin brass border, wide and short, empty.
7. Small brass cat-paw badge (marks a cat that is ready to attack).
8. Small cracked red damage splash burst, empty center (shows damage taken).
```

## Arch 2: rámy karet (3 vedle sebe, mřížka 3×1)

```
A game card frame asset sheet, 3 card frames side by side in a 3x1 grid, each frame centered in its own equal cell with empty margin. Each frame is a tall portrait card, aspect ratio 2:3, flat front view. Background of the whole image AND the inside window of every frame is flat solid pure chroma green (#00FF00), so the artwork can show through later. No text, no letters, no numbers.

Style: painterly hand-painted fantasy card game frames for a cozy-dark pirate harbor tavern card game about cats, matching aged brass, dark stained wood and deep red cloth. Frames are THIN (border about 4-5% of card width) so the illustration fills almost the whole card. Small empty round notch in the top-left corner for the cost medallion and small empty notches in the bottom-left and bottom-right corners for attack and health.

1. CAT card frame: warm brass and dark wood border, small cat-head crest at the top center.
2. TRICK card frame: same shape, border in deep purple enamel with brass, small swirling smoke ornament at the top center.
3. ITEM card frame: same shape, border in blackened iron with brass rivets, small crossed tools (hook and wrench) ornament at the top center.
```

## Kontrola, než mi to pošleš
- Žádná čísla ani text v držácích (čísla píše hra sama).
- Vnitřek rámů musí být zelený, ne bílý ani šachovnice, jinak ho nevyklíčuju.
- Rámy tenké a čelně, všechny tři stejného tvaru.

Ulož je kamkoli a napiš mi cesty k souborům.
