extends Node
## Global game state (autoload "Game").
##
## Holds the data tables for units and buildings, each player's economy,
## a registry of live entities, the current selection and win/lose state.
## Gameplay nodes talk to each other through this singleton so that the
## scenes in units/, buildings/, map/, ui/ and ai/ stay decoupled.

signal resources_changed
signal selection_changed
signal building_completed(building)
signal game_over(winner: int)
signal notify(text: String)

const TILE := 32
const MAP_SIZE := 64
const PLAYER := 0
const ENEMY := 1
const MAX_POP := 60
const CARRY_CAPACITY := 10
const FAR := 1.0e9

const TEAM_COLORS: Array[Color] = [Color(0.22, 0.52, 0.95), Color(0.9, 0.25, 0.22)]
const TEAM_NAMES: Array[String] = ["Blue", "Red"]
const RESOURCE_TYPES: Array[String] = ["wood", "gold", "stone"]
const RESOURCE_COLORS := {
	"wood": Color(0.55, 0.36, 0.17),
	"gold": Color(1.0, 0.82, 0.2),
	"stone": Color(0.66, 0.66, 0.7),
}
## Resource units gathered per second by one villager.
const GATHER_RATES := {"wood": 0.9, "gold": 0.75, "stone": 0.65}
const RESOURCE_AMOUNTS := {"wood": 100, "gold": 400, "stone": 300}

const UNIT_DATA := {
	"villager": {
		"name": "Villager", "hp": 40.0, "damage": 3.0, "range": 14.0, "cooldown": 1.5,
		"speed": 72.0, "sight": 120.0, "radius": 9.0, "time": 10.0,
		"cost": {"gold": 50}, "building_mult": 1.0,
	},
	"swordsman": {
		"name": "Swordsman", "hp": 90.0, "damage": 9.0, "range": 14.0, "cooldown": 1.2,
		"speed": 76.0, "sight": 170.0, "radius": 10.0, "time": 14.0,
		"cost": {"wood": 20, "gold": 50}, "building_mult": 1.5,
	},
	"archer": {
		"name": "Archer", "hp": 45.0, "damage": 6.0, "range": 150.0, "cooldown": 1.6,
		"speed": 80.0, "sight": 190.0, "radius": 9.0, "time": 14.0,
		"cost": {"wood": 30, "gold": 40}, "ranged": true, "building_mult": 0.5,
	},
}

const BUILDING_DATA := {
	"town_center": {
		"name": "Town Center", "hp": 1500.0, "size": Vector2i(3, 3), "cost": {},
		"build_time": 60.0, "pop": 5, "trains": ["villager"], "dropoff": true,
		"attack": {"damage": 4.0, "range": 190.0, "cooldown": 2.0},
	},
	"house": {
		"name": "House", "hp": 300.0, "size": Vector2i(2, 2), "cost": {"wood": 30},
		"build_time": 15.0, "pop": 5, "trains": [], "dropoff": false,
	},
	"barracks": {
		"name": "Barracks", "hp": 800.0, "size": Vector2i(3, 3), "cost": {"wood": 150, "stone": 50},
		"build_time": 30.0, "pop": 0, "trains": ["swordsman", "archer"], "dropoff": false,
	},
}
## Buildings a villager can construct, in HUD order.
const BUILDABLE: Array[String] = ["house", "barracks"]

var players: Array = []
var units: Array = []
var buildings: Array = []
var resources: Array = []
var selected: Array = []

var map: GameMap
var entities: Node2D
var effects: Node2D
var camera: RTSCamera
var placement_ghost: Node2D

var is_over := false
var winner := -1
var elapsed := 0.0

var _unit_scene: PackedScene
var _building_scene: PackedScene
var _projectile_scene: PackedScene
var _marker_script: Script


func _ready() -> void:
	_unit_scene = load("res://units/unit.tscn")
	_building_scene = load("res://buildings/building.tscn")
	_projectile_scene = load("res://units/projectile.tscn")
	_marker_script = load("res://ui/tap_marker.gd")
	reset()


## Clears all state; called by the main scene when a match starts.
func reset() -> void:
	players.clear()
	for i in 2:
		players.append({"wood": 200, "gold": 100, "stone": 0})
	units.clear()
	buildings.clear()
	resources.clear()
	selected.clear()
	is_over = false
	winner = -1
	elapsed = 0.0


