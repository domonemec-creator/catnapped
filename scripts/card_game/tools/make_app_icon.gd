extends SceneTree

# Vyřízne čtvercovou ikonu hry z portrétu (hlava kočky) a uloží icon.png (256 px).
#   Godot --headless --path . --script res://scripts/card_game/tools/make_app_icon.gd -- <portrét> <x> <y> <strana>

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var source := ProjectSettings.globalize_path(args[0])
	var img := Image.load_from_file(source)
	img.convert(Image.FORMAT_RGBA8)
	var crop := img.get_region(Rect2i(int(args[1]), int(args[2]), int(args[3]), int(args[3])))
	crop.resize(256, 256, Image.INTERPOLATE_LANCZOS)
	crop.save_png(ProjectSettings.globalize_path("res://icon.png"))
	print("icon.png uložen")
	quit()
