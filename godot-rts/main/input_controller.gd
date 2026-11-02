extends Node
## Translates touch (and mouse, for desktop testing) into RTS commands.
##
## Touch:  tap = select / command, one-finger drag = box select,
##         two-finger drag = pan, pinch = zoom, double-tap unit = select type.
## Mouse:  left click/drag = same as touch, right drag = pan, wheel = zoom.

const TAP_SLOP := 22.0          ## Screen px a finger may move and still tap.
const PICK_RADIUS := 34.0       ## Screen px around a tap that counts as a hit.
const DOUBLE_TAP_TIME := 0.35
const MOUSE_ID := 1000

@export var camera_path: NodePath
@export var hud_path: NodePath
@export var ghost_path: NodePath

var camera: RTSCamera
var hud: Node
var ghost: Node2D

var _points := {}          # pointer id -> screen position
var _gesture := ""         # "", "tap", "box", "ghost", "multi"
var _press_pos := Vector2.ZERO
var _prev_mid := Vector2.ZERO
var _prev_dist := 0.0
var _right_drag := false
var _last_tap_time := -10.0
var _last_tap_entity = null


func _ready() -> void:
	camera = get_node(camera_path)
	hud = get_node_or_null(hud_path)
	ghost = get_node_or_null(ghost_path)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_pointer_down(event.index, event.position)
		else:
			_pointer_up(event.index, event.position)
	elif event is InputEventScreenDrag:
		_pointer_move(event.index, event.position)
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
		_mouse_button(event)
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		if _right_drag:
			camera.pan_screen(event.relative)
		elif _points.has(MOUSE_ID):
			_pointer_move(MOUSE_ID, event.position)


func _mouse_button(e: InputEventMouseButton) -> void:
	match e.button_index:
		MOUSE_BUTTON_LEFT:
			if e.pressed:
				_pointer_down(MOUSE_ID, e.position)
			else:
				_pointer_up(MOUSE_ID, e.position)
		MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
			_right_drag = e.pressed
		MOUSE_BUTTON_WHEEL_UP:
			if e.pressed:
				camera.zoom_at(1.1, e.position)
		MOUSE_BUTTON_WHEEL_DOWN:
			if e.pressed:
				camera.zoom_at(1.0 / 1.1, e.position)


func _over_ui(p: Vector2) -> bool:
	return hud != null and hud.has_method("is_point_over_ui") and hud.is_point_over_ui(p)


# --- Gesture state machine -------------------------------------------------------

func _pointer_down(id: int, pos: Vector2) -> void:
	if _points.is_empty() and _over_ui(pos):
		return
	_points[id] = pos
	if _points.size() == 1:
		_press_pos = pos
		_gesture = "tap"
	else:
		_gesture = "multi"
		_set_box(Rect2())
		_prev_mid = _midpoint()
		_prev_dist = _spread()


func _pointer_move(id: int, pos: Vector2) -> void:
	if not _points.has(id):
		return
	_points[id] = pos
	match _gesture:
		"tap":
			if pos.distance_to(_press_pos) > TAP_SLOP:
				_gesture = "ghost" if ghost != null and ghost.is_active() else "box"
				_pointer_move(id, pos)
		"box":
			_set_box(Rect2(_press_pos, pos - _press_pos).abs())
		"ghost":
			ghost.set_target(camera.screen_to_world(pos))
		"multi":
			if _points.size() >= 2:
				var mid := _midpoint()
				var dist := _spread()
				camera.pan_screen(mid - _prev_mid)
				if _prev_dist > 10.0 and dist > 10.0:
					camera.zoom_at(dist / _prev_dist, mid)
				_prev_mid = mid
				_prev_dist = dist


func _pointer_up(id: int, pos: Vector2) -> void:
	if not _points.has(id):
		return
	_points.erase(id)
	if _points.is_empty():
		match _gesture:
			"tap":
				handle_tap(pos)
			"box":
				_finish_box(Rect2(_press_pos, pos - _press_pos).abs())
		_gesture = ""
		_set_box(Rect2())
	elif _gesture == "multi" and _points.size() >= 1:
		_prev_mid = _midpoint()
		_prev_dist = _spread()


func _midpoint() -> Vector2:
	var sum := Vector2.ZERO
	for p in _points.values():
		sum += p
	return sum / maxf(1.0, _points.size())


func _spread() -> float:
	var v: Array = _points.values()
	return v[0].distance_to(v[1]) if v.size() >= 2 else 0.0


