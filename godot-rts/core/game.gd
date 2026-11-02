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

const GAIA := 2  ## Neutral team for wild and farm animals.

const TEAM_COLORS: Array[Color] = [Color(0.22, 0.52, 0.95), Color(0.9, 0.25, 0.22), Color(0.75, 0.7, 0.55)]
const TEAM_NAMES: Array[String] = ["Blue", "Red", "Nature"]
const SPRITE_TEAMS: Array[String] = ["blue", "red", "blue"]
const RESOURCE_TYPES: Array[String] = ["food", "wood", "gold", "stone"]
const RESOURCE_COLORS := {
	"food": Color(0.86, 0.3, 0.26),
	"wood": Color(0.55, 0.36, 0.17),
	"gold": Color(1.0, 0.82, 0.2),
	"stone": Color(0.66, 0.66, 0.7),
}
## Resource units gathered per second by one villager (before node multipliers).
const GATHER_RATES := {"food": 0.85, "wood": 0.9, "gold": 0.75, "stone": 0.65}
const START_RESOURCES := {"food": 200, "wood": 200, "gold": 100, "stone": 0}

const UNIT_DATA := {
	"villager": {
		"name": "Villager", "hp": 40.0, "damage": 3.0, "range": 14.0, "cooldown": 1.5,
		"speed": 72.0, "sight": 120.0, "radius": 10.0, "time": 10.0,
		"cost": {"food": 50}, "building_mult": 0.5,
	},
	"swordsman": {
		"name": "Swordsman", "hp": 90.0, "damage": 9.0, "range": 14.0, "cooldown": 1.2,
		"speed": 76.0, "sight": 170.0, "radius": 11.0, "time": 14.0,
		"cost": {"food": 60, "gold": 20}, "building_mult": 1.0,
	},
	"spearman": {
		"name": "Spearman", "hp": 70.0, "damage": 7.0, "range": 24.0, "cooldown": 1.3,
		"speed": 78.0, "sight": 170.0, "radius": 11.0, "time": 12.0,
		"cost": {"food": 35, "wood": 25}, "building_mult": 0.5, "bonus": {"knight": 3.0},
	},
	"archer": {
		"name": "Archer", "hp": 45.0, "damage": 6.0, "range": 150.0, "cooldown": 1.6,
		"speed": 80.0, "sight": 190.0, "radius": 10.0, "time": 14.0,
		"cost": {"wood": 30, "gold": 40}, "ranged": true, "building_mult": 0.3,
	},
	"axeman": {
		"name": "Axeman", "hp": 80.0, "damage": 11.0, "range": 14.0, "cooldown": 1.3,
		"speed": 74.0, "sight": 170.0, "radius": 11.0, "time": 14.0,
		"cost": {"food": 50, "wood": 30}, "building_mult": 1.6,
	},
	"crossbowman": {
		"name": "Crossbowman", "hp": 55.0, "damage": 10.0, "range": 170.0, "cooldown": 2.4,
		"speed": 72.0, "sight": 200.0, "radius": 10.0, "time": 16.0,
		"cost": {"wood": 35, "gold": 50}, "ranged": true, "building_mult": 0.4,
	},
	"ram": {
		"name": "Battering Ram", "hp": 260.0, "damage": 40.0, "range": 14.0, "cooldown": 2.5,
		"speed": 40.0, "sight": 170.0, "radius": 16.0, "time": 25.0,
		"cost": {"wood": 160, "gold": 75}, "building_mult": 1.0, "machine": "ram", "buildings_only": true,
	},
	"catapult": {
		"name": "Catapult", "hp": 120.0, "damage": 30.0, "range": 270.0, "cooldown": 4.5,
		"speed": 36.0, "sight": 290.0, "radius": 15.0, "time": 30.0,
		"cost": {"wood": 200, "gold": 150}, "ranged": true, "building_mult": 2.0, "machine": "catapult",
		"splash": 45.0,
	},
	"knight": {
		"name": "Knight", "hp": 160.0, "damage": 13.0, "range": 14.0, "cooldown": 1.5,
		"speed": 64.0, "sight": 180.0, "radius": 12.0, "time": 20.0,
		"cost": {"food": 80, "gold": 75}, "building_mult": 0.8,
	},
	"monk": {
		"name": "Monk", "hp": 40.0, "damage": 0.0, "range": 70.0, "cooldown": 1.0,
		"speed": 60.0, "sight": 190.0, "radius": 10.0, "time": 20.0,
		"cost": {"gold": 100}, "building_mult": 0.0, "heal": 6.0,
	},
	# Animals (team GAIA). "food" is the meat left when they die.
	"sheep": {
		"name": "Sheep", "hp": 8.0, "damage": 0.0, "range": 10.0, "cooldown": 1.0,
		"speed": 32.0, "sight": 60.0, "radius": 9.0, "animal": "passive", "food": 100,
	},
	"deer": {
		"name": "Deer", "hp": 10.0, "damage": 0.0, "range": 10.0, "cooldown": 1.0,
		"speed": 105.0, "sight": 100.0, "radius": 9.0, "animal": "flee", "food": 140,
	},
	"boar": {
		"name": "Wild Boar", "hp": 75.0, "damage": 5.0, "range": 14.0, "cooldown": 1.4,
		"speed": 70.0, "sight": 80.0, "radius": 11.0, "animal": "aggressive", "food": 300,
		"building_mult": 0.2,
	},
}

