extends Node
## Main menu. A live AI-vs-AI battle plays in the background while the player
## picks a mode (Skirmish, Survival, Sandbox), difficulty and map.

const MODES := [
	{"id": "skirmish", "title": "Skirmish", "icon": ["building", "town_center"],
		"text": "Build your realm and destroy the enemy Town Center before they destroy yours."},
	{"id": "survival", "title": "Survival", "icon": ["unit", "knight"],
		"text": "No enemy base - hold out against 12 growing raider waves from the map edges."},
	{"id": "sandbox", "title": "Sandbox", "icon": ["building", "mill"],
		"text": "1000 of every resource and a peaceful enemy. Build freely and experiment."},
]
const DIFFICULTIES := ["Easy", "Normal", "Hard"]

var _ui: Control
var _fade: ColorRect
var _title_box: Control
var _main_panel: Control
var _mode_panel: Control
var _settings_panel: Control
var _credits_panel: Control
var _mode := "skirmish"
var _difficulty := 1
var _random_map := false
var _mode_buttons := {}
var _diff_buttons: Array[Button] = []
var _map_buttons: Array[Button] = []
var _t := 0.0


func _ready() -> void:
	_mode = Sound.settings.get("mode", "skirmish")
	_difficulty = int(Sound.settings.get("difficulty", 1))
	_random_map = bool(Sound.settings.get("random_map", false))
	# Background battle.
	Game.mode = "demo"
	Game.difficulty = 1
	Game.random_map = false
	add_child(load("res://main/main.tscn").instantiate())
	Sound.set_in_game(false)
	Sound.play_music("menu")
	_build_ui()
	_show(_main_panel)
	_fade.color.a = 1.0
	create_tween().tween_property(_fade, "color:a", 0.0, 0.8)


func _process(delta: float) -> void:
	_t += delta
	if _title_box != null:
		_title_box.position.y = 36.0 + sin(_t * 1.3) * 4.0


# --- Layout ----------------------------------------------------------------------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.theme = UITheme.build(24)
	layer.add_child(_ui)
	_ui.add_child(_shade())

	_title_box = VBoxContainer.new()
	_title_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_title_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_title_box.position.y = 36
	_title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_title_box)
	var title := UITheme.label("TINY REALMS", 96, UITheme.TITLE)
	title.add_theme_constant_override("outline_size", 16)
	title.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.02))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	title.add_theme_constant_override("shadow_offset_y", 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_box.add_child(title)
	var sub := UITheme.label("Gather  -  Build  -  Conquer", 26, UITheme.PARCHMENT)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_box.add_child(sub)

	_main_panel = _build_main_panel()
	_mode_panel = _build_mode_panel()
	_settings_panel = _build_settings_panel()
	_credits_panel = _build_credits_panel()

	var version := UITheme.label("v0.4  -  original game, CC0/CC-BY assets", 16, Color(1, 1, 1, 0.6))
	version.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	version.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	version.grow_vertical = Control.GROW_DIRECTION_BEGIN
	version.position -= Vector2(12, 8)
	_ui.add_child(version)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_fade)


## Soft dark gradient so text reads well over the battle.
func _shade() -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.15))
	g.set_color(1, Color(0, 0, 0, 0.7))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.45)
	tex.fill_to = Vector2(1.1, 1.1)
	var r := TextureRect.new()
	r.texture = tex
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _centered_panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.position.y += 60
	_ui.add_child(p)
	return p


func _build_main_panel() -> Control:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.position.y += 80
	box.add_theme_constant_override("separation", 16)
	_ui.add_child(box)
	box.add_child(UITheme.button("Play", Vector2(380, 84), func(): _show(_mode_panel), 34))
	box.add_child(UITheme.button("Settings", Vector2(380, 70), func(): _show(_settings_panel)))
	box.add_child(UITheme.button("Credits", Vector2(380, 70), func():
		_show(_credits_panel)
		Sound.play_music("credits")))
	box.add_child(UITheme.button("Quit", Vector2(380, 70), func(): get_tree().quit()))
	return box


