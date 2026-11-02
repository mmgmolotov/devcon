extends CanvasLayer
## Mobile HUD with a medieval look: carved-wood panels with gold trim,
## drawn resource icons, a portrait of the selection, picture buttons,
## a framed minimap, placement bar, toasts and the game-over screen.
## Built in code so the layout adapts to any landscape aspect ratio.

const FONT_SIZE := 22
const ACTION_SIZE := Vector2(116, 112)
const TOP_H := 58.0
const BOTTOM_H := 136.0
const MINIMAP_SIZE := 176.0

const PARCHMENT := Color(0.98, 0.92, 0.78)
const GOLD := Color(0.83, 0.66, 0.32)
const WOOD_BG := Color(0.2, 0.13, 0.08, 0.95)

var _root: Control
var _top_bar: PanelContainer
var _res_labels := {}
var _pop_label: Label
var _time_label: Label
var _bottom: PanelContainer
var _portrait: IconView
var _portrait_count: Label
var _title_label: Label
var _hp_bar: ProgressBar
var _status_label: Label
var _actions: HBoxContainer
var _minimap: Control
var _placement: PanelContainer
var _placement_label: Label
var _placement_ok: Button
var _toast: Label
var _toast_t := 0.0
var _overlay: ColorRect
var _overlay_label: Label
var _box: Control
var _box_rect := Rect2()
var _refresh_t := 0.0
var _portrait_key := ""


func _ready() -> void:
	layer = 10
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = _make_theme()
	add_child(_root)
	_build_vignette()
	_build_box_overlay()
	_build_top_bar()
	_build_minimap()
	_build_bottom_panel()
	_build_placement_bar()
	_build_toast()
	_build_game_over()
	Game.selection_changed.connect(_rebuild_actions)
	Game.resources_changed.connect(_refresh)
	Game.notify.connect(show_toast)
	Game.game_over.connect(_on_game_over)
	Game.building_completed.connect(func(_b): _rebuild_actions())
	var ghost = Game.placement_ghost
	if ghost != null:
		ghost.changed.connect(_on_placement_changed)
	_rebuild_actions()
	_refresh()


func _process(delta: float) -> void:
	_refresh_t -= delta
	if _refresh_t <= 0.0:
		_refresh_t = 0.25
		_refresh()
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.modulate.a = clampf(_toast_t / 0.5, 0.0, 1.0)
		_toast.visible = _toast_t > 0.0


## Used by the input controller so taps on HUD panels don't reach the map.
func is_point_over_ui(p: Vector2) -> bool:
	if _overlay.visible:
		return true
	for c in [_top_bar, _bottom, _minimap, _placement]:
		if c.visible and c.get_global_rect().has_point(p):
			return true
	return false


func set_selection_box(r: Rect2) -> void:
	_box_rect = r
	_box.queue_redraw()


func show_toast(text: String) -> void:
	_toast.text = text
	_toast.visible = true
	_toast.modulate.a = 1.0
	_toast_t = 2.2


# --- Theme -----------------------------------------------------------------------------------

func _framed(bg: Color, border: Color, border_w: int, radius: int, margin: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	return sb


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = FONT_SIZE
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Georgia", "Noto Serif", "DejaVu Serif", "Liberation Serif", "serif"])
	font.font_weight = 600
	t.default_font = font
	var panel := _framed(WOOD_BG, GOLD, 3, 6, 8)
	panel.shadow_color = Color(0, 0, 0, 0.45)
	panel.shadow_size = 6
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_color("font_color", "Label", PARCHMENT)
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.85))
	t.set_constant("outline_size", "Label", 4)
	t.set_stylebox("normal", "Button", _framed(Color(0.36, 0.24, 0.13), GOLD.darkened(0.15), 2, 8, 6))
	t.set_stylebox("hover", "Button", _framed(Color(0.43, 0.29, 0.16), GOLD, 2, 8, 6))
	t.set_stylebox("pressed", "Button", _framed(Color(0.55, 0.38, 0.17), Color(1.0, 0.85, 0.45), 3, 8, 6))
	t.set_stylebox("disabled", "Button", _framed(Color(0.2, 0.16, 0.12), Color(0.4, 0.35, 0.3), 2, 8, 6))
	var focus := StyleBoxEmpty.new()
	t.set_stylebox("focus", "Button", focus)
	t.set_color("font_color", "Button", PARCHMENT)
	t.set_color("font_hover_color", "Button", Color(1, 0.97, 0.88))
	t.set_color("font_pressed_color", "Button", Color(1, 0.95, 0.75))
	t.set_color("font_disabled_color", "Button", Color(0.55, 0.5, 0.45))
	t.set_color("font_outline_color", "Button", Color(0, 0, 0, 0.8))
	t.set_constant("outline_size", "Button", 3)
	t.set_stylebox("background", "ProgressBar", _framed(Color(0.08, 0.05, 0.03), GOLD.darkened(0.3), 1, 3, 0))
	t.set_stylebox("fill", "ProgressBar", _framed(Color(0.3, 0.75, 0.3), Color(0, 0, 0, 0), 0, 3, 0))
	return t


