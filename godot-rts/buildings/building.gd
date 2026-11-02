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
var _fx_timer := 0.0


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
	Game.map.occupy(cell, size, self, not data.get("walkable", false))


var _sails: Node2D


## Rotating windmill sails (a child node, so the building art stays cached).
class Sails extends Node2D:
	func _draw() -> void:
		Art.draw_mill_sails(self, Vector2.ZERO, 0.0)


func _ready() -> void:
	Game.register_building(self)
	if type == "mill":
		_sails = Sails.new()
		_sails.position = Vector2(0, -Vector2(size).y * Game.TILE * 0.5 + 3.0 - Art.WALL_HEIGHT.mill + 2.0)
		_sails.visible = constructed
		add_child(_sails)


func get_display_name() -> String:
	return data.name


func get_rect() -> Rect2:
	var s := Vector2(size) * Game.TILE
	return Rect2(position - s * 0.5, s)


## Footprint plus the part of the art that rises above it (for tapping).
func get_visual_rect() -> Rect2:
	var r := get_rect()
	var up: float = Art.WALL_HEIGHT.get(type, 22.0) + 18.0
	return Rect2(r.position - Vector2(0, up), r.size + Vector2(0, up))


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
	if type == "farm":
		_become_field()
		return
	constructed = true
	if _sails != null:
		_sails.visible = true
	if hp > max_hp * 0.97:
		hp = max_hp  # absorb float rounding from incremental construction
	queue_redraw()
	Game.building_completed.emit(self)
	Game.resources_changed.emit()
	Game.notify_player(team, "%s complete" % data.name)
	if team == Game.PLAYER:
		Sound.play("complete")


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


## A finished farm turns into a walkable food field that villagers work.
func _become_field() -> void:
	var builders := Game.units.filter(func(u): return u.team == team and u.state == Unit.State.BUILD and u.target == self)
	dead = true
	Game.on_entity_died(self)
	Game.map.free_area(cell, size)
	var field := Game.map.add_resource_node("farm", cell, size)
	field.team = team
	Game.notify_player(team, "Farm ready")
	for u in builders:
		u.command_gather(field)
	queue_free()


func _process(delta: float) -> void:
	if _sails != null and constructed and visible:
		_sails.rotation += delta * 0.9


func _physics_process(delta: float) -> void:
	if dead or not constructed or Game.is_over:
		return
	_fx_timer -= delta
	if _fx_timer <= 0.0:
		_fx_timer = 0.18
		_emit_ambient()
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
				Sound.play("arrow", position, -8.0)
			else:
				attack_timer = 0.5


func _spawn(unit_type: String) -> void:
	var toward := rally_point if has_rally else Game.map.get_world_size() * 0.5
	var ring := Game.map.ring_cells(cell, size, toward)
	var pos := position + Vector2(0, get_radius() + 12.0)
	if not ring.is_empty():
		pos = Game.map.cell_center(ring[0])
	var u := Game.spawn_unit(unit_type, team, pos)
	if team == Game.PLAYER:
		Sound.play("confirm", null, -6.0)
	Game.resources_changed.emit()
	if has_rally:
		var occ = Game.map.occupancy.get(Game.map.world_to_cell(rally_point))
		if occ is ResourceNode and u.is_villager:
			u.command_gather(occ)
		else:
			u.command_move(rally_point)


## Chimney smoke, and fire/smoke on damaged buildings.
func _emit_ambient() -> void:
	if not visible:
		return
	var s := Vector2(size) * Game.TILE
	var top := position + Vector2(0, -s.y * 0.5 - Art.WALL_HEIGHT.get(type, 22.0) * 0.5)
	var f := hp / max_hp
	if f < 0.66:
		var spots := 1 if f > 0.33 else 3
		for i in spots:
			var p := top + Vector2(randf_range(-0.35, 0.35) * s.x, randf_range(-0.2, 0.4) * s.y)
			Game.emit_fx("fire", p, 2)
			if randf() < 0.4:
				Game.emit_fx("smoke", p + Vector2(0, -10), 1)
	var chimney := Art.chimney_offset(type, s)
	if chimney.x < INF and randf() < 0.35:
		Game.emit_fx("smoke", position + chimney, 1)


func die() -> void:
	if dead:
		return
	var s := Vector2(size) * Game.TILE
	Game.spawn_decal("rubble", position, {"size": s, "life": 30.0})
	Game.emit_fx("debris", position, 18)
	Sound.play("collapse", position)
	Game.emit_fx("dust", position, 14)
	Game.map.free_area(cell, size)
	queue.clear()
	super.die()


# --- Drawing ---------------------------------------------------------------------

func _draw() -> void:
	var s := Vector2(size) * Game.TILE
	var half := s * 0.5
	var col: Color = Game.TEAM_COLORS[team]
	var wall_h: float = Art.WALL_HEIGHT.get(type, 22.0)
	if selected:
		Art.ellipse_outline(self, Vector2.ZERO, half.x + 6.0, half.y + 4.0, Color(0.45, 1.0, 0.45), 2.0)
	var progress: float = 1.0 if constructed else build_progress / data.build_time
	Art.draw_building(self, type, col, s, progress, _sails != null)
	if selected and has_rally and team == Game.PLAYER:
		var rp := rally_point - position
		draw_dashed_line(Vector2.ZERO, rp, Color(1, 1, 1, 0.7), 2.0, 8.0)
		Art.flag(self, rp, 18.0, col)
	var top_y := -half.y - wall_h - 22.0
	var bar_w := s.x * 0.7
	if selected or hp < max_hp or not constructed:
		draw_health_bar(bar_w, top_y)
	var prog := -1.0
	if not constructed:
		prog = progress
	elif not queue.is_empty():
		prog = train_timer / Game.UNIT_DATA[queue[0]].time
	if prog >= 0.0:
		var pr := Rect2(-bar_w * 0.5, top_y + 7.0, bar_w, 4.0)
		draw_rect(pr.grow(1), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(pr.position, Vector2(bar_w * clampf(prog, 0.0, 1.0), 4.0)), Color(0.35, 0.75, 1.0))
