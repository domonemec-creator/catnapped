extends SceneTree

const TARGET_PATHS := [
    "res://assets/card_game/ui/postmatch_victory_emblem.png",
    "res://assets/card_game/ui/postmatch_defeat_emblem.png",
    "res://assets/card_game/ui/postmatch_threat_badge.png",
]


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    for resource_path in TARGET_PATHS:
        var absolute_path := ProjectSettings.globalize_path(resource_path)
        var image := Image.load_from_file(absolute_path)
        if image == null or image.is_empty():
            push_error("Could not load %s" % resource_path)
            quit(1)
            return
        _remove_checker_background(image)
        var save_error := image.save_png(absolute_path)
        if save_error != OK:
            push_error("Could not save cleaned %s" % resource_path)
            quit(1)
            return

    print("Post-match assets cleaned.")
    quit()


func _remove_checker_background(image: Image) -> void:
    image.convert(Image.FORMAT_RGBA8)
    var width := image.get_width()
    var height := image.get_height()
    var visited := {}
    var queue: Array[Vector2i] = []

    for x in range(width):
        _try_enqueue_background_pixel(image, Vector2i(x, 0), queue, visited)
        _try_enqueue_background_pixel(image, Vector2i(x, height - 1), queue, visited)
    for y in range(height):
        _try_enqueue_background_pixel(image, Vector2i(0, y), queue, visited)
        _try_enqueue_background_pixel(image, Vector2i(width - 1, y), queue, visited)

    var offsets: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
    while not queue.is_empty():
        var point: Vector2i = queue.pop_back()
        var color := image.get_pixelv(point)
        color.a = 0.0
        image.set_pixelv(point, color)

        for offset in offsets:
            var next_point: Vector2i = point + offset
            if next_point.x < 0 or next_point.y < 0 or next_point.x >= width or next_point.y >= height:
                continue
            _try_enqueue_background_pixel(image, next_point, queue, visited)


func _try_enqueue_background_pixel(image: Image, point: Vector2i, queue: Array[Vector2i], visited: Dictionary) -> void:
    if visited.has(point):
        return
    visited[point] = true
    var color := image.get_pixelv(point)
    if not _is_background_candidate(color):
        return
    queue.append(point)


func _is_background_candidate(color: Color) -> bool:
    if color.a <= 0.0:
        return false
    var rgb_max := maxf(color.r, maxf(color.g, color.b))
    var rgb_min := minf(color.r, minf(color.g, color.b))
    var neutral_delta := rgb_max - rgb_min
    return rgb_max >= 0.88 and neutral_delta <= 0.06