const BUILDING_DATA := {
	"town_center": {
		"name": "Town Center", "hp": 2400.0, "size": Vector2i(3, 3), "cost": {},
		"build_time": 60.0, "pop": 5, "trains": ["villager"], "dropoff": ["food", "wood", "gold", "stone"],
		"attack": {"damage": 6.0, "range": 190.0, "cooldown": 1.5},
	},
	"house": {
		"name": "House", "hp": 300.0, "size": Vector2i(2, 2), "cost": {"wood": 30},
		"build_time": 15.0, "pop": 5, "trains": [], "dropoff": [],
	},
	"farm": {
		"name": "Farm", "hp": 200.0, "size": Vector2i(2, 2), "cost": {"wood": 60},
		"build_time": 10.0, "pop": 0, "trains": [], "dropoff": [], "walkable": true, "food": 300,
	},
	"mill": {
		"name": "Mill", "hp": 500.0, "size": Vector2i(2, 2), "cost": {"wood": 100},
		"build_time": 20.0, "pop": 0, "trains": [], "dropoff": ["food"],
	},
	"lumber_camp": {
		"name": "Lumber Camp", "hp": 500.0, "size": Vector2i(2, 2), "cost": {"wood": 100},
		"build_time": 20.0, "pop": 0, "trains": [], "dropoff": ["wood"],
	},
	"mining_camp": {
		"name": "Mining Camp", "hp": 500.0, "size": Vector2i(2, 2), "cost": {"wood": 100},
		"build_time": 20.0, "pop": 0, "trains": [], "dropoff": ["gold", "stone"],
	},
	"barracks": {
		"name": "Barracks", "hp": 800.0, "size": Vector2i(3, 3), "cost": {"wood": 150, "stone": 50},
		"build_time": 30.0, "pop": 0, "trains": ["swordsman", "spearman", "axeman", "knight"], "dropoff": [],
	},
	"archery_range": {
		"name": "Archery Range", "hp": 800.0, "size": Vector2i(3, 3), "cost": {"wood": 150},
		"build_time": 30.0, "pop": 0, "trains": ["archer", "crossbowman"], "dropoff": [],
	},
	"siege_workshop": {
		"name": "Siege Workshop", "hp": 900.0, "size": Vector2i(3, 3), "cost": {"wood": 200, "gold": 100},
		"build_time": 40.0, "pop": 0, "trains": ["ram", "catapult"], "dropoff": [],
	},
	"watch_tower": {
		"name": "Watch Tower", "hp": 700.0, "size": Vector2i(2, 2), "cost": {"wood": 50, "stone": 100},
		"build_time": 25.0, "pop": 0, "trains": [], "dropoff": [],
		"attack": {"damage": 6.0, "range": 220.0, "cooldown": 1.8},
	},
	"monastery": {
		"name": "Monastery", "hp": 900.0, "size": Vector2i(3, 3), "cost": {"wood": 100, "stone": 150},
		"build_time": 35.0, "pop": 0, "trains": ["monk"], "dropoff": [],
	},
}
## Buildings a villager can construct, as HUD pages (economy, military).
const BUILD_PAGES := [
	["house", "farm", "mill", "lumber_camp", "mining_camp"],
	["barracks", "archery_range", "siege_workshop", "watch_tower", "monastery"],
]

var players: Array = []
var units: Array = []
var buildings: Array = []
var resources: Array = []
var selected: Array = []

var map: GameMap
var entities: Node2D
var effects: Node2D
var decals: Node2D
var overlay: Node2D
var fx: FX
var fog: Node2D
var camera: RTSCamera
var placement_ghost: Node2D

