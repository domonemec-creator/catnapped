extends SceneTree

# Obecný screenshot scény (S oknem): -- "<res://scéna.tscn>" "<abs cesta>.png"
func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("Usage: -- <scene> <output.png>")
		quit(1)
		return
	root.size = Vector2i(1600, 900)
	root.add_child((load(args[0]) as PackedScene).instantiate())
	await process_frame
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(args[1])
	print("Saved %s" % args[1])
	quit()
