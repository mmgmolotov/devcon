extends Node
## Simple scripted opponent.
##
## Every second it: keeps villagers gathering (balanced across resources),
## trains villagers, builds houses before hitting the population cap, builds
## a barracks, trains soldiers and defends its base. Every few minutes it
## sends its army to attack the player in a wave that grows over time.

const TEAM := 1
const THINK_INTERVAL := 1.0
const FIRST_WAVE_TIME := 300.0
const WAVE_INTERVAL := 150.0
const RETRY_DELAY := 30.0
const TARGET_VILLAGERS := 12
const DEFENSE_RADIUS := 360.0
## Desired share of villagers per resource, before/after the barracks exists.
const SPLIT_EARLY := {"food": 0.4, "wood": 0.35, "gold": 0.1, "stone": 0.15}
const SPLIT_LATE := {"food": 0.35, "wood": 0.25, "gold": 0.32, "stone": 0.08}
const ARMY_MIX: Array[String] = ["swordsman", "archer", "spearman", "swordsman", "archer", "knight"]
const MAX_FARMS := 6
const CAMP_DISTANCE := 260.0

var wave_timer := FIRST_WAVE_TIME
var waves_sent := 0
var _think_timer := 1.0
var _mix_index := 0
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
			elif not u.is_monk:
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
	var counts := {"food": 0, "wood": 0, "gold": 0, "stone": 0}
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
		var res := Game.find_nearest_resource(best, tc.position, 1400.0 if best != "food" else 700.0)
		if res == null and best == "food":
			res = _free_farm()
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
	elif _needs_farm(tc):
		_try_build("farm", villagers, tc)
	elif _needs_camp("wood", "lumber_camp", tc) and villagers.size() >= 5:
		_try_build_near("lumber_camp", villagers, Game.find_nearest_resource("wood", tc.position))
	elif barracks.is_empty() and villagers.size() >= 5:
		_try_build("barracks", villagers, tc)
	elif _needs_camp("gold", "mining_camp", tc) and villagers.size() >= 7:
		_try_build_near("mining_camp", villagers, Game.find_nearest_resource("gold", tc.position))
	elif barracks.size() < 2 and waves_sent >= 2 and villagers.size() >= 10:
		_try_build("barracks", villagers, tc)


func _own_count(type: String) -> int:
	return Game.buildings.filter(func(b): return b.team == TEAM and not b.dead and b.type == type).size() \
		+ Game.resources.filter(func(r): return r.kind == "farm" and r.team == TEAM and not r.dead).size() * int(type == "farm")


## Farms are needed once there is no wild food close to the Town Center.
func _needs_farm(tc: Building) -> bool:
	if _own_count("farm") >= MAX_FARMS:
		return false
	var food := Game.find_nearest_resource("food", tc.position, 450.0)
	return food == null or (food.kind == "farm" and _free_farm() == null)


func _free_farm() -> ResourceNode:
	for r in Game.resources:
		if r.kind == "farm" and r.team == TEAM and not r.dead:
			var busy := Game.units.any(func(u): return u.team == TEAM and u.resource_target == r)
			if not busy:
				return r
	return null


func _needs_camp(res: String, camp: String, tc: Building) -> bool:
	if _own_count(camp) > 0:
		return false
	var r := Game.find_nearest_resource(res, tc.position)
	return r != null and r.position.distance_to(tc.position) > CAMP_DISTANCE


## Builds next to a resource cluster (for drop-off camps).
func _try_build_near(type: String, villagers: Array, near: ResourceNode) -> void:
	if near == null:
		return
	var d: Dictionary = Game.BUILDING_DATA[type]
	if not Game.can_afford(TEAM, d.cost):
		return
	var center := Game.map.world_to_cell(near.position)
	for r in range(2, 7):
		for y in range(center.y - r, center.y + r + 1):
			for x in range(center.x - r, center.x + r + 1):
				var c := Vector2i(x, y)
				if Game.map.is_area_free(c, d.size, 1):
					var b := Game.place_building(TEAM, type, c)
					if b != null:
						var v = _closest(villagers, b.position)
						if v != null:
							v.command_build(b)
					return


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
			if b.enqueue(ARMY_MIX[_mix_index % ARMY_MIX.size()]) == "":
				_mix_index += 1


func _defend(tc: Building, soldiers: Array) -> void:
	var threat: Entity = null
	var best := DEFENSE_RADIUS
	for u in Game.units:
		if u.team != TEAM and u.team != Game.GAIA and not u.dead:
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
	var army := Game.units.filter(func(u): return u.team == TEAM and not u.dead and not u.is_villager \
		and not u.is_monk and not u.attack_move)
	if army.size() < 2 + waves_sent:
		wave_timer = RETRY_DELAY
		return
	var target: Entity = Game.get_town_center(Game.PLAYER)
	if target == null:
		target = Game.find_nearest_enemy(TEAM, army[0].position, Game.FAR)
	if target == null:
		return
	# Waves start small and grow, so new players can hold the first one.
	army.sort_custom(func(a, b): return a.position.distance_to(target.position) < b.position.distance_to(target.position))
	army = army.slice(0, 4 + waves_sent * 3)
	for s in army:
		s.command_attack(target, true)
	waves_sent += 1
	wave_timer = WAVE_INTERVAL
	Game.notify.emit("Enemy attack wave %d incoming!" % waves_sent)
	Sound.play("prepare_yourself")


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
