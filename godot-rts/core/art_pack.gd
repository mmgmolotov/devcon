extends Node
## Optional, user-supplied art pack (autoload "ArtPack"). See docs/ART_PACKS.md.
##
## The game ships with its own art. A pack lets you replace units, buildings,
## resources and grass with your own images. Packs are loaded from the first
## folder below that contains a pack.json:
##   res://artpack/                      - inside the project (git-ignored), for
##                                         building your own personal APK
##   user://artpack/                     - the game's data folder (desktop)
##   <Documents>/TinyRealms/artpack/     - phone/PC documents folder (best effort)
## Anything not in the pack keeps the built-in art. Broken entries are skipped
## and listed in `errors` (shown in Settings) instead of crashing the game.

const TEAM_NAMES := ["blue", "red", "nature"]
## Heading angles (degrees, screen space: y points down) for direction names.
const DIR_ANGLES := {"E": 0.0, "SE": 45.0, "S": 90.0, "SW": 135.0, "W": 180.0,
	"NW": 225.0, "N": 270.0, "NE": 315.0}
const MIRROR := {"E": "W", "SE": "SW", "NE": "NW", "W": "E", "SW": "SE", "NW": "NE"}

var loaded := false
var pack_dir := ""
var pack_name := ""
var errors: Array[String] = []
var overrides := 0
var _pack := {}
var _tex := {}


func _ready() -> void:
	reload()


func search_dirs() -> Array[String]:
	var dirs: Array[String] = ["res://artpack", "user://artpack"]
	var docs := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if docs != "":
		dirs.append(docs.path_join("TinyRealms").path_join("artpack"))
	return dirs


func reload() -> void:
	_pack = {}
	_tex.clear()
	errors.clear()
	loaded = false
	overrides = 0
	pack_dir = ""
	pack_name = ""
	for d in search_dirs():
		var f := d.path_join("pack.json")
		if not FileAccess.file_exists(f):
			continue
		var data = JSON.parse_string(FileAccess.get_file_as_string(f))
		if typeof(data) != TYPE_DICTIONARY:
			errors.append("%s is not valid JSON" % f)
			continue
		_pack = data
		pack_dir = d
		pack_name = str(data.get("name", "Unnamed pack"))
		loaded = true
		_validate()
		break


## Short status line for the Settings screen.
func status_text() -> String:
	if not loaded:
		return "No art pack found (built-in art)."
	var s := "Art pack \"%s\": %d overrides from %s" % [pack_name, overrides, pack_dir]
	if not errors.is_empty():
		s += "\n%d problem(s): %s" % [errors.size(), errors[0]]
	return s


func _validate() -> void:
	for section in ["units", "buildings", "resources"]:
		var entries = _pack.get(section, {})
		if typeof(entries) != TYPE_DICTIONARY:
			errors.append("\"%s\" must be an object" % section)
			_pack[section] = {}
			continue
		for key in entries.keys():
			var def = entries[key]
			var ok := typeof(def) == TYPE_DICTIONARY
			if ok:
				for path in _image_paths(def):
					if texture(path) == null:
						errors.append("%s/%s: can't load %s" % [section, key, path])
						ok = false
						break
			if ok and section == "units" and typeof(def.get("anims")) != TYPE_DICTIONARY:
				errors.append("units/%s: missing \"anims\"" % key)
				ok = false
			if ok:
				overrides += 1
			else:
				entries.erase(key)
	var terrain = _pack.get("terrain", {})
	if typeof(terrain) == TYPE_DICTIONARY:
		for k in terrain:
			if texture(str(terrain[k])) == null:
				errors.append("terrain/%s: can't load %s" % [k, terrain[k]])
			else:
				overrides += 1


func _image_paths(def: Dictionary) -> Array:
	var out := []
	for key in ["image", "construction"]:
		if def.has(key):
			var p := str(def[key])
			if p.contains("{team}"):
				out.append(p.replace("{team}", TEAM_NAMES[0]))
			else:
				out.append(p)
	for p in def.get("images", []):
		out.append(str(p))
	return out


## Loads (and caches) an image relative to the pack folder.
func texture(rel: String) -> Texture2D:
	if _tex.has(rel):
		return _tex[rel]
	var path := pack_dir.path_join(rel)
	var tex: Texture2D = null
	if path.begins_with("res://") and ResourceLoader.exists(path):
		tex = load(path)
	if tex == null and FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null and not img.is_empty():
			tex = ImageTexture.create_from_image(img)
	_tex[rel] = tex
	return tex


