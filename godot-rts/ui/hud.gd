extends CanvasLayer
## Mobile HUD: top resource bar, minimap, bottom selection panel with large
## action buttons, building placement bar, toasts and the game-over screen.
## Built in code so the layout adapts to any landscape aspect ratio.

const FONT_SIZE := 22
const ACTION_SIZE := Vector2(132, 104)
const TOP_H := 56.0
const BOTTOM_H := 128.0
const MINIMAP_SIZE := 168.0

var _root: Control
var _top_bar: PanelContainer
var _res_labels := {}
var _pop_label: Label
var _time_label: Label
var _bottom: PanelContainer
var _title_label: Label
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


func _ready() -> void:
	layer = 10
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = _make_theme()
	add_child(_root)
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


# --- Construction of the layout -----------------------------------------------------

func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = FONT_SIZE
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.08, 0.09, 0.11, 0.86)
	panel.set_content_margin_all(8)
	panel.set_corner_radius_all(6)
	t.set_stylebox("panel", "PanelContainer", panel)
	var states := {
		"normal": Color(0.24, 0.27, 0.33), "hover": Color(0.3, 0.34, 0.42),
		"pressed": Color(0.18, 0.4, 0.62), "disabled": Color(0.18, 0.18, 0.2),
		"focus": Color(0, 0, 0, 0),
	}
	for s in states:
		var sb := StyleBoxFlat.new()
		sb.bg_color = states[s]
		sb.set_corner_radius_all(8)
		sb.set_content_margin_all(6)
		if s != "focus":
			sb.border_color = Color(0.5, 0.55, 0.65, 0.6)
			sb.set_border_width_all(2)
		else:
			sb.draw_center = false
		t.set_stylebox(s, "Button", sb)
	t.set_color("font_disabled_color", "Button", Color(0.55, 0.55, 0.55))
	return t


func _build_box_overlay() -> void:
	_box = Control.new()
	_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.draw.connect(func():
		if _box_rect.size.length() > 2.0:
			_box.draw_rect(_box_rect, Color(0.4, 1.0, 0.4, 0.15))
			_box.draw_rect(_box_rect, Color(0.4, 1.0, 0.4, 0.9), false, 2.0))
	_root.add_child(_box)


func _build_top_bar() -> void:
	_top_bar = PanelContainer.new()
	_top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top_bar.custom_minimum_size.y = TOP_H
	_root.add_child(_top_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_top_bar.add_child(row)
	for r in Game.RESOURCE_TYPES:
		var icon := ColorRect.new()
		icon.color = Game.RESOURCE_COLORS[r]
		icon.custom_minimum_size = Vector2(22, 22)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)
		var l := Label.new()
		l.custom_minimum_size.x = 92
		row.add_child(l)
		_res_labels[r] = l
	_pop_label = Label.new()
	_pop_label.custom_minimum_size.x = 140
	row.add_child(_pop_label)
	_time_label = Label.new()
	row.add_child(_time_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)
	row.add_child(_make_button("Idle Villager", Vector2(170, 44), _select_idle_villager))
	row.add_child(_make_button("Army", Vector2(110, 44), _select_army))


func _build_minimap() -> void:
	_minimap = preload("res://ui/minimap.gd").new()
	_minimap.anchor_left = 1.0
	_minimap.anchor_right = 1.0
	_minimap.offset_left = -MINIMAP_SIZE - 10.0
	_minimap.offset_right = -10.0
	_minimap.offset_top = TOP_H + 10.0
	_minimap.offset_bottom = TOP_H + 10.0 + MINIMAP_SIZE
	_root.add_child(_minimap)


func _build_bottom_panel() -> void:
	_bottom = PanelContainer.new()
	_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom.offset_top = -BOTTOM_H
	_root.add_child(_bottom)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_bottom.add_child(row)
	var info := VBoxContainer.new()
	info.custom_minimum_size.x = 360
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(info)
	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 26)
	info.add_child(_title_label)
	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 19)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size.x = 360
	info.add_child(_status_label)
	_actions = HBoxContainer.new()
	_actions.add_theme_constant_override("separation", 10)
	_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_actions)


func _build_placement_bar() -> void:
	_placement = PanelContainer.new()
	_placement.anchor_left = 0.5
	_placement.anchor_right = 0.5
	_placement.offset_top = TOP_H + 10.0
	_placement.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_placement.visible = false
	_root.add_child(_placement)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_placement.add_child(row)
	_placement_label = Label.new()
	row.add_child(_placement_label)
	_placement_ok = _make_button("Build", Vector2(130, 64), func(): Game.placement_ghost.confirm())
	row.add_child(_placement_ok)
	row.add_child(_make_button("Cancel", Vector2(130, 64), func(): Game.placement_ghost.cancel()))


