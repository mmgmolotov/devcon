class_name Art
extends RefCounted
## Procedural art for a 3/4 top-down medieval look.
##
## Everything is drawn from primitives (no external assets). Units, buildings,
## resources, decals and HUD icons all share these helpers so the style stays
## consistent. Functions never change the canvas transform, so callers can
## scale/flip/rotate with draw_set_transform() before calling them.

const OUTLINE := Color(0.1, 0.08, 0.06)
const SKIN := Color(0.94, 0.77, 0.6)
const WOOD := Color(0.55, 0.36, 0.18)
const WOOD_DARK := Color(0.33, 0.21, 0.1)
const STEEL := Color(0.82, 0.84, 0.88)
const STEEL_DARK := Color(0.45, 0.47, 0.52)
const CLOTH := Color(0.47, 0.35, 0.22)
const PLASTER := Color(0.92, 0.87, 0.75)
const STONE := Color(0.68, 0.66, 0.62)
const STONE_DARK := Color(0.46, 0.44, 0.41)
const THATCH := Color(0.82, 0.66, 0.33)
const ROOF_RED := Color(0.68, 0.3, 0.2)
const GLASS := Color(0.2, 0.25, 0.32)

## Height of each building's front wall (the part drawn above its footprint).
const WALL_HEIGHT := {"house": 20.0, "barracks": 26.0, "town_center": 32.0}


# --- Primitives ----------------------------------------------------------------------

static func ellipse_points(c: Vector2, rx: float, ry: float, n := 14) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.resize(n)
	for i in n:
		var a := TAU * float(i) / float(n)
		pts[i] = c + Vector2(cos(a) * rx, sin(a) * ry)
	return pts


static func ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, n := 14) -> void:
	ci.draw_colored_polygon(ellipse_points(c, rx, ry, n), col)


static func ellipse_outline(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, width := 2.0) -> void:
	var pts := ellipse_points(c, rx, ry, 24)
	pts.append(pts[0])
	ci.draw_polyline(pts, col, width)


static func shadow(ci: CanvasItem, c: Vector2, rx: float, ry: float, alpha := 0.28) -> void:
	ellipse(ci, c, rx, ry, Color(0, 0, 0, alpha))


static func poly(ci: CanvasItem, pts: Array, col: Color, outline := Color(0, 0, 0, 0), width := 1.5) -> void:
	var p := PackedVector2Array(pts)
	ci.draw_colored_polygon(p, col)
	if outline.a > 0.0:
		p.append(p[0])
		ci.draw_polyline(p, outline, width)


static func box(ci: CanvasItem, r: Rect2, col: Color, outline := OUTLINE, width := 1.5) -> void:
	ci.draw_rect(r, col)
	if outline.a > 0.0:
		ci.draw_rect(r, outline, false, width)


