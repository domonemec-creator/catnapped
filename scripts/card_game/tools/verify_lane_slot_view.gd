extends SceneTree


const CardInstance = preload("res://scripts/card_game/runtime/card_instance.gd")
const CardDefinition = preload("res://scripts/card_game/data/card_definition.gd")


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_card(card_id: StringName, owner_id: int, current_life: int = -1, can_attack: bool = false, has_attacked: bool = false) -> CardInstance:
	var definition := load("res://data/cards/%s.tres" % String(card_id)) as CardDefinition
	if definition == null:
		return null

	var instance := CardInstance.new()
	instance.definition = definition
	instance.owner_id = owner_id
	instance.current_attack = definition.attack
	instance.current_life = definition.life if current_life < 0 else current_life
	instance.can_attack = can_attack
	instance.has_attacked = has_attacked
	return instance


func _run() -> void:
	var packed_scene := load("res://scenes/card_game/lane_slot_view.tscn") as PackedScene
	if packed_scene == null:
		_fail("Could not load lane_slot_view.tscn.")
		return

	var slot := packed_scene.instantiate() as LaneSlotView
	root.add_child(slot)

	await process_frame
	await process_frame

	slot.configure(1, LaneSlotView.OWNER_PLAYER, "Ty 2", "Vyloz kocku")

	if slot.card_preview.get_display_mode() != &"board":
		_fail("Lane slot did not switch its card preview to board mode.")
		return
	if not slot.empty_frame.visible:
		_fail("Empty lane should show the board placeholder frame.")
		return
	if slot.card_preview.visible:
		_fail("Empty lane should not show a card preview.")
		return
	if slot.empty_label.text != "VYLOZ KOCKU":
		_fail("Player lane did not expose the expected empty slot label.")
		return

	var wounded_card := _make_card(&"alley_scrapper", LaneSlotView.OWNER_PLAYER, 1, true, false)
	if wounded_card == null:
		_fail("Could not create wounded test card.")
		return

	slot.set_card_instance(wounded_card)

	if not slot.card_preview.visible:
		_fail("Occupied lane should show the compact card preview.")
		return
	if slot.empty_frame.visible:
		_fail("Occupied lane should hide the empty slot frame.")
		return
	if not slot.name_ribbon.visible:
		_fail("Occupied lane should show the name ribbon.")
		return
	if slot.occupant_label.text != wounded_card.definition.display_name:
		_fail("Lane name ribbon did not show the card display name.")
		return
	if not slot.wound_glow.visible:
		_fail("Wounded lane card was not visually marked.")
		return
	if not slot.status_badge.visible:
		_fail("Ready lane card should show a status badge.")
		return

	slot.set_highlight_mode(slot.HIGHLIGHT_PLAY)
	if not slot.highlight.visible or not slot.slot_glow.visible:
		_fail("Playable lane highlight did not enable the slot glow.")
		return
	if not slot.target_ring_center.visible:
		_fail("Playable lane highlight did not show the target ring.")
		return

	slot.set_recent_event("UTOK 3", slot.EVENT_ACTION)
	if not slot.event_panel.visible:
		_fail("Lane event banner did not appear.")
		return
	if slot.event_label.text != "UTOK 3":
		_fail("Lane event banner text did not update.")
		return

	print("Lane slot view verification passed.")
	quit()
