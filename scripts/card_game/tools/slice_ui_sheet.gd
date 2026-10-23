extends SceneTree

# Rozřeže arch UI assetů (rovnoměrná mřížka, zelené chroma pozadí) na průhledná PNG oříznutá na obsah.
# Spouštět headless:
#   Godot --headless --path . --script res://scripts/card_game/tools/slice_ui_sheet.gd -- <zdroj> <id1,id2,...> [sloupce] [řádky]
# Pořadí id = po řádcích zleva doprava, „-“ = políčko přeskočit. Výstup assets/card_game/ui/sheet/<id>.png.

const OUT_DIR := "res://assets/card_game/ui/sheet/"
const KEY_FULL := 0.28  # zelená převaha nad R/B, od které je pixel úplně průhledný
const KEY_EDGE := 0.06  # pod touto převahou pixel zůstává neprůhledný
const PAD := 4
const MIN_PIXELS := 40  # menší tvary = šum po kompresi
const BIG_PIXELS := 3000  # od této velikosti je tvar samostatný předmět


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
	var cols := int(args[2]) if args.size() > 2 else 4
	var rows := int(args[3]) if args.size() > 3 else 4
	var sheet := Image.load_from_file(source)
	if sheet == null or sheet.is_empty():
		push_error("Nejde načíst %s" % source)
		quit(1)
		return
	sheet.convert(Image.FORMAT_RGBA8)
	_key_green(sheet)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	# Předměty přesahují hranice políček, proto se hledají souvislé tvary a každý patří
	# do políčka, kde leží jeho těžiště (jiskry u tlapek jsou samostatné tvary téhož políčka).
	var w := sheet.get_width()
	var h := sheet.get_height()
	var cell := Vector2(float(w) / cols, float(h) / rows)
	var labels := PackedInt32Array()
	labels.resize(w * h)
	var cell_of_label := {0: -1}
	var cell_rects := {}
	var next_label := 1
	var components: Array = []
	for y in h:
		for x in w:
			var i := y * w + x
			if labels[i] != 0 or sheet.get_pixel(x, y).a < 0.5:
				continue
			var stack: Array[int] = [i]
			labels[i] = next_label
			var rect := Rect2i(x, y, 1, 1)
			var sum := Vector2.ZERO
			var count := 0
			while not stack.is_empty():
				var j: int = stack.pop_back()
				var px := j % w
				var py := j / w
				rect = rect.expand(Vector2i(px, py))
				sum += Vector2(px, py)
				count += 1
				for n in [j - 1, j + 1, j - w, j + w]:
					if n < 0 or n >= w * h or labels[n] != 0:
						continue
					if (n == j - 1 and px == 0) or (n == j + 1 and px == w - 1):
						continue
					if sheet.get_pixel(n % w, n / w).a < 0.5:
						continue
					labels[n] = next_label
					stack.append(n)
			rect.size += Vector2i.ONE
			components.append({"label": next_label, "rect": rect, "count": count, "center": sum / count})
			next_label += 1
	# Velké tvary patří do políčka podle těžiště, drobné (jiskry) k nejbližšímu velkému tvaru.
	var big: Array = components.filter(func(c): return c["count"] >= BIG_PIXELS)
	for c in components:
		var cell_index := -1
		if c["count"] >= BIG_PIXELS:
			var center: Vector2 = c["center"]
			cell_index = mini(int(center.y / cell.y), rows - 1) * cols + mini(int(center.x / cell.x), cols - 1)
		elif c["count"] >= MIN_PIXELS:
			var best := INF
			for b in big:
				var d := _rect_distance(c["rect"], b["rect"])
				if d < best:
					best = d
					var bc: Vector2 = b["center"]
					cell_index = mini(int(bc.y / cell.y), rows - 1) * cols + mini(int(bc.x / cell.x), cols - 1)
		cell_of_label[c["label"]] = cell_index
		if cell_index >= 0:
			cell_rects[cell_index] = cell_rects[cell_index].merge(c["rect"]) if cell_rects.has(cell_index) else c["rect"]
	for index in ids.size():
		if ids[index] == "-" or not cell_rects.has(index):
			continue
		var used: Rect2i = cell_rects[index].grow(PAD).intersection(Rect2i(0, 0, w, h))
		var out := Image.create(used.size.x, used.size.y, false, Image.FORMAT_RGBA8)
		for y in used.size.y:
			for x in used.size.x:
				var sx := used.position.x + x
				var sy := used.position.y + y
				var owner_cell: int = cell_of_label[labels[sy * w + sx]]
				# Cizí tvar (soused přesahující sem) vynechat; měkký okraj (label 0) bereme.
				if labels[sy * w + sx] != 0 and owner_cell != index:
					continue
				out.set_pixel(x, y, sheet.get_pixel(sx, sy))
		var path := OUT_DIR + ids[index] + ".png"
		out.save_png(ProjectSettings.globalize_path(path))
		print("Uloženo %s %s" % [path, out.get_size()])
	quit()


func _rect_distance(a: Rect2i, b: Rect2i) -> float:
	var dx := maxi(0, maxi(b.position.x - a.end.x, a.position.x - b.end.x))
	var dy := maxi(0, maxi(b.position.y - a.end.y, a.position.y - b.end.y))
	return Vector2(dx, dy).length()


# Zelené pozadí → průhlednost s měkkou hranou; ze zbylých okrajů se zelená odsaje (despill).
func _key_green(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			var dominance := c.g - maxf(c.r, c.b)
			if dominance <= KEY_EDGE:
				continue
			var alpha := 1.0 - clampf((dominance - KEY_EDGE) / (KEY_FULL - KEY_EDGE), 0.0, 1.0)
			if alpha <= 0.0:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			c.g = maxf(c.r, c.b)
			c.a = alpha
			image.set_pixel(x, y, c)
