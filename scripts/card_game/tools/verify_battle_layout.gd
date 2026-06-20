extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _run() -> void:
	root.size = Vector2i(1600, 900)

	var packed_scene := load("res://scenes/card_game/battle_scene.tscn") as PackedScene
	if packed_scene == null:
		_fail("Could not load battle_scene.tscn.")
		return

	var battle = packed_scene.instantiate()
	root.add_child(battle)

	await process_frame
	await process_frame

	if battle.hand_row.get_child_count() <= 0:
		_fail("Hand row did not create any visible card views.")
		return

	var hand_panel = battle.get_node("Margin/Layout/BottomBar/HandPanel") as Control
	if hand_panel == null:
		_fail("Could not locate HandPanel.")
		return

	var hand_panel_rect := hand_panel.get_global_rect()
	var hand_panel_bottom := hand_panel_rect.position.y + hand_panel_rect.size.y
	if hand_panel_bottom > root.size.y - 8:
		_fail("Hand panel is pushed below the viewport.")
		return

	var first_card = battle.hand_row.get_child(0) as Control
	if first_card == null:
		_fail("Hand row did not expose the first card control.")
		return

	var first_card_rect := first_card.get_global_rect()
	var first_card_bottom := first_card_rect.position.y + first_card_rect.size.y
	if first_card_bottom > root.size.y - 8:
		_fail("First hand card is pushed below the viewport.")
		return

	print("Battle layout verification passed.")
	quit()
