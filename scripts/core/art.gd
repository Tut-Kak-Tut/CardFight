class_name Art

const FINAL := "res://assets/art/final/"
const PLACEHOLDER := "res://assets/art/placeholder/"

static var _cache: Dictionary = {}


static func _resolve(name: String) -> String:
	if name == "":
		return ""
	if name.ends_with("_locked"):
		var base := name.trim_suffix("_locked")
		if ResourceLoader.exists(FINAL + name + ".png"):
			return FINAL + name + ".png"
		if ResourceLoader.exists(FINAL + base + ".png"):
			return FINAL + base + ".png"
		if ResourceLoader.exists(PLACEHOLDER + name + ".svg"):
			return PLACEHOLDER + name + ".svg"
		if ResourceLoader.exists(PLACEHOLDER + base + ".svg"):
			return PLACEHOLDER + base + ".svg"
		return ""
	if ResourceLoader.exists(FINAL + name + ".png"):
		return FINAL + name + ".png"
	if ResourceLoader.exists(PLACEHOLDER + name + ".svg"):
		return PLACEHOLDER + name + ".svg"
	return ""


static func path(name: String) -> String:
	return _resolve(name)


static func tex(name: String) -> Texture2D:
	if _cache.has(name):
		return _cache[name]
	var p := _resolve(name)
	var t: Texture2D = load(p) if p != "" else null
	_cache[name] = t
	return t


## true, якщо для name використовується фінальний PNG.
## Для "<x>_locked": true лише коли final-PNG є, але це НЕ окремий _locked (тобто потрібен силует).
static func is_final(name: String) -> bool:
	return _resolve(name).begins_with(FINAL)


## true, якщо для "<x>_locked" окремої locked-текстури нема і взято звичайну (UI робить силует).
static func needs_silhouette(name: String) -> bool:
	var p := _resolve(name)
	return name.ends_with("_locked") and p != "" and not p.get_file().begins_with(name + ".")