## Match settings chosen in the main menu (kept across reset()).
var mode := "skirmish"      ## skirmish | survival | sandbox | demo
var difficulty := 1         ## 0 easy, 1 normal, 2 hard
var random_map := false
## Gather speed multiplier per team (the AI gets a bonus/penalty by difficulty).
var gather_mult: Array[float] = [1.0, 1.0, 1.0]
## Extra line shown in the HUD (e.g. survival wave countdown).
var status_text := ""

var is_over := false
var winner := -1
var elapsed := 0.0

var _unit_scene: PackedScene
var _building_scene: PackedScene
var _projectile_scene: PackedScene
var _marker_script: Script
var _decal_script: Script
var _sprite_meta := {}
var _textures := {}


func _ready() -> void:
	_unit_scene = load("res://units/unit.tscn")
	_building_scene = load("res://buildings/building.tscn")
	_projectile_scene = load("res://units/projectile.tscn")
	_marker_script = load("res://ui/tap_marker.gd")
	_decal_script = load("res://fx/decal.gd")
	reset()


## Clears all state; called by the main scene when a match starts.
func reset() -> void:
	players.clear()
	for i in 2:
		players.append(START_RESOURCES.duplicate())
	units.clear()
	buildings.clear()
	resources.clear()
	selected.clear()
	is_over = false
	winner = -1
	elapsed = 0.0
	fx = null
	fog = null
	status_text = ""
	gather_mult = [1.0, [0.8, 1.0, 1.25][difficulty], 1.0]
	if mode == "sandbox":
		for p in players:
			for k in p:
				p[k] = 1000
	elif mode == "survival":
		players[PLAYER] = {"food": 300, "wood": 400, "gold": 200, "stone": 200}
	elif difficulty == 2:
		for k in players[ENEMY]:
			players[ENEMY][k] += 150


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
	if team >= 2:
		return 0
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


func spawn_projectile(attacker: Entity, target: Entity, damage: float, splash := 0.0) -> void:
	var p: Node2D = _projectile_scene.instantiate()
	p.setup(attacker, target, damage, splash)
	effects.add_child(p)


func spawn_marker(pos: Vector2, color: Color) -> void:
	var parent := overlay if overlay != null else effects
	if parent == null:
		return
	var m := Node2D.new()
	m.set_script(_marker_script)
	m.position = pos
	m.set("color", color)
	parent.add_child(m)


## Adds a ground decal (corpse, rubble or stump). props are set on the node.
func spawn_decal(kind: String, pos: Vector2, props := {}) -> void:
	if decals == null:
		return
	var d := Node2D.new()
	d.set_script(_decal_script)
	d.position = pos
	d.set("kind", kind)
	for k in props:
		d.set(k, props[k])
	decals.add_child(d)


func emit_fx(kind: String, pos: Vector2, count := 4) -> void:
	if fx != null:
		fx.emit(kind, pos, count)


## True if a world position is inside (or near) the camera view.
func on_screen(pos: Vector2, margin := 0.0) -> bool:
	if camera == null:
		return true
	return camera.visible_world_rect().grow(margin).has_point(pos)


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
	Sound.set_in_game(false)
	Sound.play_music("")
	Sound.play("victory" if winning_team == PLAYER else "defeat")
	Sound.play("you_win" if winning_team == PLAYER else "you_lose", null, 2.0)
	game_over.emit(winning_team)


# --- Queries -----------------------------------------------------------------

func get_town_center(team: int) -> Building:
	for b in buildings:
		if b.team == team and b.type == "town_center" and not b.dead:
			return b
	return null


## Nearest hostile entity. Animals (GAIA) are ignored unless include_gaia.
func find_nearest_enemy(team: int, pos: Vector2, max_dist: float, units_only := false, include_gaia := false) -> Entity:
	var best: Entity = null
	var best_d := max_dist
	for u in units:
		if u.team != team and not u.dead and (include_gaia or u.team != GAIA):
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


func find_nearest_enemy_building(team: int, pos: Vector2, max_dist: float) -> Building:
	var best: Building = null
	var best_d := max_dist
	for b in buildings:
		if b.team != team and not b.dead:
			var d: float = b.distance_to_edge(pos)
			if d < best_d:
				best_d = d
				best = b
	return best


## Damages every hostile entity within radius of pos (catapult stones).
func splash_damage(team: int, pos: Vector2, radius: float, damage: float, attacker) -> void:
	for e in units.duplicate() + buildings.duplicate():
		if e.dead or e.team == team:
			continue
		var d: float = e.distance_to_edge(pos)
		if d <= radius:
			var mult: float = 1.0 - d / radius * 0.5
			if e is Building:
				mult *= 2.0
			e.take_damage(damage * mult, attacker if alive(attacker) else null)


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