func _team_image(def: Dictionary, team: int, key := "image") -> Texture2D:
	var p := str(def.get(key, ""))
	if p == "":
		return null
	if p.contains("{team}"):
		var t := texture(p.replace("{team}", TEAM_NAMES[clampi(team, 0, 2)]))
		return t if t != null else texture(p.replace("{team}", TEAM_NAMES[0]))
	return texture(p)


# --- Units ----------------------------------------------------------------------------

func unit_def(type: String) -> Dictionary:
	return _pack.get("units", {}).get(type, {})


func unit_texture(type: String, team: int) -> Texture2D:
	return _team_image(unit_def(type), team)


## Which pack animation to use for a game action (falls back sensibly).
func unit_anim(type: String, wanted: String) -> Dictionary:
	var anims: Dictionary = unit_def(type).get("anims", {})
	for name in [wanted] + {"work": ["attack", "walk"], "attack": ["walk"], "idle": ["walk"],
			"death": [], "walk": ["idle"]}.get(wanted, ["walk"]):
		if anims.has(name):
			return anims[name]
	return {}


## Source rectangle and mirroring for one frame facing `heading`.
func unit_frame(type: String, anim: Dictionary, heading: Vector2, frame: int) -> Dictionary:
	var def := unit_def(type)
	var size: Array = anim.get("frame", def.get("frame", [64, 64]))
	var fw := float(size[0])
	var fh := float(size[1])
	var dirs: Array = anim.get("directions", def.get("directions", ["S"]))
	var mirror: bool = anim.get("mirror", def.get("mirror", false))
	var pick := _pick_direction(dirs, mirror, heading)
	var y0 := float(anim.get("y", float(anim.get("row", 0)) * fh))
	var n := int(anim.get("frames", 1))
	var f := clampi(frame, 0, n - 1)
	return {"region": Rect2(f * fw, y0 + pick.row * fh, fw, fh), "flip": pick.flip}


func _pick_direction(dirs: Array, mirror: bool, heading: Vector2) -> Dictionary:
	var ang := rad_to_deg(heading.angle()) if heading != Vector2.ZERO else 90.0
	var best := {"row": 0, "flip": false}
	var best_d := 1.0e9
	for i in dirs.size():
		var name := str(dirs[i])
		if not DIR_ANGLES.has(name):
			continue
		var options := [[DIR_ANGLES[name], false]]
		if mirror and MIRROR.has(name) and not dirs.has(MIRROR[name]):
			options.append([DIR_ANGLES[MIRROR[name]], true])
		for o in options:
			var d := absf(wrapf(ang - o[0], -180.0, 180.0))
			if d < best_d:
				best_d = d
				best = {"row": i, "flip": o[1]}
	return best


# --- Buildings and resources -------------------------------------------------------------

func building_def(type: String) -> Dictionary:
	return _pack.get("buildings", {}).get(type, {})


func building_texture(type: String, team: int, constructed: bool) -> Texture2D:
	var def := building_def(type)
	if not constructed:
		return _team_image(def, team, "construction")
	return _team_image(def, team)


func resource_def(kind: String) -> Dictionary:
	return _pack.get("resources", {}).get(kind, {})


func resource_texture(kind: String, variant: int) -> Texture2D:
	var def := resource_def(kind)
	var imgs: Array = def.get("images", [])
	if not imgs.is_empty():
		return texture(str(imgs[absi(variant) % imgs.size()]))
	return _team_image(def, 0)


## Draws a pack image so that its anchor pixel sits at `at`.
func draw_image(ci: CanvasItem, tex: Texture2D, def: Dictionary, at := Vector2.ZERO, modulate := Color.WHITE) -> void:
	var s := float(def.get("scale", 1.0))
	var a: Array = def.get("anchor", [tex.get_width() * 0.5, tex.get_height() * 0.5])
	ci.draw_set_transform(at, 0.0, Vector2(s, s))
	ci.draw_texture(tex, -Vector2(float(a[0]), float(a[1])), modulate)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func terrain_texture(key: String) -> Texture2D:
	var t = _pack.get("terrain", {})
	if typeof(t) != TYPE_DICTIONARY or not t.has(key):
		return null
	return texture(str(t[key]))
