extends RefCounted

# Sdílené načítání artu karet přes importované resources (funguje i v exportu).
# Portrétní art (2:3) se pro malé náhledy ořízne na horní pás kolem hlavy.

static var _full_cache: Dictionary = {}
static var _crop_cache: Dictionary = {}


static func get_full(resource_path: String) -> Texture2D:
	if resource_path.is_empty():
		return null
	if not _full_cache.has(resource_path):
		_full_cache[resource_path] = load(resource_path) if ResourceLoader.exists(resource_path) else null
	return _full_cache[resource_path]


# top/height jsou podíly výšky artu; výchozí pás sedí na hlavu u současných portrétů.
static func get_cropped(resource_path: String, top: float = 0.04, height: float = 0.42) -> Texture2D:
	var key := "%s|%s|%s" % [resource_path, top, height]
	if _crop_cache.has(key):
		return _crop_cache[key]
	var full := get_full(resource_path)
	var result: Texture2D = null
	if full != null:
		var atlas := AtlasTexture.new()
		atlas.atlas = full
		var w := float(full.get_width())
		var h := float(full.get_height())
		atlas.region = Rect2(0.0, h * top, w, minf(h * height, h * (1.0 - top)))
		result = atlas
	_crop_cache[key] = result
	return result
