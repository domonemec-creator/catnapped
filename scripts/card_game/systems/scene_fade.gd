extends CanvasLayer

# Autoload „SceneFade“: po každé změně scény krátce roztmí obraz z černé.
# Volající nic nemění (change_scene_to_file zůstává), headless se nic nekreslí.

const FADE_IN_TIME := 0.28

var _rect: ColorRect


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	if DisplayServer.get_name() == "headless":
		return
	_rect = ColorRect.new()
	_rect.color = Color(0.03, 0.02, 0.015, 1.0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.modulate.a = 0.0
	add_child(_rect)
	get_tree().scene_changed.connect(_on_scene_changed)


func _on_scene_changed() -> void:
	if _rect == null:
		return
	_rect.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(_rect, "modulate:a", 0.0, FADE_IN_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