func _physics_process(delta: float) -> void:
	if is_over or map == null:
		return
	elapsed += delta
	_separate_units()


# --- Economy -----------------------------------------------------------------

func can_afford(team: int, cost: Dictionary) -> bool:
	for k in cost:
		if players[team][k] < cost[k]:
			return false
	return true


func spend(team: int, cost: Dictionary) -> bool:
	if not can_afford(team, cost):
		return false
	for k in cost:
		players[team][k] -= cost[k]
	resources_changed.emit()
	return true


func refund(team: int, cost: Dictionary) -> void:
	for k in cost:
		players[team][k] += cost[k]
	resources_changed.emit()


func add_resource(team: int, type: String, amount: int) -> void:
	players[team][type] += amount
	resources_changed.emit()


func cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for k in RESOURCE_TYPES:
		if cost.has(k):
			parts.append("%d %s" % [cost[k], k.substr(0, 1).to_upper()])
	return " ".join(parts)


func missing_text(team: int, cost: Dictionary) -> String:
	for k in RESOURCE_TYPES:
		if cost.has(k) and players[team][k] < cost[k]:
			return "Not enough %s" % k
	return ""


## Population = living units + units waiting in training queues.
func get_pop(team: int) -> int:
	var n := 0
	for u in units:
		if u.team == team and not u.dead:
			n += 1
	for b in buildings:
		if b.team == team and not b.dead:
			n += b.queue.size()
	return n


func get_pop_cap(team: int) -> int:
	var cap := 0
	for b in buildings:
		if b.team == team and not b.dead and b.constructed:
			cap += b.data.pop
	return mini(cap, MAX_POP)


func notify_player(team: int, text: String) -> void:
	if team == PLAYER:
		notify.emit(text)


# --- Spawning ----------------------------------------------------------------

func spawn_unit(type: String, team: int, pos: Vector2) -> Unit:
	var u: Unit = _unit_scene.instantiate()
	u.setup(type, team)
	u.position = pos
	entities.add_child(u)
	return u


func spawn_building(type: String, team: int, cell: Vector2i, complete: bool) -> Building:
	var b: Building = _building_scene.instantiate()
	b.setup(type, team, cell, complete)
	entities.add_child(b)
	return b


## Pays for and lays the foundation of a building. Returns null on failure.
func place_building(team: int, type: String, cell: Vector2i) -> Building:
	var d: Dictionary = BUILDING_DATA[type]
	if not map.is_area_free(cell, d.size):
		notify_player(team, "Can't build there")
		return null
	if not spend(team, d.cost):
		notify_player(team, missing_text(team, d.cost))
		return null
	return spawn_building(type, team, cell, false)


func spawn_projectile(attacker: Entity, target: Entity, damage: float) -> void:
	var p: Node2D = _projectile_scene.instantiate()
	p.setup(attacker, target, damage)
	effects.add_child(p)


func spawn_marker(pos: Vector2, color: Color) -> void:
	if effects == null:
		return
	var m := Node2D.new()
	m.set_script(_marker_script)
	m.position = pos
	m.set("color", color)
	effects.add_child(m)


# --- Registry ----------------------------------------------------------------

func register_unit(u: Unit) -> void:
	units.append(u)


func register_building(b: Building) -> void:
	buildings.append(b)


func on_entity_died(e: Entity) -> void:
	units.erase(e)
	buildings.erase(e)
	if selected.has(e):
		selected.erase(e)
		selection_changed.emit()
	resources_changed.emit()
	if e is Building and e.type == "town_center" and not is_over:
		end_game(PLAYER if e.team == ENEMY else ENEMY)


func end_game(winning_team: int) -> void:
	if is_over:
		return
	is_over = true
	winner = winning_team
	game_over.emit(winning_team)


# --- Queries -----------------------------------------------------------------

func get_town_center(team: int) -> Building:
	for b in buildings:
		if b.team == team and b.type == "town_center" and not b.dead:
			return b
	return null


func find_nearest_enemy(team: int, pos: Vector2, max_dist: float, units_only := false) -> Entity:
	var best: Entity = null
	var best_d := max_dist
	for u in units:
		if u.team != team and not u.dead:
			var d: float = u.position.distance_to(pos) - u.radius
			if d < best_d:
				best_d = d
				best = u
	if best != null or units_only:
		return best
	for b in buildings:
		if b.team != team and not b.dead:
			var d: float = b.distance_to_edge(pos)
			if d < best_d:
				best_d = d
				best = b
	return best