static func upper_dome(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 9:
		var a := PI + PI * float(i) / 8.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func flag(ci: CanvasItem, base: Vector2, height: float, team: Color, wave := 0.0) -> void:
	ci.draw_line(base, base + Vector2(0, -height), WOOD_DARK, 2.0)
	var top := base + Vector2(0, -height)
	poly(ci, [top + Vector2(1, 0), top + Vector2(14, 3 + wave), top + Vector2(1, 8)], team, OUTLINE, 1.0)


# --- People ----------------------------------------------------------------------------

## Draws a person whose feet are at (0, 0); about 26 px tall.
## walk: walk-cycle phase (radians). work: 0..1 tool swing, or -1 when resting
## (strike lands at 1.0). tool: "", axe, pick, hammer, sword, bow.
## carry: "", wood, gold or stone (bundle on the back).
static func draw_person(ci: CanvasItem, kind: String, team: Color, facing: float, walk: float,
		work: float, tool: String, carry: String) -> void:
	var f := 1.0 if facing >= 0.0 else -1.0
	var bob := -absf(sin(walk)) * 1.3
	var o := Vector2(0, bob)
	var leg := sin(walk) * 3.2
	var pants := Color(0.3, 0.24, 0.18)
	if kind == "swordsman":
		pants = STEEL_DARK
	var tunic := team
	if kind == "villager":
		tunic = team.lerp(Color(0.62, 0.52, 0.36), 0.35)

	# Legs and feet.
	ci.draw_line(Vector2(-2, -7) + o, Vector2(-2 + leg, -0.5), pants, 2.8)
	ci.draw_line(Vector2(2, -7) + o, Vector2(2 - leg, -0.5), pants, 2.8)
	ci.draw_circle(Vector2(-2 + leg + f * 0.8, -0.3), 1.7, OUTLINE)
	ci.draw_circle(Vector2(2 - leg + f * 0.8, -0.3), 1.7, OUTLINE)

	# Bundle carried on the back.
	var back := Vector2(-5.0 * f, -13.0) + o
	match carry:
		"wood":
			for i in 3:
				var y := -3.0 + i * 2.4
				ci.draw_line(back + Vector2(-4, y), back + Vector2(4, y - 1.0), WOOD, 2.4)
				ci.draw_circle(back + Vector2(4, y - 1.0), 1.2, WOOD.lightened(0.3))
		"gold":
			ellipse(ci, back, 4.0, 4.6, CLOTH)
			ci.draw_circle(back + Vector2(0, -3.5), 2.2, Color(1.0, 0.85, 0.2))
		"stone":
			poly(ci, [back + Vector2(-4, 2), back + Vector2(-3, -3), back + Vector2(2, -4), back + Vector2(4, 1)],
				STONE, OUTLINE, 1.0)

	# Back arm (behind the body).
	var sh_back := Vector2(-3.0 * f, -15.0) + o
	var back_hand := sh_back + Vector2(-sin(walk) * 2.5 * f, 6.5)
	ci.draw_line(sh_back, back_hand, tunic.darkened(0.35), 2.6)

	# Torso.
	var body := [Vector2(-4.5, -16) + o, Vector2(4.5, -16) + o, Vector2(5.8, -6.5) + o, Vector2(-5.8, -6.5) + o]
	if kind == "swordsman":
		poly(ci, body, STEEL_DARK.lightened(0.15), OUTLINE, 1.2)
		poly(ci, [Vector2(-2.5, -16) + o, Vector2(2.5, -16) + o, Vector2(3.2, -6.5) + o, Vector2(-3.2, -6.5) + o], tunic)
	else:
		poly(ci, body, tunic, OUTLINE, 1.2)
	ci.draw_line(Vector2(-5.3, -9) + o, Vector2(5.3, -9) + o, WOOD_DARK, 1.8)

	# Shield (swordsman) in front of the body.
	if kind == "swordsman":
		var sc := Vector2(-2.6 * f, -11.0) + o
		ellipse(ci, sc, 4.8, 6.0, OUTLINE)
		ellipse(ci, sc, 3.9, 5.1, team.darkened(0.1))
		ci.draw_line(sc + Vector2(0, -4.2), sc + Vector2(0, 4.2), team.lightened(0.45), 1.4)
		ci.draw_line(sc + Vector2(-3.2, -0.5), sc + Vector2(3.2, -0.5), team.lightened(0.45), 1.4)
		ci.draw_circle(sc, 1.2, STEEL)

	# Head and headgear.
	var head := Vector2(0.6 * f, -20.0) + o
	ci.draw_circle(head, 4.5, OUTLINE)
	ci.draw_circle(head, 3.7, SKIN)
	ci.draw_circle(head + Vector2(1.9 * f, -0.3), 0.75, OUTLINE)
	match kind:
		"villager":
			ellipse(ci, head + Vector2(0, -2.4), 6.4, 2.0, THATCH.darkened(0.15))
			ellipse(ci, head + Vector2(0, -3.6), 3.4, 2.4, THATCH)
		"swordsman":
			var dome := upper_dome(head + Vector2(0, -0.6), 4.8, 4.8)
			ci.draw_colored_polygon(dome, STEEL)
			dome.append(dome[0])
			ci.draw_polyline(dome, OUTLINE, 1.0)
			ci.draw_line(head + Vector2(1.6 * f, -1.0), head + Vector2(1.6 * f, 2.2), STEEL_DARK, 1.4)
			ci.draw_line(head + Vector2(0, -5.4), head + Vector2(0, -7.4), team, 2.0)
		"archer":
			var hood := upper_dome(head + Vector2(-0.4 * f, -0.3), 5.0, 5.2)
			hood.append(head + Vector2(-5.2 * f, 3.0))
			ci.draw_colored_polygon(hood, Color(0.26, 0.4, 0.2))
			ci.draw_line(head + Vector2(-4.5 * f, -1.0), head + Vector2(-6.5 * f, 4.0), Color(0.2, 0.32, 0.16), 1.6)

	# Front arm + tool. theta: 0 = hanging down, PI/2 = forward, PI = overhead.
	var sh := Vector2(2.6 * f, -15.0) + o
	var theta := 0.35 + sin(walk) * 0.25
	if tool == "bow":
		theta = 1.5 if work >= 0.0 else 0.9
	elif work >= 0.0:
		theta = lerpf(0.5, 2.8, work / 0.7) if work < 0.7 else lerpf(2.8, 0.8, (work - 0.7) / 0.3)
	var dir := Vector2(sin(theta) * f, cos(theta))
	var perp := Vector2(-dir.y, dir.x) * -f
	var hand := sh + dir * 6.0
	ci.draw_line(sh, hand, tunic.darkened(0.15), 2.8)
	match tool:
		"axe":
			var tip := hand + dir * 9.0
			ci.draw_line(hand - dir * 2.0, tip, WOOD, 1.8)
			poly(ci, [tip + perp * 0.5, tip - dir * 4.0 + perp * 0.5, tip - dir * 5.0 + perp * 4.5, tip + dir * 1.0 + perp * 4.5],
				STEEL, OUTLINE, 1.0)
		"pick":
			var tip := hand + dir * 9.0
			ci.draw_line(hand - dir * 2.0, tip, WOOD, 1.8)
			ci.draw_polyline(PackedVector2Array([tip - perp * 5.0 - dir * 2.5, tip, tip + perp * 5.0 - dir * 2.5]), STEEL_DARK, 2.2)
		"hammer":
			var tip := hand + dir * 7.0
			ci.draw_line(hand - dir * 1.5, tip, WOOD, 1.8)
			poly(ci, [tip - perp * 3.0, tip + perp * 3.0, tip + perp * 3.0 + dir * 3.0, tip - perp * 3.0 + dir * 3.0], STEEL_DARK, OUTLINE, 1.0)
		"sword":
			var tip := hand + dir * 13.0
			ci.draw_line(hand + dir * 1.5, tip, STEEL, 2.4)
			ci.draw_line(hand + dir * 1.5, tip, Color(1, 1, 1, 0.5), 0.8)
			ci.draw_line(hand + dir * 1.5 - perp * 2.8, hand + dir * 1.5 + perp * 2.8, WOOD_DARK, 2.0)
		"bow":
			var a := dir.angle()
			ci.draw_arc(hand - dir * 1.5, 8.0, a - 1.25, a + 1.25, 12, WOOD, 2.0)
			var e1 := hand - dir * 1.5 + Vector2.from_angle(a - 1.25) * 8.0
			var e2 := hand - dir * 1.5 + Vector2.from_angle(a + 1.25) * 8.0
			var pull := clampf(work, 0.0, 1.0) * 5.0
			var mid := (e1 + e2) * 0.5 - dir * pull
			ci.draw_polyline(PackedVector2Array([e1, mid, e2]), Color(0.9, 0.9, 0.85), 0.9)
			if work >= 0.0 and work < 0.95:
				ci.draw_line(mid, mid + dir * 11.0, WOOD.lightened(0.2), 1.3)
	ci.draw_circle(hand, 1.6, SKIN)


# --- Buildings -------------------------------------------------------------------------

## Draws a building centred on its footprint. size = footprint in pixels.
## progress < 1 draws the construction stages.
static func draw_building(ci: CanvasItem, type: String, team: Color, size: Vector2, progress := 1.0) -> void:
	var r := Rect2(-size * 0.5 + Vector2(3, 3), size - Vector2(6, 6))
	var h: float = WALL_HEIGHT.get(type, 22.0)
	if progress < 1.0:
		_draw_construction(ci, r, h, progress, team)
		return
	ci.draw_rect(Rect2(r.position + Vector2(10, 6), r.size), Color(0, 0, 0, 0.22))
	match type:
		"house":
			_draw_house(ci, r, h, team)
		"barracks":
			_draw_barracks(ci, r, h, team)
		"town_center":
			_draw_town_center(ci, r, h, team)


static func chimney_offset(type: String, size: Vector2) -> Vector2:
	if type == "house":
		return Vector2(size.x * 0.5 - 17.0, -size.y * 0.5 - WALL_HEIGHT.house - 4.0)
	return Vector2(INF, INF)


## Gable roof with the ridge running east-west, drawn above the footprint.
static func _gable_roof(ci: CanvasItem, r: Rect2, h: float, col: Color, overhang: float, tiles: bool) -> float:
	var x0 := r.position.x - overhang
	var x1 := r.end.x + overhang
	var y_back := r.position.y - h + 4.0
	var y_front := r.end.y - h + 1.0
	var y_ridge := (y_back + y_front) * 0.5 - 10.0
	poly(ci, [Vector2(x0 + 3, y_back), Vector2(x1 - 3, y_back), Vector2(x1 - 1, y_ridge), Vector2(x0 + 1, y_ridge)],
		col.lightened(0.18), OUTLINE, 1.5)
	poly(ci, [Vector2(x0 + 1, y_ridge), Vector2(x1 - 1, y_ridge), Vector2(x1 + 2, y_front), Vector2(x0 - 2, y_front)],
		col, OUTLINE, 1.5)
	var rows := 5
	for i in range(1, rows):
		var t := float(i) / rows
		var y := lerpf(y_ridge, y_front, t)
		var xa := lerpf(x0 + 1, x0 - 2, t)
		var xb := lerpf(x1 - 1, x1 + 2, t)
		ci.draw_line(Vector2(xa, y), Vector2(xb, y), col.darkened(0.25), 1.2)
		if tiles:
			var x := xa + 6.0 * (i % 2)
			while x < xb:
				ci.draw_line(Vector2(x, y), Vector2(x, y - (y_front - y_ridge) / rows), col.darkened(0.2), 1.0)
				x += 12.0
	ci.draw_line(Vector2(x0 + 1, y_ridge), Vector2(x1 - 1, y_ridge), col.darkened(0.45), 2.5)
	return y_ridge


static func _draw_house(ci: CanvasItem, r: Rect2, h: float, team: Color) -> void:
	ci.draw_rect(Rect2(r.position.x, r.end.y - 4, r.size.x, 4), STONE_DARK)
	var wall := Rect2(r.position.x + 2, r.end.y - h - 3, r.size.x - 4, h)
	box(ci, wall, PLASTER)
	for i in 4:
		var x := wall.position.x + wall.size.x * i / 3.0
		ci.draw_line(Vector2(x, wall.position.y), Vector2(x, wall.end.y), WOOD_DARK, 2.0)
	ci.draw_line(Vector2(wall.position.x, wall.position.y + 1), Vector2(wall.end.x, wall.position.y + 1), WOOD_DARK, 2.0)
	ci.draw_line(Vector2(wall.position.x, wall.end.y - h * 0.45), Vector2(wall.position.x + wall.size.x / 3.0, wall.end.y), WOOD_DARK, 1.6)
	ci.draw_line(Vector2(wall.end.x, wall.end.y - h * 0.45), Vector2(wall.end.x - wall.size.x / 3.0, wall.end.y), WOOD_DARK, 1.6)
	box(ci, Rect2(-4.5, wall.end.y - 13, 9, 13), WOOD_DARK, OUTLINE, 1.0)
	ci.draw_circle(Vector2(2.5, wall.end.y - 6), 0.9, STEEL)
	for side: float in [-1.0, 1.0]:
		var wx := wall.get_center().x + side * wall.size.x * 0.33 - 3.5
		box(ci, Rect2(wx, wall.position.y + 5, 7, 6), GLASS, OUTLINE, 1.0)
		ci.draw_rect(Rect2(wx - 2.5, wall.position.y + 5, 2.5, 6), team.darkened(0.1))
		ci.draw_rect(Rect2(wx + 7, wall.position.y + 5, 2.5, 6), team.darkened(0.1))
	box(ci, Rect2(r.end.x - 20, r.position.y - h - 6, 7, 14), STONE, OUTLINE, 1.0)
	_gable_roof(ci, r, h, THATCH, 4.0, false)
	ci.draw_line(Vector2(r.position.x - 6, r.end.y - h + 1), Vector2(r.end.x + 6, r.end.y - h + 1), team, 3.0)
	var ridge_y := (r.position.y - h + 4.0 + r.end.y - h + 1.0) * 0.5 - 10.0
	flag(ci, Vector2(r.position.x + 4, ridge_y), 12.0, team)


static func _draw_barracks(ci: CanvasItem, r: Rect2, h: float, team: Color) -> void:
	var wall := Rect2(r.position.x + 2, r.end.y - h - 2, r.size.x - 4, h)
	box(ci, wall, WOOD.lightened(0.1))
	var x := wall.position.x + 6.0
	while x < wall.end.x:
		ci.draw_line(Vector2(x, wall.position.y), Vector2(x, wall.end.y), WOOD_DARK.lightened(0.1), 1.0)
		x += 6.0
	var base := Rect2(wall.position.x, wall.end.y - 8, wall.size.x, 8)
	box(ci, base, STONE, OUTLINE, 1.0)
	x = base.position.x + 8.0
	while x < base.end.x:
		ci.draw_line(Vector2(x, base.position.y), Vector2(x, base.end.y), STONE_DARK, 1.0)
		x += 10.0
	box(ci, Rect2(-10, wall.end.y - 18, 20, 18), WOOD_DARK, OUTLINE, 1.2)
	ci.draw_line(Vector2(0, wall.end.y - 18), Vector2(0, wall.end.y), OUTLINE, 1.2)
	for side: float in [-1.0, 1.0]:
		box(ci, Rect2(side * 26.0 - 4.0, wall.position.y + 5, 8, 7), GLASS, OUTLINE, 1.0)
	var y_ridge := _gable_roof(ci, r, h, ROOF_RED, 5.0, true)
	# Shield emblem with crossed swords above the door.
	var e := Vector2(0, wall.position.y + 1)
	ci.draw_line(e + Vector2(-9, -9), e + Vector2(9, 9), STEEL, 2.2)
	ci.draw_line(e + Vector2(9, -9), e + Vector2(-9, 9), STEEL, 2.2)
	ellipse(ci, e, 6.0, 7.0, OUTLINE)
	ellipse(ci, e, 5.0, 6.0, team)
	# Weapon rack by the left wall and a banner on the right.
	for i in 3:
		var sx := r.position.x + 4.0 + i * 4.0
		ci.draw_line(Vector2(sx, r.end.y), Vector2(sx + 3, r.end.y - 30), WOOD_DARK, 1.6)
		poly(ci, [Vector2(sx + 3, r.end.y - 34), Vector2(sx + 1.5, r.end.y - 29), Vector2(sx + 4.5, r.end.y - 29)], STEEL)
	ci.draw_line(Vector2(r.position.x + 2, r.end.y - 16), Vector2(r.position.x + 16, r.end.y - 16), WOOD_DARK, 2.0)
	flag(ci, Vector2(r.end.x - 4, y_ridge + 2), 16.0, team, 1.0)


static func _stone_wall(ci: CanvasItem, wall: Rect2, col: Color) -> void:
	box(ci, wall, col)
	var row := 0
	var y := wall.position.y + 6.0
	while y < wall.end.y:
		ci.draw_line(Vector2(wall.position.x, y), Vector2(wall.end.x, y), col.darkened(0.25), 1.0)
		var x := wall.position.x + (6.0 if row % 2 == 0 else 12.0)
		while x < wall.end.x:
			ci.draw_line(Vector2(x, y - 6.0), Vector2(x, y), col.darkened(0.25), 1.0)
			x += 12.0
		y += 6.0
		row += 1


static func _tower(ci: CanvasItem, base: Vector2, w: float, h: float, team: Color) -> void:
	var body := Rect2(base.x - w * 0.5, base.y - h, w, h)
	_stone_wall(ci, body, STONE.darkened(0.05))
	ellipse(ci, Vector2(base.x, base.y - h), w * 0.5 + 1.0, w * 0.22, STONE_DARK)
	poly(ci, [Vector2(base.x - w * 0.5 - 3, base.y - h), Vector2(base.x + w * 0.5 + 3, base.y - h), Vector2(base.x, base.y - h - w * 1.1)],
		team.darkened(0.2), OUTLINE, 1.2)
	box(ci, Rect2(base.x - 1.5, base.y - h * 0.6, 3, 6), GLASS, OUTLINE, 1.0)


static func _draw_town_center(ci: CanvasItem, r: Rect2, h: float, team: Color) -> void:
	# Roof terrace (top surface of the outer wall block).
	var top := Rect2(r.position.x, r.position.y - h, r.size.x, r.size.y)
	box(ci, top, STONE.lightened(0.12))
	ci.draw_rect(top.grow(-6), Color(0.6, 0.55, 0.45))
	# Central keep.
	var keep := Rect2(-20, top.get_center().y - 18, 40, 30)
	var kh := 24.0
	box(ci, Rect2(keep.position.x, keep.position.y - kh, keep.size.x, keep.size.y), STONE.lightened(0.05))
	_stone_wall(ci, Rect2(keep.position.x, keep.end.y - kh, keep.size.x, kh), STONE)
	box(ci, Rect2(-3, keep.end.y - kh + 6, 6, 9), GLASS, OUTLINE, 1.0)
	var kt := keep.position.y - kh
	poly(ci, [Vector2(keep.position.x - 4, keep.end.y - kh), Vector2(keep.end.x + 4, keep.end.y - kh),
		Vector2(keep.end.x - 6, kt + 2), Vector2(keep.position.x + 6, kt + 2)], ROOF_RED, OUTLINE, 1.5)
	poly(ci, [Vector2(keep.position.x + 6, kt + 2), Vector2(keep.end.x - 6, kt + 2), Vector2(0, kt - 14)],
		ROOF_RED.lightened(0.15), OUTLINE, 1.5)
	flag(ci, Vector2(0, kt - 14), 16.0, team, 1.5)
	# Front wall with battlements, gate and banners.
	var wall := Rect2(r.position.x, r.end.y - h, r.size.x, h)
	_stone_wall(ci, wall, STONE)
	var mx := wall.position.x
	while mx < wall.end.x - 4:
		box(ci, Rect2(mx, wall.position.y - 5, 6, 5), STONE.lightened(0.05), OUTLINE, 1.0)
		mx += 10.0
	var gate := Rect2(-10, wall.end.y - 20, 20, 20)
	ci.draw_rect(gate, WOOD_DARK)
	ellipse(ci, Vector2(0, gate.position.y), 10.0, 6.0, WOOD_DARK)
	for gy in [gate.position.y + 5, gate.position.y + 13]:
		ci.draw_line(Vector2(-10, gy), Vector2(10, gy), STEEL_DARK, 1.6)
	ci.draw_line(Vector2(0, gate.position.y - 5), Vector2(0, gate.end.y), OUTLINE, 1.0)
	for side: float in [-1.0, 1.0]:
		var bx := side * 24.0
		poly(ci, [Vector2(bx - 5, wall.position.y + 3), Vector2(bx + 5, wall.position.y + 3),
			Vector2(bx + 5, wall.position.y + 22), Vector2(bx, wall.position.y + 18), Vector2(bx - 5, wall.position.y + 22)],
			team, OUTLINE, 1.0)
		ci.draw_circle(Vector2(bx, wall.position.y + 10), 2.2, Color(1.0, 0.85, 0.3))
	_tower(ci, Vector2(r.position.x + 7, r.end.y), 16.0, h + 12.0, team)
	_tower(ci, Vector2(r.end.x - 7, r.end.y), 16.0, h + 12.0, team)


static func _draw_construction(ci: CanvasItem, r: Rect2, h: float, p: float, team: Color) -> void:
	ci.draw_rect(r, Color(0.5, 0.4, 0.26, 0.85))
	ci.draw_rect(r, STONE_DARK, false, 3.0)
	if p < 0.35:
		for c in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
			ci.draw_line(c, c + Vector2(0, -10), WOOD, 2.5)
		for i in 3:
			ci.draw_line(Vector2(-14, 6 - i * 3.0), Vector2(2, 4 - i * 3.0), WOOD, 3.0)
		ellipse(ci, Vector2(12, 6), 6.0, 4.0, STONE)
		ellipse(ci, Vector2(16, 3), 4.0, 3.0, STONE.lightened(0.1))
	else:
		var wh := h * clampf((p - 0.35) / 0.35, 0.15, 1.0)
		var wall := Rect2(r.position.x + 2, r.end.y - wh - 2, r.size.x - 4, wh)
		box(ci, wall, PLASTER.darkened(0.08))
		var x := wall.position.x
		while x <= wall.end.x + 0.1:
			ci.draw_line(Vector2(x, r.end.y), Vector2(x, r.end.y - h - 10), WOOD, 2.0)
			x += wall.size.x / 3.0
		for y in [r.end.y - h * 0.5, r.end.y - h - 4]:
			ci.draw_line(Vector2(r.position.x - 2, y), Vector2(r.end.x + 2, y), WOOD_DARK, 2.5)
		if p > 0.7:
			var y_front := r.end.y - h + 1.0
			var y_ridge := (r.position.y - h + 4.0 + y_front) * 0.5 - 10.0
			ci.draw_line(Vector2(r.position.x, y_ridge), Vector2(r.end.x, y_ridge), WOOD_DARK, 2.5)
			var n := 6
			for i in n + 1:
				var rx := lerpf(r.position.x, r.end.x, float(i) / n)
				ci.draw_line(Vector2(rx, y_ridge), Vector2(rx, y_front), WOOD, 1.6)
	ci.draw_rect(Rect2(r.position.x, r.position.y, 10, 6), team)


static func draw_rubble(ci: CanvasItem, size: Vector2, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var r := Rect2(-size * 0.5 + Vector2(4, 4), size - Vector2(8, 8))
	ci.draw_rect(r, Color(0.25, 0.2, 0.16, 0.55))
	for i in int(size.x * size.y / 220.0):
		var p := Vector2(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y, r.end.y))
		var s := rng.randf_range(3.0, 7.0)
		var c := STONE_DARK if rng.randf() < 0.6 else WOOD_DARK
		ellipse(ci, p, s, s * 0.7, c.darkened(rng.randf_range(0.0, 0.3)), 8)
	for i in 4:
		var p := Vector2(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y, r.end.y))
		ci.draw_line(p, p + Vector2(rng.randf_range(-14, 14), rng.randf_range(-6, 6)), Color(0.15, 0.1, 0.06), 3.0)


