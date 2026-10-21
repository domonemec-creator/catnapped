extends SceneTree

# Rozřeže arch s ilustracemi (mřížka 3×3, tmavé linky mezi políčky) na jednotlivé karty.
# Spouštět headless:
#   Godot --headless --path . --script res://scripts/card_game/tools/slice_art_sheet.gd -- <zdroj> <id1,id2,...> [sloupce] [řádky]
# Pořadí id = po řádcích zleva doprava. Výstup přepíše assets/card_game/card_art/<id>.png.

const OUT_DIR := "res://assets/card_game/card_art/"
const OUT_SIZE := Vector2i(1024, 1536)
const GUTTER_SEARCH := 0.08  # jak daleko (podíl rozměru) od teoretické hranice hledat tmavou linku
const INSET := 3  # px uvnitř políčka, ať nezůstane tmavý okraj


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("Použití: -- <zdroj> <id1,id2,...> [sloupce] [řádky]")
		quit(1)
		return
	var source := args[0]
	if source.begins_with("res://"):
		source = ProjectSettings.globalize_path(source)
	var ids := args[1].split(",", false)
	var cols := int(args[2]) if args.size() > 2 else 3
	var rows := int(args[3]) if args.size() > 3 else 3
	var sheet := Image.load_from_file(source)
	if sheet == null or sheet.is_empty():
		push_error("Nejde načíst %s" % source)
		quit(1)
		return
	sheet.convert(Image.FORMAT_RGB8)
	var xs := _find_cuts(sheet, cols, true)
	var ys := _find_cuts(sheet, rows, false)
	print("řezy x=%s y=%s" % [xs, ys])
	for i in mini(ids.size(), cols * rows):
		var cx := i % cols
		var cy := i / cols
		var rect := Rect2i(xs[cx] + INSET, ys[cy] + INSET, xs[cx + 1] - xs[cx] - INSET * 2, ys[cy + 1] - ys[cy] - INSET * 2)
		var tile := sheet.get_region(_fit_aspect(_trim_dark_edges(sheet, rect)))
		tile.resize(OUT_SIZE.x, OUT_SIZE.y, Image.INTERPOLATE_LANCZOS)
		var out_path := ProjectSettings.globalize_path(OUT_DIR + ids[i].strip_edges() + ".png")
		if tile.save_png(out_path) != OK:
			push_error("Uložení selhalo: %s" % out_path)
			quit(1)
			return
		print("ok %s %s" % [ids[i], rect])
	quit()


# Hranice políček: kolem každé teoretické hranice najde nejtmavší sloupec/řádek.
func _find_cuts(img: Image, parts: int, vertical: bool) -> Array[int]:
	var length := img.get_width() if vertical else img.get_height()
	var cuts: Array[int] = [0]
	for k in range(1, parts):
		var center := length * k / parts
		var radius := int(length * GUTTER_SEARCH)
		var best := center
		var best_value := INF
		for p in range(center - radius, center + radius):
			var value := _line_brightness(img, p, vertical)
			if value < best_value:
				best_value = value
				best = p
		cuts.append(best)
	cuts.append(length)
	return cuts


func _line_brightness(img: Image, pos: int, vertical: bool) -> float:
	var total := 0.0
	var count := img.get_height() if vertical else img.get_width()
	for i in range(0, count, 4):
		var c := img.get_pixel(pos, i) if vertical else img.get_pixel(i, pos)
		total += c.get_luminance()
	return total


# Odřízne tmavý rámeček / širší linky po okrajích políčka (arch může mít vnější rám).
func _trim_dark_edges(img: Image, rect: Rect2i) -> Rect2i:
	var r := rect
	var limit := int(mini(rect.size.x, rect.size.y) * 0.06)
	for _i in limit:
		if _edge_dark(img, Rect2i(r.position.x, r.position.y, 1, r.size.y)):
			r = Rect2i(r.position.x + 1, r.position.y, r.size.x - 1, r.size.y)
		if _edge_dark(img, Rect2i(r.end.x - 1, r.position.y, 1, r.size.y)):
			r.size.x -= 1
		if _edge_dark(img, Rect2i(r.position.x, r.position.y, r.size.x, 1)):
			r = Rect2i(r.position.x, r.position.y + 1, r.size.x, r.size.y - 1)
		if _edge_dark(img, Rect2i(r.position.x, r.end.y - 1, r.size.x, 1)):
			r.size.y -= 1
	return r


func _edge_dark(img: Image, line: Rect2i) -> bool:
	var total := 0.0
	var count := 0
	for y in range(line.position.y, line.end.y, 3):
		for x in range(line.position.x, line.end.x, 3):
			total += img.get_pixel(x, y).get_luminance()
			count += 1
	return count > 0 and total / count < 0.06


# Ořízne políčko na poměr 2:3 (na střed), ať se karta nedeformuje.
func _fit_aspect(rect: Rect2i) -> Rect2i:
	var target := float(OUT_SIZE.x) / OUT_SIZE.y
	var current := float(rect.size.x) / rect.size.y
	if current > target:
		var w := int(rect.size.y * target)
		return Rect2i(rect.position.x + (rect.size.x - w) / 2, rect.position.y, w, rect.size.y)
	var h := int(rect.size.x / target)
	return Rect2i(rect.position.x, rect.position.y + (rect.size.y - h) / 2, rect.size.x, h)
