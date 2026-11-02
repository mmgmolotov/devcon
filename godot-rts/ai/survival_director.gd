extends Node
## Survival mode: no enemy base. Waves of raiders arrive from the map edges,
## growing in size and strength. Survive all waves to win.

const TOTAL_WAVES := 12
const FIRST_DELAY := [200.0, 150.0, 110.0]
const WAVE_GAP := [100.0, 80.0, 65.0]
const SIZE_MULT := [0.7, 1.0, 1.4]
const POOLS := [
	["swordsman", "spearman", "archer"],
	["swordsman", "spearman", "archer", "axeman", "crossbowman"],
	["axeman", "crossbowman", "knight", "spearman", "archer"],
	["knight", "axeman", "crossbowman", "ram", "catapult", "swordsman"],
]

var wave := 0
var timer := 150.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 99
	timer = FIRST_DELAY[Game.difficulty]


func _physics_process(delta: float) -> void:
	if Game.is_over or Game.map == null:
		return
	if wave >= TOTAL_WAVES:
		var left := Game.units.filter(func(u): return u.team == Game.ENEMY and not u.dead).size()
		Game.status_text = "Final wave: %d raiders left" % left
		if left == 0:
			Game.end_game(Game.PLAYER)
		return
	timer -= delta
	var t := maxi(0, ceili(timer))
	Game.status_text = "Wave %d/%d in %d:%02d" % [wave + 1, TOTAL_WAVES, t / 60, t % 60]
	if timer <= 0.0:
		spawn_wave()


func spawn_wave() -> void:
	var tc := Game.get_town_center(Game.PLAYER)
	if tc == null:
		return
	var pool: Array = POOLS[mini(wave / 3, POOLS.size() - 1)]
	var count := maxi(2, int(round((3 + wave * 2) * SIZE_MULT[Game.difficulty])))
	var origin := _edge_point(tc.position)
	for i in count:
		var type: String = pool[_rng.randi() % pool.size()]
		if Game.UNIT_DATA[type].has("machine") and i % 4 != 0:
			type = "swordsman"
		var offset := Vector2((i % 5) * 26.0, (i / 5) * 26.0) - Vector2(52, 26)
		var cell := Game.map.nearest_walkable(Game.map.world_to_cell(origin + offset))
		var u := Game.spawn_unit(type, Game.ENEMY, Game.map.cell_center(cell))
		u.command_attack(tc, true)
	wave += 1
	timer = WAVE_GAP[Game.difficulty]
	Game.notify.emit("Wave %d: %d raiders approach!" % [wave, count])
	Sound.play("prepare_yourself")


## A walkable point on a map edge, far from the player's base.
func _edge_point(avoid: Vector2) -> Vector2:
	var world := Game.map.get_world_size()
	var best := Vector2.ZERO
	var best_d := -1.0
	for i in 8:
		var p := Vector2.ZERO
		match _rng.randi() % 4:
			0:
				p = Vector2(_rng.randf_range(100, world.x - 100), 80)
			1:
				p = Vector2(world.x - 80, _rng.randf_range(100, world.y - 100))
			2:
				p = Vector2(_rng.randf_range(100, world.x - 100), world.y - 80)
			_:
				p = Vector2(80, _rng.randf_range(100, world.y - 100))
		var d := p.distance_to(avoid)
		if d > best_d:
			best_d = d
			best = p
	return best
