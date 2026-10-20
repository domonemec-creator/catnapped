extends SceneTree

# Screenshot menu a overlaye Nastavení (S oknem).
func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var out := "user://settings.png"
	if not OS.get_cmdline_user_args().is_empty():
		out = OS.get_cmdline_user_args()[0]
	root.size = Vector2i(1600, 900)
	var menu = (load("res://scenes/card_game/encounter_select.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await process_frame
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.get_basename() + "_menu.png")
	menu._open_settings()
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out)
	print("Saved %s" % out)
	quit()
