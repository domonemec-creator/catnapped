# Art prompty pro nové karty (2026-10-20)

Karty už jsou ve hře s dočasným artem: ztmavený rub karty + zlatá tematická ikona (game-icons.net, CC BY 3.0), generuje `scripts/card_game/tools/make_placeholder_art.gd`. Vlastní obrázek prostě **přepíše** placeholder se stejným názvem. Hotový obrázek ulož do
`assets/card_game/card_art/<id>.png` (název přesně podle id). Godot ho při dalším spuštění naimportuje
a karta ho začne používat sama, bez úprav kódu.

**Formát:** 1024×1536 (na výšku, 2:3), PNG, bez rámu a textu. Hlava kočky v horní třetině obrázku,
protože hra pro malé náhledy ořezává horní pás (4–46 % výšky).

**Společný styl (přidej ke každému promptu):**
> painterly digital fantasy illustration, anthropomorphic cat character, dark warm tavern and harbor
> atmosphere, candlelight and lantern glow, deep browns and amber with muted red accents, detailed fur,
> dramatic rim lighting, three-quarter view, head and upper body in the upper third of the frame,
> no text, no frame, no border, portrait orientation 2:3

| id | Název | Prompt (postava) |
|---|---|---|
| `lamplighter` | Lampářka | slender tabby she-cat lamplighter holding a long brass lighting pole with a small flame, soot-smudged apron, mischievous eyes, harbor street lanterns behind |
| `dock_harpooner` | Harpunář | grizzled grey harbor cat aiming a heavy iron harpoon, oilskin coat, rope coiled over shoulder, misty dock and ship hulls behind |
| `pickpocket` | Kapsář | small sly black kitten pickpocket in a too-big hood, holding a stolen coin pouch, crouching in a tavern corner, grin, coins glinting |
| `stray_mother` | Toulavá máma | tough calico mother cat in a patched shawl, two tiny kittens peeking from behind her legs, protective stance, alley with crates |
| `galley_cook` | Kuchař z podpalubí | stout ginger ship's cook cat with ladle and steaming pot, stained apron, ship galley interior, warm steam |
| `harbor_drummer` | Přístavní bubeník | muscular brown tabby beating a large war drum with bone sticks, sailor tattoos, rallying shout, ship deck at dusk |
| `grey_veteran` | Šedivý veterán | old scarred grey maine-coon veteran in battered plate armor and a round shield, one eye scarred shut, calm and immovable |
| `carrion_prowler` | Mrchožravý slídil | gaunt dark-furred scavenger cat with glowing yellow eyes, tattered cloak, gnawing a fish bone, back-alley shadows |
| `graveyard_glutton` | Hřbitovní hodovník | huge fat black cat feasting at a candlelit table among tombstones, napkin tucked in collar, greedy grin |

Zbývající karty bez artu (Tricky a Itemy) se ve výchozí hře zatím nepoužívají (D-011, D-013), proto mají nižší prioritu.