# --- Layout ------------------------------------------------------------------------------------

func _build_vignette() -> void:
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0))
	g.set_color(1, Color(0, 0, 0, 0.42))
	g.add_point(0.62, Color(0, 0, 0, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.05, 1.05)
	tex.width = 128
	tex.height = 128
	var v := TextureRect.new()
	v.texture = tex
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.stretch_mode = TextureRect.STRETCH_SCALE
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(v)


func _build_box_overlay() -> void:
	_box = Control.new()
	_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.draw.connect(func():
		if _box_rect.size.length() > 2.0:
			_box.draw_rect(_box_rect, Color(0.45, 1.0, 0.45, 0.15))
			_box.draw_rect(_box_rect, Color(0.45, 1.0, 0.45, 0.9), false, 2.0))
	_root.add_child(_box)


func _build_top_bar() -> void:
	_top_bar = PanelContainer.new()
	_top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top_bar.custom_minimum_size.y = TOP_H
	_root.add_child(_top_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_top_bar.add_child(row)
	for r in Game.RESOURCE_TYPES:
		row.add_child(_icon("resource", r, Vector2(34, 34)))
		var l := Label.new()
		l.custom_minimum_size.x = 72
		row.add_child(l)
		_res_labels[r] = l
	row.add_child(_icon("resource", "pop", Vector2(34, 34)))
	_pop_label = Label.new()
	_pop_label.custom_minimum_size.x = 84
	row.add_child(_pop_label)
	_time_label = Label.new()
	_time_label.modulate = Color(1, 0.9, 0.6)
	row.add_child(_time_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)
	row.add_child(_icon_button("unit", "villager", "Idle", Vector2(118, 46), _select_idle_villager, true))
	row.add_child(_icon_button("unit", "swordsman", "Army", Vector2(118, 46), _select_army, true))


func _build_minimap() -> void:
	_minimap = preload("res://ui/minimap.gd").new()
	_minimap.anchor_left = 1.0
	_minimap.anchor_right = 1.0
	_minimap.offset_left = -MINIMAP_SIZE - 12.0
	_minimap.offset_right = -12.0
	_minimap.offset_top = TOP_H + 12.0
	_minimap.offset_bottom = TOP_H + 12.0 + MINIMAP_SIZE
	_root.add_child(_minimap)


func _build_bottom_panel() -> void:
	_bottom = PanelContainer.new()
	_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom.offset_top = -BOTTOM_H
	_root.add_child(_bottom)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_bottom.add_child(row)

	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _framed(Color(0.36, 0.3, 0.22), GOLD, 3, 4, 2))
	frame.custom_minimum_size = Vector2(112, 112)
	row.add_child(frame)
	_portrait = IconView.new()
	frame.add_child(_portrait)
	_portrait_count = Label.new()
	_portrait_count.add_theme_font_size_override("font_size", 20)
	_portrait_count.size_flags_vertical = Control.SIZE_SHRINK_END
	_portrait_count.size_flags_horizontal = Control.SIZE_SHRINK_END
	frame.add_child(_portrait_count)

	var info := VBoxContainer.new()
	info.custom_minimum_size.x = 300
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 6)
	row.add_child(info)
	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 26)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.5))
	info.add_child(_title_label)
	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(260, 14)
	_hp_bar.show_percentage = false
	_hp_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	info.add_child(_hp_bar)
	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 18)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size.x = 300
	info.add_child(_status_label)

	_actions = HBoxContainer.new()
	_actions.add_theme_constant_override("separation", 10)
	_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_actions.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_child(_actions)


