extends Node
## Simple scripted opponent.
##
## Every second it: keeps villagers gathering (balanced across resources),
## trains villagers, builds houses before hitting the population cap, builds
## a barracks, trains soldiers and defends its base. Every few minutes it
## sends its army to attack the player in a wave that grows over time.

const TEAM := 1
const THINK_INTERVAL := 1.0
const FIRST_WAVE_TIME := 240.0
const WAVE_INTERVAL := 150.0
const RETRY_DELAY := 30.0
const TARGET_VILLAGERS := 12
const DEFENSE_RADIUS := 360.0
## Desired share of villagers per resource, before/after the barracks exists.
const SPLIT_EARLY := {"wood": 0.5, "gold": 0.3, "stone": 0.2}
const SPLIT_LATE := {"wood": 0.45, "gold": 0.45, "stone": 0.1}

var wave_timer := FIRST_WAVE_TIME
var waves_sent := 0
var _think_timer := 1.0
var _next_soldier := "swordsman"
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 7


func _physics_process(delta: float) -> void:
	if Game.is_over or Game.map == null:
		return
	wave_timer -= delta
	_think_timer -= delta
	if _think_timer <= 0.0:
		_think_timer = THINK_INTERVAL
		_think()
	if wave_timer <= 0.0:
		_send_wave()


func _think() -> void:
	var tc := Game.get_town_center(TEAM)
	if tc == null:
		return
	var villagers := []
	var soldiers := []
	for u in Game.units:
		if u.team == TEAM and not u.dead:
			if u.is_villager:
				villagers.append(u)
			else:
				soldiers.append(u)
	var barracks := _own_buildings("barracks")
	_assign_gatherers(villagers, tc, barracks.is_empty())
	_manage_construction(villagers, tc, barracks)
	_train(tc, villagers, barracks)
	_defend(tc, soldiers)


func _own_buildings(type: String) -> Array:
	return Game.buildings.filter(func(b): return b.team == TEAM and not b.dead and b.type == type)


func _assign_gatherers(villagers: Array, tc: Building, early: bool) -> void:
	var split: Dictionary = SPLIT_EARLY if early else SPLIT_LATE
	var counts := {"wood": 0, "gold": 0, "stone": 0}
	var idle := []
	for v in villagers:
		if v.state == Unit.State.IDLE:
			idle.append(v)
		elif v.resource_type != "":
			counts[v.resource_type] += 1
	var total := villagers.size()
	for v in idle:
		var best := "wood"
		var best_gap := -INF
		for r in split:
			var gap: float = split[r] * total - counts[r]
			if gap > best_gap:
				best_gap = gap
				best = r
		var res := Game.find_nearest_resource(best, tc.position)
		if res == null:
			res = Game.find_nearest_resource("wood", tc.position)
		if res != null:
			v.command_gather(res)
			counts[res.type] += 1


func _manage_construction(villagers: Array, tc: Building, barracks: Array) -> void:
	var unfinished := Game.buildings.filter(func(b): return b.team == TEAM and not b.dead and not b.constructed)
	for b in unfinished:
		var has_builder := villagers.any(func(v): return v.state == Unit.State.BUILD and v.target == b)
		if not has_builder:
			var v = _closest(villagers, b.position)
			if v != null:
				v.command_build(b)
	if not unfinished.is_empty() or villagers.size() < 3:
		return
	var pop := Game.get_pop(TEAM)
	var cap := Game.get_pop_cap(TEAM)
	if cap < Game.MAX_POP and cap - pop <= 2:
		_try_build("house", villagers, tc)
	elif barracks.is_empty() and villagers.size() >= 5:
		_try_build("barracks", villagers, tc)
	elif barracks.size() < 2 and waves_sent >= 2 and villagers.size() >= 10:
		_try_build("barracks", villagers, tc)


func _try_build(type: String, villagers: Array, tc: Building) -> void:
	var d: Dictionary = Game.BUILDING_DATA[type]
	if not Game.can_afford(TEAM, d.cost):
		return
	var cell := _find_spot(tc, d.size)
	if cell.x < 0:
		return
	var b := Game.place_building(TEAM, type, cell)
	if b == null:
		return
	var v = _closest(villagers, b.position)
	if v != null:
		v.command_build(b)


## Searches outward from the Town Center for a free footprint with a 1-tile
## margin so the base never walls itself in.
func _find_spot(tc: Building, size: Vector2i) -> Vector2i:
	var center := tc.cell + tc.size / 2
	for r in range(3, 16):
		var candidates: Array[Vector2i] = []
		for y in range(center.y - r, center.y + r + 1):
			for x in range(center.x - r, center.x + r + 1):
				if absi(x - center.x) == r or absi(y - center.y) == r:
					candidates.append(Vector2i(x, y) - size / 2)
		while not candidates.is_empty():
			var c: Vector2i = candidates.pop_at(_rng.randi_range(0, candidates.size() - 1))
			if Game.map.is_area_free(c, size, 1):
				return c
	return Vector2i(-1, -1)


func _train(tc: Building, villagers: Array, barracks: Array) -> void:
	if tc.queue.is_empty() and villagers.size() < TARGET_VILLAGERS:
		tc.enqueue("villager")
	if villagers.size() < 6:
		return
	for b in barracks:
		if b.constructed and b.queue.is_empty():
			if b.enqueue(_next_soldier) == "":
				_next_soldier = "archer" if _next_soldier == "swordsman" else "swordsman"


func _defend(tc: Building, soldiers: Array) -> void:
	var threat: Entity = null
	var best := DEFENSE_RADIUS
	for u in Game.units:
		if u.team != TEAM and not u.dead:
			for b in Game.buildings:
				if b.team == TEAM and not b.dead:
					var d: float = b.distance_to_edge(u.position)
					if d < best:
						best = d
						threat = u
	if threat == null:
		return
	for s in soldiers:
		if not s.attack_move and (s.state == Unit.State.IDLE or s.state == Unit.State.MOVE):
			s.command_attack(threat)


func _send_wave() -> void:
	var army := Game.units.filter(func(u): return u.team == TEAM and not u.dead and not u.is_villager and not u.attack_move)
	if army.size() < 2 + waves_sent:
		wave_timer = RETRY_DELAY
		return
	var target: Entity = Game.get_town_center(Game.PLAYER)
	if target == null:
		target = Game.find_nearest_enemy(TEAM, army[0].position, Game.FAR)
	if target == null:
		return
	for s in army:
		s.command_attack(target, true)
	waves_sent += 1
	wave_timer = WAVE_INTERVAL
	Game.notify.emit("Enemy attack wave %d incoming!" % waves_sent)


func _closest(list: Array, pos: Vector2):
	var best = null
	var best_d := INF
	for v in list:
		if v.state == Unit.State.BUILD:
			continue
		var d: float = v.position.distance_squared_to(pos)
		if d < best_d:
			best_d = d
			best = v
	return best
