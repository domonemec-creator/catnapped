# Prompt: arch UI assetů (menu, tlačítka, ikony) – 2026-10-23

Jeden obrázek, mřížka 4×4 = 16 assetů. Pozadí čistě zelené (chroma key), abych ho mohl vyklíčovat na průhlednost.
Rozřežu po rovnoměrné mřížce, takže **políčka musí být stejně velká a předměty uprostřed s odstupem od okraje**.
Ideálně čtvercový obrázek 2048×2048 (nebo co nejvyšší rozlišení).

## Prompt (anglicky – generátory mu rozumí líp)

```
A game UI asset sheet, 4x4 grid of 16 separate items, each item centered in its own equal square cell with generous empty margin, nothing touching or overlapping cell borders. Background of the whole image is a flat solid pure chroma green (#00FF00), no gradient, no texture, no shadows cast on the background, no grid lines.

Style: painterly hand-painted fantasy illustration matching a cozy-dark pirate harbor tavern card game about cats. Warm candlelight, aged brass and gold trim, dark stained wood, deep red cloth accents, subtle wear. Consistent lighting from top-left. Clean readable silhouettes. Absolutely no text, no letters, no numbers anywhere.

Row 1:
1. Empty ornate title plaque for a game logo: wide horizontal dark wooden board with brass frame, small cat-paw crest on top, red cloth drapes on the sides. Center left empty.
2. Empty wide button: dark polished wood plate with thin brass border and small rivets, rounded corners, flat front view, center empty.
3. Same wide button but glowing warm gold (highlighted/hover state), center empty.
4. Empty round brass medallion button, dark wood center, front view.

Row 2:
5. Empty rectangular panel frame: brass-trimmed dark wood border with ornate corners, flat front view, center filled with plain very dark brown, evenly thick border on all four sides (usable for 9-slice).
6. Horizontal decorative divider: thin brass line with a small cat-paw ornament in the middle.
7. Red heart icon with brass rim (player life).
8. Tuna fish icon: shiny blue-silver tuna fish, slightly stylized (energy resource).

Row 3:
9. Gold fish-scale coin icon (currency), embossed fish scale pattern.
10. Stack of face-down playing cards with ornate red-and-gold backs (deck icon).
11. Small pile of torn discarded cards (discard pile icon).
12. Brass ship's wheel icon (settings).

Row 4:
13. Two cat paws doing a high-five (two-player mode icon).
14. Wooden training dummy with scratch marks (training mode icon).
15. Old rolled treasure map with a dotted route and a red X (expedition mode icon).
16. Brass padlock with a cat-paw engraving (locked icon).
```

## Kdyby generátor 16 položek nezvládl
Rozděl na dva archy po 8 (mřížka 4×2): řádky 1–2 v jednom, 3–4 ve druhém. Zbytek promptu stejný, jen změň „4x4 grid of 16“ na „4x2 grid of 8“.

## Kontrola, než mi to pošleš
- Žádný text ani písmena (logo „Catnapped!“ píšu fontem já).
- Pozadí jednolitě zelené, předměty nezasahují do sousedních políček.
- Tlačítka a rám čelně (ne v perspektivě), jinak nepůjdou natáhnout.

Ulož ho kamkoli a napiš mi cestu k souboru. Rozřežu to a nasadím do menu, tlačítek, Balík a postup a ikon v souboji.