func _build_placement_bar() -> void:
	_placement = PanelContainer.new()
	_placement.anchor_left = 0.5
	_placement.anchor_right = 0.5
	_placement.offset_top = TOP_H + 12.0
	_placement.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_placement.visible = false
	_root.add_child(_placement)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_placement.add_child(row)
	_placement_label = Label.new()
	row.add_child(_placement_label)
	_placement_ok = _text_button("Build", Vector2(130, 64), func(): Game.placement_ghost.confirm())
	row.add_child(_placement_ok)
	row.add_child(_text_button("Cancel", Vector2(130, 64), func(): Game.placement_ghost.cancel()))


func _build_toast() -> void:
	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.offset_top = -BOTTOM_H - 58.0
	_toast.offset_bottom = -BOTTOM_H - 18.0
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 26)
	_toast.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55))
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.visible = false
	_root.add_child(_toast)


func _build_game_over() -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.62)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	_root.add_child(_overlay)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	panel.add_child(box)
	_overlay_label = Label.new()
	_overlay_label.add_theme_font_size_override("font_size", 64)
	_overlay_label.add_theme_constant_override("outline_size", 10)
	_overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_label.custom_minimum_size.x = 420
	box.add_child(_overlay_label)
	var again := _text_button("Play Again", Vector2(260, 84), func(): get_tree().reload_current_scene())
	again.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(again)


# --- Widgets -----------------------------------------------------------------------------------

func _icon(kind: String, type: String, min_size: Vector2) -> IconView:
	var v := IconView.new().setup(kind, type, Game.PLAYER)
	v.custom_minimum_size = min_size
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return v


