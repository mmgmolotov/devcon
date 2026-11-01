class_name Building
extends Entity
## A structure: Town Center, House or Barracks.
##
## Handles construction progress, a training queue, rally point, resource
## drop-off and (for the Town Center) shooting arrows at nearby enemies.

const MAX_QUEUE := 5

var type := "house"
var data: Dictionary = {}
var cell := Vector2i.ZERO
var size := Vector2i(2, 2)
var constructed := true
var build_progress := 0.0
var queue: Array[String] = []
var train_timer := 0.0
var rally_point := Vector2.ZERO
var has_rally := false
var attack_timer := 0.0


func setup(building_type: String, building_team: int, at_cell: Vector2i, complete: bool) -> void:
	type = building_type
	team = building_team
	cell = at_cell
	data = Game.BUILDING_DATA[type]
	size = data.size
	max_hp = data.hp
	constructed = complete
	hp = max_hp if complete else maxf(1.0, max_hp * 0.1)
	position = Game.map.cell_to_world(cell) + Vector2(size) * Game.TILE * 0.5
	Game.map.occupy(cell, size, self)


func _ready() -> void:
	Game.register_building(self)


func get_display_name() -> String:
	return data.name


func get_rect() -> Rect2:
	var s := Vector2(size) * Game.TILE
	return Rect2(position - s * 0.5, s)


func get_radius() -> float:
	return size.x * Game.TILE * 0.5


func distance_to_edge(p: Vector2) -> float:
	return Game.rect_distance(get_rect(), p)


func nearest_point_to(p: Vector2) -> Vector2:
	var r := get_rect()
	return p.clamp(r.position, r.end)


func get_status_text() -> String:
	if not constructed:
		return "Under construction %d%%" % int(build_progress / data.build_time * 100.0)
	if queue.is_empty():
		return "Idle" if not data.trains.is_empty() else ""
	var t: float = Game.UNIT_DATA[queue[0]].time
	var extra := "" if queue.size() == 1 else " (+%d)" % (queue.size() - 1)
	return "Training %s %d%%%s" % [Game.UNIT_DATA[queue[0]].name, int(train_timer / t * 100.0), extra]


# --- Construction ------------------------------------------------------------------

## Called every frame by each villager working on this foundation.
func add_build_work(delta: float) -> void:
	if constructed or dead:
		return
	var bt: float = data.build_time
	build_progress += delta
	hp = minf(max_hp, hp + max_hp * 0.9 * delta / bt)
	if build_progress >= bt:
		_complete()
	queue_redraw()


func _complete() -> void:
	constructed = true
	if hp > max_hp * 0.97:
		hp = max_hp  # absorb float rounding from incremental construction
	queue_redraw()
	Game.building_completed.emit(self)
	Game.resources_changed.emit()
	Game.notify_player(team, "%s complete" % data.name)


# --- Training --------------------------------------------------------------------

## Queues a unit. Returns "" on success or an error message.
func enqueue(unit_type: String) -> String:
	if not constructed:
		return "Still under construction"
	if not data.trains.has(unit_type):
		return "Can't train that here"
	if queue.size() >= MAX_QUEUE:
		return "Queue is full"
	if Game.get_pop(team) + 1 > Game.get_pop_cap(team):
		return "Need more houses" if Game.get_pop_cap(team) < Game.MAX_POP else "Population limit reached"
	var cost: Dictionary = Game.UNIT_DATA[unit_type].cost
	if not Game.spend(team, cost):
		return Game.missing_text(team, cost)
	queue.append(unit_type)
	queue_redraw()
	Game.resources_changed.emit()
	return ""


func cancel_last() -> void:
	if queue.is_empty():
		return
	var t: String = queue.pop_back()
	Game.refund(team, Game.UNIT_DATA[t].cost)
	if queue.is_empty():
		train_timer = 0.0
	queue_redraw()


func set_rally(p: Vector2) -> void:
	rally_point = p
	has_rally = true
	queue_redraw()


func _physics_process(delta: float) -> void:
	if dead or not constructed or Game.is_over:
		return
	if not queue.is_empty():
		train_timer += delta
		if train_timer >= Game.UNIT_DATA[queue[0]].time:
			train_timer = 0.0
			_spawn(queue.pop_front())
		if Engine.get_physics_frames() % 6 == 0:
			queue_redraw()
	if data.has("attack"):
		attack_timer -= delta
		if attack_timer <= 0.0:
			var atk: Dictionary = data.attack
			var e := Game.find_nearest_enemy(team, position, atk.range + get_radius(), true)
			if e != null:
				attack_timer = atk.cooldown
				Game.spawn_projectile(self, e, atk.damage)
			else:
				attack_timer = 0.5


