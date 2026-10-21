extends SceneTree

# Screenshot tutorialu „Jak to hrát“ (S oknem), bez ohledu na save.
func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var out := OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "user://tutorial.png"
	root.size = Vector2i(1600, 900)
	var battle = (load("res://scenes/card_game/battle_scene.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await process_frame
	battle._overlay_presenter._tutorial_overlay.visible = true
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out)
	print("Saved %s" % out)
	quit()