# --- Resources ----------------------------------------------------------------------------

static func draw_tree(ci: CanvasItem, rng: RandomNumberGenerator) -> void:
	var pine := rng.randf() < 0.4
	var j := Vector2(rng.randf_range(-3, 3), rng.randf_range(-2, 2))
	shadow(ci, Vector2(5, 9) + j, 14.0, 6.0, 0.3)
	poly(ci, [Vector2(-2.6, 10) + j, Vector2(2.6, 10) + j, Vector2(1.8, -6) + j, Vector2(-1.8, -6) + j], WOOD, OUTLINE, 1.0)
	if pine:
		var g := Color(0.12, 0.33, 0.2).lightened(rng.randf_range(0.0, 0.1))
		for i in 3:
			var y := 2.0 - i * 10.0
			var w := 15.0 - i * 3.5
			poly(ci, [Vector2(-w, y) + j, Vector2(w, y) + j, Vector2(0, y - 16) + j], g.darkened(0.15), OUTLINE, 1.0)
			poly(ci, [Vector2(-w + 3, y - 1) + j, Vector2(0, y - 1) + j, Vector2(0, y - 14) + j], g.lightened(0.12))
	else:
		var g := Color(0.2, 0.45, 0.17).lightened(rng.randf_range(-0.05, 0.1))
		ellipse(ci, Vector2(0, -12) + j, 15.0, 13.0, OUTLINE, 16)
		ellipse(ci, Vector2(0, -12) + j, 14.0, 12.0, g.darkened(0.3), 16)
		for i in 4:
			var p := Vector2(rng.randf_range(-7, 7), rng.randf_range(-19, -9)) + j
			ci.draw_circle(p, rng.randf_range(5.5, 7.5), g)
		ci.draw_circle(Vector2(-4, -18) + j, 4.5, g.lightened(0.15))
		ci.draw_circle(Vector2(-6, -20) + j, 2.2, g.lightened(0.3))


