extends SceneTree

# Vyrobí tematický placeholder art pro karty bez obrázku: ztmavený rub karty + zlatá ikona
# (game-icons.net, CC BY 3.0) v horní třetině, kterou hra ořezává pro náhledy.
# Headless: Godot --headless --path . --script res://scripts/card_game/tools/make_placeholder_art.gd
# Existující PNG nepřepíše (vlastní art majitele má přednost).

const BACK_PATH := "res://assets/card_game/card_art/_placeholder_back.png"
const ICON_DIR := "res://assets/card_game/icons/cards/"
const OUT_DIR := "res://assets/card_game/card_art/"
const TINT := Color(0.98, 0.82, 0.45)
# Barva ikony podle typu karty: kočka zlatá, Trick červený, Item ocelově modrý.
const TYPE_TINTS := [Color(0.98, 0.82, 0.45), Color(0.95, 0.42, 0.36), Color(0.62, 0.8, 0.98)]


func _init() -> void:
	var back := Image.load_from_file(ProjectSettings.globalize_path(BACK_PATH))
	back.convert(Image.FORMAT_RGBA8)
	var made := 0
	for file in DirAccess.get_files_at(ICON_DIR):
		if not file.ends_with(".svg"):
			continue
		var card_id := file.get_basename()
		var out_path := ProjectSettings.globalize_path(OUT_DIR + card_id + ".png")
		if FileAccess.file_exists(out_path):
			print("skip %s (art už existuje)" % card_id)
			continue
		var canvas := back.duplicate() as Image
		# Ztmavit pozadí, ať ikona vynikne.
		for y in canvas.get_height():
			for x in canvas.get_width():
				var c := canvas.get_pixel(x, y)
				canvas.set_pixel(x, y, Color(c.r * 0.42, c.g * 0.36, c.b * 0.32, 1.0))
		var svg := FileAccess.get_file_as_string(ProjectSettings.globalize_path(ICON_DIR + file))
		var tint := TINT
		var card_res_path := "res://data/cards/%s.tres" % card_id
		if ResourceLoader.exists(card_res_path):
			var definition = load(card_res_path)
			tint = TYPE_TINTS[clampi(definition.card_type, 0, 2)]
		var icon := Image.new()
		var icon_size := int(canvas.get_width() * 0.3)
		icon.load_svg_from_string(svg, float(icon_size) / 512.0)
		icon.convert(Image.FORMAT_RGBA8)
		for y in icon.get_height():
			for x in icon.get_width():
				var p := icon.get_pixel(x, y)
				icon.set_pixel(x, y, Color(tint.r * p.r, tint.g * p.g, tint.b * p.b, p.a))
		var pos := Vector2i((canvas.get_width() - icon.get_width()) / 2, int(canvas.get_height() * 0.25) - icon.get_height() / 2)
		canvas.blend_rect(icon, Rect2i(Vector2i.ZERO, icon.get_size()), pos)
		canvas.save_png(out_path)
		made += 1
		print("made %s" % card_id)
	print("Placeholder art: %s nových" % made)
	quit()