func _build_toast() -> void:
	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.offset_top = -BOTTOM_H - 56.0
	_toast.offset_bottom = -BOTTOM_H - 16.0
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 24)
	_toast.add_theme_color_override("font_outline_color", Color.BLACK)
	_toast.add_theme_constant_override("outline_size", 6)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.visible = false
	_root.add_child(_toast)


func _build_game_over() -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.6)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	_root.add_child(_overlay)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	_overlay.add_child(box)
	_overlay_label = Label.new()
	_overlay_label.add_theme_font_size_override("font_size", 64)
	_overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_overlay_label)
	var again := _make_button("Play Again", Vector2(260, 84), func(): get_tree().reload_current_scene())
	again.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(again)


func _make_button(text: String, min_size: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b


# --- Dynamic content ------------------------------------------------------------------

func _refresh() -> void:
	if _pop_label == null:
		return
	var p: Dictionary = Game.players[Game.PLAYER]
	for r in Game.RESOURCE_TYPES:
		_res_labels[r].text = "%s %d" % [r.capitalize(), p[r]]
	var pop := Game.get_pop(Game.PLAYER)
	var cap := Game.get_pop_cap(Game.PLAYER)
	_pop_label.text = "Pop %d/%d" % [pop, cap]
	_pop_label.modulate = Color(1, 0.55, 0.45) if pop >= cap else Color.WHITE
	var t := int(Game.elapsed)
	_time_label.text = "%d:%02d" % [t / 60, t % 60]
	_refresh_info()
	for b in _actions.get_children():
		if b.has_meta("cost"):
			b.disabled = not Game.can_afford(Game.PLAYER, b.get_meta("cost"))
		if b.has_meta("needs_queue"):
			var bld := Game.selected_own_building()
			b.disabled = bld == null or bld.queue.is_empty()


func _refresh_info() -> void:
	var sel := Game.selected
	if sel.is_empty():
		_title_label.text = "Nothing selected"
		_status_label.text = "Tap a unit or building. Drag to box-select.\nTwo fingers: pan & pinch to zoom."
		return
	if sel.size() == 1:
		var e = sel[0]
		var owner := "" if e.team == Game.PLAYER else " (enemy)"
		_title_label.text = "%s%s" % [e.get_display_name(), owner]
		_status_label.text = "HP %d/%d   %s" % [ceili(e.hp), int(e.max_hp), e.get_status_text()]
		return
	var counts := {}
	for e in sel:
		counts[e.get_display_name()] = counts.get(e.get_display_name(), 0) + 1
	var parts: Array[String] = []
	for k in counts:
		parts.append("%d %s" % [counts[k], k])
	_title_label.text = "%d units" % sel.size()
	_status_label.text = ", ".join(parts)


func _rebuild_actions() -> void:
	for c in _actions.get_children():
		c.queue_free()
	var own := Game.selected_own_units()
	var bld := Game.selected_own_building()
	if not own.is_empty():
		if own.any(func(u): return u.is_villager):
			for t in Game.BUILDABLE:
				var d: Dictionary = Game.BUILDING_DATA[t]
				var b := _make_button("%s\n%s" % [d.name, Game.cost_text(d.cost)], ACTION_SIZE, _start_placement.bind(t))
				b.set_meta("cost", d.cost)
				_actions.add_child(b)
		_actions.add_child(_make_button("Stop", ACTION_SIZE, _stop_selected))
	elif bld != null and bld.constructed:
		for t in bld.data.trains:
			var d: Dictionary = Game.UNIT_DATA[t]
			var b := _make_button("%s\n%s" % [d.name, Game.cost_text(d.cost)], ACTION_SIZE, _train.bind(bld, t))
			b.set_meta("cost", d.cost)
			_actions.add_child(b)
		if not bld.data.trains.is_empty():
			var c := _make_button("Cancel", ACTION_SIZE, func(): bld.cancel_last())
			c.set_meta("needs_queue", true)
			_actions.add_child(c)
	if not Game.selected.is_empty():
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_actions.add_child(spacer)
		_actions.add_child(_make_button("X", Vector2(96, ACTION_SIZE.y), Game.clear_selection))
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
		_placement_label.text = "Tap map to place %s" % Game.BUILDING_DATA[g.type].name
		_placement_ok.disabled = not g.valid


func _on_game_over(winner: int) -> void:
	Game.placement_ghost.cancel()
	_overlay.visible = true
	_overlay_label.text = "VICTORY!" if winner == Game.PLAYER else "DEFEAT"
	_overlay_label.modulate = Color(1, 0.9, 0.3) if winner == Game.PLAYER else Color(1, 0.4, 0.35)