static func draw_rocks(ci: CanvasItem, rng: RandomNumberGenerator, gold: bool) -> void:
	shadow(ci, Vector2(3, 8), 16.0, 7.0, 0.3)
	var base := Color(0.5, 0.45, 0.37) if gold else STONE
	var pts: Array[Vector2] = []
	for i in 3:
		pts.append(Vector2(rng.randf_range(-7, 7), rng.randf_range(-4, 5)))
	pts.sort_custom(func(a, b): return a.y < b.y)
	for p in pts:
		var rx := rng.randf_range(7.5, 10.0)
		var ry := rx * 0.8
		ellipse(ci, p, rx + 1.0, ry + 1.0, OUTLINE, 12)
		ellipse(ci, p, rx, ry, base.darkened(0.25), 12)
		ellipse(ci, p + Vector2(-1.2, -2.0), rx - 2.5, ry - 2.5, base, 12)
		ellipse(ci, p + Vector2(-2.5, -3.5), rx * 0.35, ry * 0.25, base.lightened(0.25), 8)
		if gold:
			for k in 3:
				var q := p + Vector2(rng.randf_range(-4.5, 4.5), rng.randf_range(-3.5, 3.0))
				ci.draw_circle(q, rng.randf_range(1.5, 2.6), Color(1.0, 0.8, 0.15))
				ci.draw_circle(q + Vector2(-0.6, -0.6), 0.9, Color(1.0, 0.97, 0.7))
		else:
			ci.draw_line(p + Vector2(-3, -1), p + Vector2(1, 2), base.darkened(0.4), 1.0)
	if gold:
		var s := Vector2(rng.randf_range(-6, 6), rng.randf_range(-8, -2))
		ci.draw_line(s + Vector2(-3, 0), s + Vector2(3, 0), Color(1, 1, 0.8), 1.0)
		ci.draw_line(s + Vector2(0, -3), s + Vector2(0, 3), Color(1, 1, 0.8), 1.0)


