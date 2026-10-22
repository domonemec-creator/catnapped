extends SceneTree

# Přeskládá obrázek stolu shora (6 vyrytých míst 3×2) tak, aby místa padla přesně na políčka v souboji.
# Změří políčka v battle_scene a obrázek po pásech přeškáluje (vodorovná prkna snesou zúžení mezer).
# Spouštět headless:
#   Godot --headless --path . --script res://scripts/card_game/tools/build_board_texture.gd -- <zdroj> [x0,x1,...,x5] [y0,...,y3]
# x = levé/pravé hrany tří míst ve zdroji, y = horní/dolní hrany dvou řad (px zdroje).

const OUT_PATH := "res://assets/card_game/ui/board_topdown.png"
const OUT_SCALE := 2.0  # výstup ve 2× rozlišení panelu (ostrost na velkých monitorech)
const BOARD_PATH := "Margin/Layout/TopRow/BoardColumn/BoardPanel"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Použití: -- <zdroj> [x0..x5] [y0..y3]")
		quit(1)
		return
	var source := Image.load_from_file(args[0])
	if source == null or source.is_empty():
		push_error("Nejde načíst %s" % args[0])
		quit(1)
		return
	source.convert(Image.FORMAT_RGB8)
	var src_x: Array = _parse(args[1]) if args.size() > 1 else [300.0, 562.0, 703.0, 965.0, 1105.0, 1367.0]
	var src_y: Array = _parse(args[2]) if args.size() > 2 else [75.0, 433.0, 488.0, 851.0]

	var battle = (load("res://scenes/card_game/battle_scene.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	for i in 4:
		await process_frame
	var panel := battle.get_node(BOARD_PATH) as Control
	var origin := panel.global_position
	var size := panel.size
	var tx: Array[float] = []
	for lane in battle._player_lanes:
		var rect: Rect2 = lane.empty_frame.get_global_rect()
		tx.append(rect.position.x - origin.x)
		tx.append(rect.end.x - origin.x)
	var enemy_rect: Rect2 = battle._enemy_lanes[0].empty_frame.get_global_rect()
	var player_rect: Rect2 = battle._player_lanes[0].empty_frame.get_global_rect()
	var ty: Array = [enemy_rect.position.y - origin.y, enemy_rect.end.y - origin.y, player_rect.position.y - origin.y, player_rect.end.y - origin.y]
	print("panel %s, místa x=%s y=%s" % [size, tx, ty])

	# Okraje mimo místa: stejné měřítko jako místa, ať se roh stolu nedeformuje.
	var sx: float = (tx[1] - tx[0]) / (src_x[1] - src_x[0])
	var sy: float = (ty[1] - ty[0]) / (src_y[1] - src_y[0])
	var bx: Array = [maxf(0.0, src_x[0] - tx[0] / sx)] + src_x + [minf(source.get_width(), src_x[5] + (size.x - tx[5]) / sx)]
	var by: Array = [maxf(0.0, src_y[0] - ty[0] / sy)] + src_y + [minf(source.get_height(), src_y[3] + (size.y - ty[3]) / sy)]
	var ox: Array = [0.0] + tx + [size.x]
	var oy: Array = [0.0] + ty + [size.y]
	print("měřítko míst x=%.3f y=%.3f (deformace %.0f %%)" % [sx, sy, absf(sx / sy - 1.0) * 100.0])

	# Vodorovně: každý pás zdroje (plná výška) na cílovou šířku.
	var out_w := int(size.x * OUT_SCALE)
	var out_h := int(size.y * OUT_SCALE)
	var mid := Image.create(out_w, source.get_height(), false, Image.FORMAT_RGB8)
	for i in bx.size() - 1:
		var x0: int = int(round(ox[i] * OUT_SCALE))
		var x1: int = int(round(ox[i + 1] * OUT_SCALE))
		var piece := source.get_region(Rect2i(int(bx[i]), 0, maxi(1, int(bx[i + 1] - bx[i])), source.get_height()))
		piece.resize(maxi(1, x1 - x0), source.get_height(), Image.INTERPOLATE_LANCZOS)
		mid.blit_rect(piece, Rect2i(Vector2i.ZERO, piece.get_size()), Vector2i(x0, 0))
	# Svisle: totéž po řádcích.
	var out := Image.create(out_w, out_h, false, Image.FORMAT_RGB8)
	for i in by.size() - 1:
		var y0: int = int(round(oy[i] * OUT_SCALE))
		var y1: int = int(round(oy[i + 1] * OUT_SCALE))
		var piece := mid.get_region(Rect2i(0, int(by[i]), out_w, maxi(1, int(by[i + 1] - by[i]))))
		piece.resize(out_w, maxi(1, y1 - y0), Image.INTERPOLATE_LANCZOS)
		out.blit_rect(piece, Rect2i(Vector2i.ZERO, piece.get_size()), Vector2i(0, y0))
	if out.save_png(ProjectSettings.globalize_path(OUT_PATH)) != OK:
		push_error("Uložení selhalo")
		quit(1)
		return
	print("ok %s %s" % [OUT_PATH, out.get_size()])
	quit()


func _parse(text: String) -> Array:
	var values: Array = []
	for part in text.split(","):
		values.append(float(part))
	return values
