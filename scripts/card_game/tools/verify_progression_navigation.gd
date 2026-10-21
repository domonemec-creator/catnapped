extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _run() -> void:
	var encounter_scene := load("res://scenes/card_game/encounter_select.tscn") as PackedScene
	if encounter_scene == null:
		_fail("Could not load encounter_select.tscn.")
		return

	var menu := encounter_scene.instantiate()
	root.add_child(menu)
	current_scene = menu

	await process_frame
	await process_frame

	if not (current_scene is EncounterSelectMenu):
		_fail("Encounter select did not become the current scene.")
		return

	menu._progress_button.emit_signal("pressed")

	await process_frame
	await process_frame

	var progression := current_scene
	if progression == null or not (progression is ProgressionScreenMenu):
		_fail("Progression screen did not replace the encounter selector.")
		return

	if progression._back_button == null:
		_fail("Progression screen did not expose the back button.")
		return

	progression._back_button.emit_signal("pressed")

	await process_frame
	await process_frame

	if current_scene == null or not (current_scene is EncounterSelectMenu):
		_fail("Progression screen did not return to encounter select.")
		return
	if current_scene._encounters.size() != ProgressionSystem.TRAINING_ORDER.size():
		_fail("Encounter select did not reload its encounter roster after returning from progression.")
		return
	if current_scene._selected_encounter == null or current_scene._selected_encounter.id != &"smug_tabby":
		_fail("Encounter select did not restore its default selection after returning from progression.")
		return

	print("Progression navigation verification passed.")
	quit()