static func draw_stump(ci: CanvasItem) -> void:
	shadow(ci, Vector2(2, 4), 7.0, 3.0, 0.25)
	ci.draw_rect(Rect2(-4, -3, 8, 6), WOOD)
	ellipse(ci, Vector2(0, -3), 4.0, 2.0, WOOD.lightened(0.3))
	ellipse_outline(ci, Vector2(0, -3), 2.0, 1.0, WOOD, 0.8)


## Small icon for HUD resource counters, centred at c and about s pixels wide.
static func draw_resource_icon(ci: CanvasItem, type: String, c: Vector2, s: float) -> void:
	var k := s / 24.0
	match type:
		"wood":
			for p in [Vector2(-5, 4), Vector2(5, 4), Vector2(0, -4)]:
				ci.draw_circle(c + p * k, 5.2 * k, OUTLINE)
				ci.draw_circle(c + p * k, 4.4 * k, WOOD.lightened(0.25))
				ci.draw_arc(c + p * k, 2.2 * k, 0.0, TAU, 10, WOOD, 1.0)
		"gold":
			for p in [Vector2(-4, 4), Vector2(4, 4), Vector2(0, -3)]:
				ellipse(ci, c + p * k, 6.0 * k, 4.6 * k, OUTLINE)
				ellipse(ci, c + p * k, 5.2 * k, 3.8 * k, Color(1.0, 0.8, 0.2))
				ellipse(ci, c + (p + Vector2(-1.5, -1)) * k, 2.0 * k, 1.2 * k, Color(1, 0.97, 0.7))
		"stone":
			for p in [Vector2(-5, 4), Vector2(5, 3), Vector2(0, -4)]:
				ellipse(ci, c + p * k, 6.2 * k, 5.0 * k, OUTLINE)
				ellipse(ci, c + p * k, 5.4 * k, 4.2 * k, STONE)
				ellipse(ci, c + (p + Vector2(-1.5, -1.5)) * k, 2.2 * k, 1.4 * k, STONE.lightened(0.3))
		"pop":
			ci.draw_circle(c + Vector2(0, -5) * k, 4.5 * k, OUTLINE)
			ci.draw_circle(c + Vector2(0, -5) * k, 3.7 * k, SKIN)
			poly(ci, [c + Vector2(-7, 9) * k, c + Vector2(7, 9) * k, c + Vector2(4, 0) * k, c + Vector2(-4, 0) * k],
				Color(0.4, 0.55, 0.85), OUTLINE, 1.0)