func _spawn(unit_type: String) -> void:
	var toward := rally_point if has_rally else Game.map.get_world_size() * 0.5
	var ring := Game.map.ring_cells(cell, size, toward)
	var pos := position + Vector2(0, get_radius() + 12.0)
	if not ring.is_empty():
		pos = Game.map.cell_center(ring[0])
	var u := Game.spawn_unit(unit_type, team, pos)
	Game.resources_changed.emit()
	if has_rally:
		var occ = Game.map.occupancy.get(Game.map.world_to_cell(rally_point))
		if occ is ResourceNode and u.is_villager:
			u.command_gather(occ)
		else:
			u.command_move(rally_point)


func die() -> void:
	if dead:
		return
	Game.map.free_area(cell, size)
	queue.clear()
	super.die()


# --- Drawing ---------------------------------------------------------------------

func _draw() -> void:
	var half := Vector2(size) * Game.TILE * 0.5
	var r := Rect2(-half + Vector2(3, 3), half * 2.0 - Vector2(6, 6))
	var col: Color = Game.TEAM_COLORS[team]
	var wall := Color(0.8, 0.7, 0.52)
	var dark := Color(0.2, 0.17, 0.14)
	if not constructed:
		_draw_foundation(r, col, dark)
	else:
		draw_rect(Rect2(r.position + Vector2(5, 6), r.size), Color(0, 0, 0, 0.25))
		match type:
			"town_center":
				draw_rect(r, dark)
				draw_rect(r.grow(-2), wall)
				var inner := r.grow(-14)
				draw_rect(inner, dark)
				draw_rect(inner.grow(-2), col)
				draw_rect(Rect2(-9, -9, 18, 18), col.darkened(0.35))
				draw_rect(Rect2(-5, 6, 10, 14), Color(0.35, 0.22, 0.1))
				draw_line(Vector2(-half.x + 10, -half.y + 10), Vector2(-half.x + 10, -half.y - 14), dark, 2.0)
				draw_colored_polygon(PackedVector2Array([
					Vector2(-half.x + 11, -half.y - 14), Vector2(-half.x + 27, -half.y - 9), Vector2(-half.x + 11, -half.y - 4)]), col)
			"house":
				draw_rect(r, dark)
				draw_rect(r.grow(-2), wall)
				draw_colored_polygon(PackedVector2Array([
					r.position + Vector2(-3, r.size.y * 0.5), Vector2(0, r.position.y - 6),
					Vector2(r.end.x + 3, r.position.y + r.size.y * 0.5)]), col.darkened(0.15))
				draw_rect(Rect2(-5, r.end.y - 16, 10, 14), Color(0.35, 0.22, 0.1))
			"barracks":
				draw_rect(r, dark)
				draw_rect(r.grow(-2), wall.darkened(0.15))
				draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, 16)), col.darkened(0.1))
				draw_line(Vector2(-14, -4), Vector2(14, 24), Color(0.85, 0.85, 0.9), 4.0)
				draw_line(Vector2(14, -4), Vector2(-14, 24), Color(0.85, 0.85, 0.9), 4.0)
				draw_line(Vector2(-16, 22), Vector2(-10, 26), Color(0.45, 0.3, 0.15), 4.0)
				draw_line(Vector2(16, 22), Vector2(10, 26), Color(0.45, 0.3, 0.15), 4.0)
	if selected:
		draw_rect(r.grow(3), Color(0.45, 1.0, 0.45), false, 2.0)
		if has_rally and team == Game.PLAYER:
			var rp := rally_point - position
			draw_dashed_line(Vector2.ZERO, rp, Color(1, 1, 1, 0.7), 2.0, 8.0)
			draw_line(rp, rp + Vector2(0, -18), dark, 2.0)
			draw_colored_polygon(PackedVector2Array([rp + Vector2(0, -18), rp + Vector2(12, -14), rp + Vector2(0, -10)]), col)
	var bar_w := r.size.x * 0.8
	if selected or hp < max_hp or not constructed:
		draw_health_bar(bar_w, -half.y - 10.0)
	var prog := -1.0
	if not constructed:
		prog = build_progress / data.build_time
	elif not queue.is_empty():
		prog = train_timer / Game.UNIT_DATA[queue[0]].time
	if prog >= 0.0:
		var pr := Rect2(-bar_w * 0.5, half.y - 12.0, bar_w, 5.0)
		draw_rect(pr.grow(1), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(pr.position, Vector2(bar_w * clampf(prog, 0.0, 1.0), 5.0)), Color(0.35, 0.75, 1.0))


func _draw_foundation(r: Rect2, col: Color, dark: Color) -> void:
	var f := clampf(build_progress / data.build_time, 0.0, 1.0)
	draw_rect(r, Color(0.55, 0.45, 0.3, 0.55))
	draw_rect(r, dark, false, 2.0)
	var h := r.size.y * f
	draw_rect(Rect2(r.position.x, r.end.y - h, r.size.x, h), Color(0.8, 0.7, 0.52, 0.85))
	var step := 16.0
	var x := r.position.x
	while x < r.end.x:
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), Color(0.4, 0.28, 0.14, 0.8), 2.0)
		x += step
	draw_rect(Rect2(r.position, Vector2(r.size.x, 6)), col)
