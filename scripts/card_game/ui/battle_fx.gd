extends RefCounted

# Jednoduché bojové efekty přes Tweeny: výpad útočníka, otřes zásahu, plovoucí čísla, záblesk.
# Všechny funkce jsou bezpečné pro headless běh (verifiery): bez okna nic neanimují.


static func is_enabled() -> bool:
	return DisplayServer.get_name() != "headless"


# Krátký výpad směrem k cíli a návrat (útočník). direction: -1 nahoru (hráč útočí), +1 dolů (soupeř).
static func lunge(node: Control, direction: float, distance: float = 34.0, duration: float = 0.22) -> void:
	if not is_enabled() or node == null or not is_instance_valid(node):
		return
	var base := node.position
	var tween := node.create_tween()
	tween.tween_property(node, "position", base + Vector2(0.0, direction * distance), duration * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position", base, duration * 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Otřes po zásahu.
static func shake(node: Control, strength: float = 9.0, duration: float = 0.28) -> void:
	if not is_enabled() or node == null or not is_instance_valid(node):
		return
	var base := node.position
	var tween := node.create_tween()
	var steps := 6
	for i in range(steps):
		var falloff := 1.0 - float(i) / float(steps)
		var offset := Vector2(randf_range(-1.0, 1.0), randf_range(-0.5, 0.5)) * strength * falloff
		tween.tween_property(node, "position", base + offset, duration / float(steps + 1))
	tween.tween_property(node, "position", base, duration / float(steps + 1))


# Barevný záblesk přes celý prvek (modulate).
static func flash(node: CanvasItem, color: Color = Color(1.6, 0.6, 0.5), duration: float = 0.3) -> void:
	if not is_enabled() or node == null or not is_instance_valid(node):
		return
	var tween := node.create_tween()
	node.modulate = color
	tween.tween_property(node, "modulate", Color.WHITE, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# Plovoucí text (např. "-3") nad prvkem, stoupá a mizí. Label se vloží do overlay vrstvy, aby ho
# nerozhodily kontejnery, a po dokončení se sám smaže.
static func float_text(anchor: Control, text: String, color: Color, font_size: int = 40) -> void:
	if not is_enabled() or anchor == null or not is_instance_valid(anchor) or not anchor.is_inside_tree():
		return
	var layer := _get_overlay_layer(anchor)
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	label.add_theme_constant_override("outline_size", 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(label)
	var rect := anchor.get_global_rect()
	label.size = Vector2(rect.size.x, font_size * 1.4)
	label.global_position = rect.position + Vector2(0.0, rect.size.y * 0.5 - label.size.y * 0.5)
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2(0.6, 0.6)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "global_position:y", label.global_position.y - 60.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.45).set_delay(0.5)
	tween.chain().tween_callback(label.queue_free)


static func _get_overlay_layer(anchor: Control) -> CanvasLayer:
	var root := anchor.get_tree().root
	var layer := root.get_node_or_null("BattleFxLayer") as CanvasLayer
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = "BattleFxLayer"
		layer.layer = 50
		root.add_child(layer)
	return layer