func find_nearest_dropoff(team: int, pos: Vector2, type := "") -> Building:
	var best: Building = null
	var best_d := FAR
	for b in buildings:
		if b.team == team and not b.dead and b.constructed and not b.data.dropoff.is_empty() \
				and (type == "" or b.data.dropoff.has(type)):
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
		if u.dead or not u.visible:
			continue
		# Units are drawn standing up, so accept taps on the body as well as the feet.
		var d: float = minf(u.position.distance_to(pos), (u.position + Vector2(0, -12)).distance_to(pos)) - u.radius
		if d < best_d:
			best_d = d
			best = u
	if best != null:
		return best
	for b in buildings:
		if not b.dead and b.visible and b.get_visual_rect().has_point(pos):
			return b
	for r in resources:
		if not r.dead and not r.occupies and r.position.distance_to(pos) < radius + 12.0:
			return r
	var c := map.world_to_cell(pos)
	var occ = map.occupancy.get(c)
	if occ != null and occ.visible:
		return occ
	best_d = radius + TILE * 0.5
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var o = map.occupancy.get(c + Vector2i(dx, dy))
			if o != null and o.visible:
				var d: float = o.distance_to_edge(pos)
				if d < best_d:
					best_d = d
					best = o
	return best


# --- Sprite assets ------------------------------------------------------------------

## Animation layout of the unit sprite sheets (generated by tools/build_unit_sprites.py).
func sprite_meta(type: String) -> Dictionary:
	if _sprite_meta.is_empty():
		var f := FileAccess.open("res://art/units/sheets.json", FileAccess.READ)
		if f != null:
			_sprite_meta = JSON.parse_string(f.get_as_text())
	return _sprite_meta.get(type, {})


func unit_texture(type: String, team: int) -> Texture2D:
	var path := "res://art/units/%s_%s.png" % [type, SPRITE_TEAMS[team]]
	if UNIT_DATA[type].has("animal"):
		path = "res://art/animals/%s.png" % type
	if not _textures.has(path):
		_textures[path] = load(path)
	return _textures[path]


static func alive(e) -> bool:
	return e != null and is_instance_valid(e) and not e.dead


static func rect_distance(rect: Rect2, p: Vector2) -> float:
	var dx := maxf(maxf(rect.position.x - p.x, 0.0), p.x - rect.end.x)
	var dy := maxf(maxf(rect.position.y - p.y, 0.0), p.y - rect.end.y)
	return sqrt(dx * dx + dy * dy)


# --- Selection ---------------------------------------------------------------

func set_selection(list: Array) -> void:
	if not list.is_empty() and list[0] is Unit and list[0].team == PLAYER:
		Sound.play("select", null, -8.0)
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
		if e is Unit and e.team == PLAYER and not e.dead and not e.is_animal:
			out.append(e)
	return out


func selected_own_building() -> Building:
	if selected.size() == 1 and selected[0] is Building and selected[0].team == PLAYER:
		return selected[0]
	return null


# --- Unit separation -----------------------------------------------------------

## Pushes overlapping units apart using a spatial hash (O(n)).
## Units standing still give way to units walking past, and moving units are
## never pushed back against their direction of travel (they slide sideways
## around the blocker instead), so a stationary unit can't stall a mover.
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
		var moving: bool = u.move_dir != Vector2.ZERO
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var bucket = grid.get(key + Vector2i(dx, dy))
				if bucket == null:
					continue
				for o in bucket:
					if o == u:
						continue
					var diff: Vector2 = u.position - o.position
					var min_d: float = (u.radius + o.radius) * 0.85
					var l2 := diff.length_squared()
					if l2 >= min_d * min_d:
						continue
					if l2 < 0.0001:
						diff = Vector2(float(u.get_instance_id() % 7) - 3.0, 1.0)
						l2 = diff.length_squared()
					var l := sqrt(l2)
					var w := 0.5
					var other_moving: bool = o.move_dir != Vector2.ZERO
					if moving and not other_moving:
						w = 0.15
					elif other_moving and not moving:
						w = 0.85
					push += diff / l * (min_d - l) * w
		if push == Vector2.ZERO:
			continue
		if moving:
			var back := push.dot(u.move_dir)
			if back < 0.0:
				push -= u.move_dir * back
				# Head-on: sidestep consistently to one side.
				var side := Vector2(-u.move_dir.y, u.move_dir.x)
				if absf(push.dot(side)) < 0.2:
					push += side * (0.6 if u.get_instance_id() % 2 == 0 else -0.6)
		var np: Vector2 = u.position + push.limit_length(1.5)
		if map.is_walkable_world(np):
			u.position = np