func _build_mode_panel() -> Control:
	var panel := _centered_panel()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var head := UITheme.label("Choose a Mode", 34, UITheme.TITLE)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(head)

	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 16)
	box.add_child(cards)
	var group := ButtonGroup.new()
	for m in MODES:
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(290, 250)
		b.button_pressed = m.id == _mode
		b.pressed.connect(func():
			_mode = m.id
			Sound.play("select", null, -6.0))
		var v := VBoxContainer.new()
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 10
		v.offset_right = -10
		v.offset_top = 8
		v.offset_bottom = -8
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(v)
		var icon := IconView.new().setup(m.icon[0], m.icon[1], Game.PLAYER)
		icon.custom_minimum_size = Vector2(0, 104)
		v.add_child(icon)
		var t := UITheme.label(m.title, 30, UITheme.TITLE)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(t)
		var d := UITheme.label(m.text, 17)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(d)
		cards.add_child(b)
		_mode_buttons[m.id] = b

	box.add_child(_toggle_row("Difficulty", DIFFICULTIES, _difficulty, _diff_buttons, func(i): _difficulty = i))
	box.add_child(_toggle_row("Map", ["Classic", "Random"], int(_random_map), _map_buttons, func(i): _random_map = i == 1))

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 20)
	box.add_child(bottom)
	bottom.add_child(UITheme.button("Back", Vector2(200, 76), func(): _show(_main_panel)))
	var start := UITheme.button("START", Vector2(320, 76), _start_game, 34)
	start.add_theme_stylebox_override("normal", UITheme.framed(Color(0.55, 0.35, 0.1), Color(1, 0.85, 0.4), 3, 8, 6))
	bottom.add_child(start)
	return panel


func _toggle_row(caption: String, options: Array, selected: int, store: Array[Button], cb: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	var l := UITheme.label(caption, 24)
	l.custom_minimum_size.x = 140
	row.add_child(l)
	var group := ButtonGroup.new()
	for i in options.size():
		var b := Button.new()
		b.text = options[i]
		b.toggle_mode = true
		b.button_group = group
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(150, 58)
		b.button_pressed = i == selected
		b.pressed.connect(func():
			cb.call(i)
			Sound.play("click", null, -8.0))
		row.add_child(b)
		store.append(b)
	return row


func _build_settings_panel() -> Control:
	var panel := _centered_panel()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	var head := UITheme.label("Settings", 34, UITheme.TITLE)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(head)
	box.add_child(UITheme.volume_slider("Music", true))
	box.add_child(UITheme.volume_slider("Sound", false))
	var back := UITheme.button("Back", Vector2(220, 70), func(): _show(_main_panel))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(back)
	return panel


func _build_credits_panel() -> Control:
	var panel := _centered_panel()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var head := UITheme.label("Credits", 34, UITheme.TITLE)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(head)
	var body := UITheme.label("", 18)
	body.custom_minimum_size.x = 720
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text = ("Tiny Realms - an original pocket strategy game.\n"
		+ "Code, buildings, terrain, siege engines and effects: original.\n\n"
		+ "Unit sprites: Liberated Pixel Cup contributors (CC-BY-SA 3.0 / OGA-BY 3.0) - bluecarrot16, "
		+ "JaidynReiman, wulax, Redshrike, makrohn, pvigier, BenCreating, ElizaWy, bigbeargames, "
		+ "castelonia, drjamgo and others.\n"
		+ "Animals: daneeklu (sheep, boar), Calciumtrice (deer) - CC-BY 3.0.\n"
		+ "Music & sounds: Ninja Adventure by Pixel-boy & AAA, and Kenney audio packs - CC0.\n"
		+ "Grass textures: openage-data by the openage authors - CC-BY-SA 4.0.\n\n"
		+ "Full details: CREDITS.md")
	box.add_child(body)
	var back := UITheme.button("Back", Vector2(220, 70), func():
		_show(_main_panel)
		Sound.play_music("menu"))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(back)
	return panel


func _show(panel: Control) -> void:
	for p in [_main_panel, _mode_panel, _settings_panel, _credits_panel]:
		p.visible = p == panel
	_title_box.visible = panel == _main_panel or panel == _settings_panel
	panel.modulate.a = 0.0
	create_tween().tween_property(panel, "modulate:a", 1.0, 0.25)


func _start_game() -> void:
	Sound.settings["mode"] = _mode
	Sound.settings["difficulty"] = _difficulty
	Sound.settings["random_map"] = _random_map
	Sound.save_settings()
	Game.mode = _mode
	Game.difficulty = _difficulty
	Game.random_map = _random_map
	Sound.play("confirm")
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.5)
	tw.tween_callback(func(): get_tree().change_scene_to_file("res://main/main.tscn"))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _main_panel.visible:
			get_tree().quit()
		else:
			_show(_main_panel)
			Sound.play_music("menu")