func _text_button(text: String, min_size: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b


## A button showing game art with a caption (cost or name) underneath.
## With `inline`, the icon sits left of the caption (compact top-bar style).
func _icon_button(kind: String, type: String, caption: String, min_size: Vector2, cb: Callable, inline := false) -> Button:
	var b := _text_button("", min_size, cb)
	var box: BoxContainer = HBoxContainer.new() if inline else VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 4
	box.offset_right = -4
	box.offset_top = 3
	box.offset_bottom = -3
	box.add_theme_constant_override("separation", 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if inline:
		box.alignment = BoxContainer.ALIGNMENT_CENTER
	b.add_child(box)
	var icon := IconView.new().setup(kind, type, Game.PLAYER)
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if inline:
		icon.custom_minimum_size = Vector2(36, 36)
		icon.size_flags_horizontal = Control.SIZE_FILL
	box.add_child(icon)
	var l := Label.new()
	l.text = caption
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 19 if inline else 16)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(l)
	b.set_meta("icon", icon)
	return b


# --- Dynamic content -----------------------------------------------------------------------------

func _refresh() -> void:
	if _pop_label == null:
		return
	var p: Dictionary = Game.players[Game.PLAYER]
	for r in Game.RESOURCE_TYPES:
		_res_labels[r].text = str(p[r])
	var pop := Game.get_pop(Game.PLAYER)
	var cap := Game.get_pop_cap(Game.PLAYER)
	_pop_label.text = "%d/%d" % [pop, cap]
	_pop_label.modulate = Color(1, 0.5, 0.4) if pop >= cap else Color.WHITE
	var t := int(Game.elapsed)
	_time_label.text = "%d:%02d" % [t / 60, t % 60]
	_refresh_info()
	for b in _actions.get_children():
		if not b is Button:
			continue
		if b.has_meta("cost"):
			b.disabled = not Game.can_afford(Game.PLAYER, b.get_meta("cost"))
		if b.has_meta("needs_queue"):
			var bld := Game.selected_own_building()
			b.disabled = bld == null or bld.queue.is_empty()
		if b.has_meta("icon"):
			b.get_meta("icon").modulate.a = 0.4 if b.disabled else 1.0


func _refresh_info() -> void:
	var sel := Game.selected
	if sel.is_empty():
		_set_portrait("", "", 0)
		_title_label.text = "Your Realm"
		_hp_bar.visible = false
		_status_label.text = "Tap a unit or building. Drag to box-select.\nTwo fingers: pan, pinch to zoom."
		_portrait_count.text = ""
		return
	var e = sel[0]
	if e is Unit:
		_set_portrait("unit", e.type, e.team)
	elif e is Building:
		_set_portrait("building", e.type, e.team)
	_hp_bar.visible = true
	if sel.size() == 1:
		var owner := "" if e.team == Game.PLAYER else "  (enemy)"
		_title_label.text = "%s%s" % [e.get_display_name(), owner]
		_hp_bar.max_value = e.max_hp
		_hp_bar.value = e.hp
		_status_label.text = "HP %d/%d   %s" % [ceili(e.hp), int(e.max_hp), e.get_status_text()]
		_portrait_count.text = ""
		return
	var counts := {}
	var hp := 0.0
	var max_hp := 0.0
	for u in sel:
		counts[u.get_display_name()] = counts.get(u.get_display_name(), 0) + 1
		hp += u.hp
		max_hp += u.max_hp
	var parts: Array[String] = []
	for k in counts:
		parts.append("%d %s" % [counts[k], k])
	_title_label.text = "%d units" % sel.size()
	_hp_bar.max_value = max_hp
	_hp_bar.value = hp
	_status_label.text = ", ".join(parts)
	_portrait_count.text = "x%d " % sel.size()


func _set_portrait(kind: String, type: String, team: int) -> void:
	var key := "%s/%s/%d" % [kind, type, team]
	if key == _portrait_key:
		return
	_portrait_key = key
	_portrait.visible = kind != ""
	if kind != "":
		_portrait.setup(kind, type, team)


func _rebuild_actions() -> void:
	for c in _actions.get_children():
		c.queue_free()
	var own := Game.selected_own_units()
	var bld := Game.selected_own_building()
	if not own.is_empty():
		if own.any(func(u): return u.is_villager):
			for t in Game.BUILDABLE:
				var d: Dictionary = Game.BUILDING_DATA[t]
				var b := _icon_button("building", t, Game.cost_text(d.cost), ACTION_SIZE, _start_placement.bind(t))
				b.set_meta("cost", d.cost)
				_actions.add_child(b)
		_actions.add_child(_text_button("Stop", ACTION_SIZE, _stop_selected))
	elif bld != null and bld.constructed:
		for t in bld.data.trains:
			var d: Dictionary = Game.UNIT_DATA[t]
			var b := _icon_button("unit", t, Game.cost_text(d.cost), ACTION_SIZE, _train.bind(bld, t))
			b.set_meta("cost", d.cost)
			_actions.add_child(b)
		if not bld.data.trains.is_empty():
			var c := _text_button("Cancel", ACTION_SIZE, func(): bld.cancel_last())
			c.set_meta("needs_queue", true)
			_actions.add_child(c)
	if not Game.selected.is_empty():
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_actions.add_child(spacer)
		_actions.add_child(_text_button("X", Vector2(88, ACTION_SIZE.y), Game.clear_selection))
	_refresh()


func _start_placement(type: String) -> void:
	var cost: Dictionary = Game.BUILDING_DATA[type].cost
	if not Game.can_afford(Game.PLAYER, cost):
		show_toast(Game.missing_text(Game.PLAYER, cost))
		return
	Game.placement_ghost.begin(type, Game.camera.position)


func _train(b: Building, type: String) -> void:
	if not Game.alive(b):
		return
	var err := b.enqueue(type)
	if err != "":
		show_toast(err)
	_refresh()


func _stop_selected() -> void:
	for u in Game.selected_own_units():
		u.command_stop()


func _select_idle_villager() -> void:
	var idle := Game.units.filter(func(u): return u.team == Game.PLAYER and u.is_villager and u.state == Unit.State.IDLE)
	if idle.is_empty():
		show_toast("No idle villagers")
		return
	var cur = Game.selected[0] if Game.selected.size() == 1 else null
	var i := (idle.find(cur) + 1) % idle.size()
	Game.set_selection([idle[i]])
	Game.camera.center_on(idle[i].position)


func _select_army() -> void:
	var army := Game.units.filter(func(u): return u.team == Game.PLAYER and not u.is_villager)
	if army.is_empty():
		show_toast("No soldiers yet - build a Barracks")
		return
	Game.set_selection(army)


func _on_placement_changed() -> void:
	var g = Game.placement_ghost
	_placement.visible = g.is_active()
	if g.is_active():
		_placement_label.text = "Place %s: tap the map" % Game.BUILDING_DATA[g.type].name
		_placement_ok.disabled = not g.valid


func _on_game_over(winner: int) -> void:
	Game.placement_ghost.cancel()
	_overlay.visible = true
	_overlay_label.text = "VICTORY!" if winner == Game.PLAYER else "DEFEAT"
	_overlay_label.add_theme_color_override("font_color",
		Color(1, 0.85, 0.35) if winner == Game.PLAYER else Color(1, 0.4, 0.35))
