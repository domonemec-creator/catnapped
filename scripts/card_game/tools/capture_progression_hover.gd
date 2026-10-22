extends SceneTree

# Screenshot Balík a postup s náhledem karty u myši (S oknem): -- "<abs cesta>.png" [card_id]

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	root.size = Vector2i(1600, 900)
	var screen = (load("res://scenes/card_game/progression_screen.tscn") as PackedScene).instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var card_id := StringName(args[1]) if args.size() > 1 else &"dockside_bruiser"
	Input.warp_mouse(Vector2(400, 500))
	await process_frame
	screen._show_hover_preview(screen._card_library.get(card_id))
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(args[0])
	print("Saved ", args[0])
	quit()
