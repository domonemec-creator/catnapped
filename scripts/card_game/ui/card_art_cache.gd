extends RefCounted

# Sdílené načítání artu karet přes importované resources (funguje i v exportu).
# Portrétní art (2:3) se pro malé náhledy ořízne na horní pás kolem hlavy.

const PLACEHOLDER_PATH := "res://assets/card_game/card_art/_placeholder_back.png"
const CARD_BACK_PATH := "res://assets/card_game/card_art/card_back.png"

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
	if full == null and not resource_path.is_empty():
		# Karta bez artu: rub karty s tlapkou, výřez na střed (emblém).
		full = get_full(PLACEHOLDER_PATH)
		top = 0.3
		height = 0.4
	if full != null:
		var atlas := AtlasTexture.new()
		atlas.atlas = full
		var w := float(full.get_width())
		var h := float(full.get_height())
		atlas.region = Rect2(0.0, h * top, w, minf(h * height, h * (1.0 - top)))
		result = atlas
	_crop_cache[key] = result
	return result


# Ikona keywordu (bílá SVG, obarvuje se přes modulate). Null, když ikona neexistuje.
static func get_keyword_icon(keyword: StringName) -> Texture2D:
	return get_full("res://assets/card_game/icons/%s.svg" % keyword)


# Výřez s daným poměrem stran (šířka/výška). Na výšku: horní pás od `top`.
# Na šířku (scéna s postavou vpravo, např. portrét Smug Tabbyho): výřez kolem focus_x.
static func get_cropped_aspect(resource_path: String, aspect: float, top: float = 0.05) -> Texture2D:
	var key := "aspect|%s|%s|%s" % [resource_path, aspect, top]
	if _crop_cache.has(key):
		return _crop_cache[key]
	var full := get_full(resource_path)
	if full == null:
		return get_cropped(resource_path)
	var w := float(full.get_width())
	var h := float(full.get_height())
	var focus_x := 0.78 if w > h else 0.5
	var region_w := w
	var region_h := region_w / aspect
	if region_h > h * (1.0 - top):
		region_h = h * (1.0 - top)
		region_w = region_h * aspect
	var x := clampf(focus_x * w - region_w * 0.5, 0.0, w - region_w)
	var atlas := AtlasTexture.new()
	atlas.atlas = full
	atlas.region = Rect2(x, h * top, region_w, region_h)
	_crop_cache[key] = atlas
	return atlas