func find_nearest_resource(type: String, pos: Vector2, max_dist := FAR) -> ResourceNode:
	var best: ResourceNode = null
	var best_d := max_dist * max_dist
	for r in resources:
		if r.type == type and not r.dead:
			var d: float = r.position.distance_squared_to(pos)
			if d < best_d:
				best_d = d
				best = r
	return best


func find_nearest_dropoff(team: int, pos: Vector2) -> Building:
	var best: Building = null
	var best_d := FAR
	for b in buildings:
		if b.team == team and not b.dead and b.constructed and b.data.dropoff:
			var d: float = b.distance_to_edge(pos)
			if d < best_d:
				best_d = d
				best = b
	return best


func find_unfinished_building(team: int, pos: Vector2, max_dist: float) -> Building:
	var best: Building = null
	var best_d := max_dist
	for b in buildings:
		if b.team == team and not b.dead and not b.constructed:
			var d: float = b.distance_to_edge(pos)
			if d < best_d:
				best_d = d
				best = b
	return best


## Returns the unit, building or resource under a world position, using a
## generous pick radius so small units are easy to tap with a finger.
func pick_at(pos: Vector2, radius: float) -> Node2D:
	var best: Node2D = null
	var best_d := radius
	for u in units:
		if u.dead:
			continue
		var d: float = u.position.distance_to(pos) - u.radius
		if d < best_d:
			best_d = d
			best = u
	if best != null:
		return best
	var c := map.world_to_cell(pos)
	var occ = map.occupancy.get(c)
	if occ != null:
		return occ
	best_d = radius + TILE * 0.5
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var o = map.occupancy.get(c + Vector2i(dx, dy))
			if o != null:
				var d: float = o.distance_to_edge(pos)
				if d < best_d:
					best_d = d
					best = o
	return best


static func alive(e) -> bool:
	return e != null and is_instance_valid(e) and not e.dead


static func rect_distance(rect: Rect2, p: Vector2) -> float:
	var dx := maxf(maxf(rect.position.x - p.x, 0.0), p.x - rect.end.x)
	var dy := maxf(maxf(rect.position.y - p.y, 0.0), p.y - rect.end.y)
	return sqrt(dx * dx + dy * dy)


# --- Selection ---------------------------------------------------------------

func set_selection(list: Array) -> void:
	for e in selected:
		if alive(e):
			e.selected = false
	selected = []
	for e in list:
		if alive(e):
			e.selected = true
			selected.append(e)
	selection_changed.emit()


func clear_selection() -> void:
	set_selection([])


func selected_own_units() -> Array:
	var out := []
	for e in selected:
		if e is Unit and e.team == PLAYER and not e.dead:
			out.append(e)
	return out


func selected_own_building() -> Building:
	if selected.size() == 1 and selected[0] is Building and selected[0].team == PLAYER:
		return selected[0]
	return null


# --- Unit separation -----------------------------------------------------------

## Gently pushes overlapping units apart using a spatial hash (O(n)).
func _separate_units() -> void:
	var grid := {}
	for u in units:
		var key := Vector2i(floori(u.position.x / TILE), floori(u.position.y / TILE))
		if grid.has(key):
			grid[key].append(u)
		else:
			grid[key] = [u]
	for u in units:
		var key := Vector2i(floori(u.position.x / TILE), floori(u.position.y / TILE))
		var push := Vector2.ZERO
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var bucket = grid.get(key + Vector2i(dx, dy))
				if bucket == null:
					continue
				for o in bucket:
					if o == u:
						continue
					var diff: Vector2 = u.position - o.position
					var min_d: float = (u.radius + o.radius) * 0.9
					var l2 := diff.length_squared()
					if l2 >= min_d * min_d:
						continue
					if l2 < 0.0001:
						diff = Vector2(float(u.get_instance_id() % 7) - 3.0, 1.0)
						l2 = diff.length_squared()
					var l := sqrt(l2)
					push += diff / l * (min_d - l) * 0.5
		if push != Vector2.ZERO:
			var np: Vector2 = u.position + push.limit_length(1.5)
			if map.is_walkable_world(np):
				u.position = np