func _set_box(r: Rect2) -> void:
	if hud != null and hud.has_method("set_selection_box"):
		hud.set_selection_box(r)


# --- Commands --------------------------------------------------------------------

func _finish_box(screen_rect: Rect2) -> void:
	var a := camera.screen_to_world(screen_rect.position)
	var b := camera.screen_to_world(screen_rect.end)
	var world_rect := Rect2(a, b - a)
	var picked := []
	for u in Game.units:
		if u.team == Game.PLAYER and not u.dead and world_rect.grow(u.radius).has_point(u.position):
			picked.append(u)
	Game.set_selection(picked)


## Interprets a tap at a screen position (public so tests can drive it).
func handle_tap(screen_pos: Vector2) -> void:
	if Game.is_over:
		return
	var wp := camera.screen_to_world(screen_pos)
	if ghost != null and ghost.is_active():
		if ghost.contains(wp) and ghost.valid:
			ghost.confirm()
		else:
			ghost.set_target(wp)
		return
	var hit := Game.pick_at(wp, PICK_RADIUS / camera.zoom.x)
	var own := Game.selected_own_units()
	var now := Time.get_ticks_msec() / 1000.0

	if hit is Unit and hit.team == Game.PLAYER and hit.hp < hit.max_hp and own.any(func(u): return u.is_monk) \
			and not hit.selected:
		for u in own:
			if u.is_monk:
				u.command_heal(hit)
		Game.spawn_marker(hit.position, Color(0.5, 1.0, 0.5))
		return
	if hit is Unit and hit.team == Game.PLAYER:
		if now - _last_tap_time < DOUBLE_TAP_TIME and _last_tap_entity == hit:
			_select_type_on_screen(hit.type)
		else:
			Game.set_selection([hit])
		_last_tap_time = now
		_last_tap_entity = hit
		return
	_last_tap_entity = null

	if hit is Building and hit.team == Game.PLAYER:
		if _villagers_work_on(own, hit):
			Game.spawn_marker(hit.position, Color(0.4, 1.0, 0.4))
			return
		Game.set_selection([hit])
		return

	if hit is Entity:  # enemy unit or building
		if own.is_empty():
			Game.set_selection([hit])
		else:
			for u in own:
				u.command_attack(hit)
			Game.spawn_marker(hit.position, Color(1.0, 0.3, 0.25))
		return

	if hit is ResourceNode:
		if not own.is_empty():
			for u in own:
				u.command_gather(hit)
			Game.spawn_marker(hit.position, Color(1.0, 0.9, 0.3))
		return

	# Empty ground.
	if not own.is_empty():
		move_group(own, wp)
		Game.spawn_marker(wp, Color(0.4, 1.0, 0.4))
		return
	var b := Game.selected_own_building()
	if b != null and not b.data.trains.is_empty():
		b.set_rally(wp)
		Game.spawn_marker(wp, Color.WHITE)
		return
	Game.clear_selection()


## Villagers tapped onto an own building: help build it or drop off resources.
func _villagers_work_on(own: Array, b: Building) -> bool:
	var used := false
	for u in own:
		if not u.is_villager:
			continue
		if not b.constructed:
			u.command_build(b)
			used = true
		elif b.data.dropoff.has(u.carry_type) and u.carry_amount > 0:
			u.command_return()
			used = true
	return used


## Moves units to a point in a loose grid formation.
static func move_group(group: Array, wp: Vector2) -> void:
	var n := group.size()
	var cols := ceili(sqrt(float(n)))
	var spacing := 24.0
	var center: Vector2 = group.reduce(func(acc, u): return acc + u.position, Vector2.ZERO) / float(n)
	var sorted := group.duplicate()
	var dir := (wp - center).normalized()
	sorted.sort_custom(func(a, b): return a.position.dot(dir) > b.position.dot(dir))
	for i in n:
		var row := floori(float(i) / cols)
		var col := i % cols
		var off := Vector2(col - (cols - 1) * 0.5, row - (ceili(float(n) / cols) - 1) * 0.5) * spacing
		sorted[i].command_move(wp + off)


func _select_type_on_screen(type: String) -> void:
	var view: Rect2 = camera.visible_world_rect()
	var picked := []
	for u in Game.units:
		if u.team == Game.PLAYER and not u.dead and u.type == type and view.has_point(u.position):
			picked.append(u)
	Game.set_selection(picked)
