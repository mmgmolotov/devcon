extends Node
## Headless end-to-end smoke test. Plays a full match on fast-forward:
##   godot --headless --fixed-fps 60 --path . res://tests/smoke_test.tscn
## Exits with code 0 on success, 1 on failure.

const FPS := 60.0
const TIMEOUT := 900.0

var _main: Node
var _frame := 0
var _failures: Array[String] = []
var _passed: Array[String] = []
var _phase := 0
var _ai: Node
var _house: Building
var _start_usec := 0
var _wave_reached_base := false


func _ready() -> void:
	_start_usec = Time.get_ticks_usec()
	_main = load("res://main/main.tscn").instantiate()
	add_child(_main)
	_ai = _main.get_node("EnemyAI")
	_check(Game.buildings.size() == 2, "two town centers spawned")
	_check(Game.units.size() == 6, "three villagers per side")
	_check(Game.resources.size() > 200, "map has resources (%d)" % Game.resources.size())
	_check(Game.players[0].wood == 200 and Game.players[0].gold == 100, "starting resources")
	_check(Game.get_pop_cap(0) == 5, "town center gives 5 population")
	_check(Game.fog.is_visible_at(Game.get_town_center(0).position), "fog: own base is visible")
	_check(not Game.fog.is_explored_at(Game.get_town_center(1).position), "fog: enemy base starts unexplored")
	_check(not Game.get_town_center(1).visible, "fog: unexplored enemy Town Center is hidden")
	_test_tap_controls()
	_give_player_orders()


func _test_tap_controls() -> void:
	var input = _main.get_node("InputController")
	var cam: RTSCamera = Game.camera
	var v: Unit = _player_villagers()[0]
	cam.center_on(v.position)
	input.handle_tap(cam.world_to_screen(v.position))
	_check(Game.selected == [v], "tap selects a unit")
	var tree := Game.find_nearest_resource("wood", v.position)
	cam.center_on(tree.position)
	input.handle_tap(cam.world_to_screen(tree.position))
	_check(v.state == Unit.State.GATHER and v.resource_target == tree, "tap resource sends villager to gather")
	var z := cam.zoom.x
	cam.zoom_at(1.5, Vector2(300, 300))
	_check(cam.zoom.x > z, "pinch zoom helper zooms")
	cam.zoom_at(1.0 / 1.5, Vector2(300, 300))
	Game.clear_selection()


func _give_player_orders() -> void:
	var tc := Game.get_town_center(0)
	var vills := _player_villagers()
	vills[1].command_gather(Game.find_nearest_resource("gold", tc.position))
	_check(tc.enqueue("villager") == "", "town center trains a villager")
	_check(Game.players[0].wood == 150, "training costs resources")
	_check(Game.get_pop(0) == 4, "queued unit counts toward population")
	var cell := tc.cell + Vector2i(5, -4)
	_house = Game.place_building(0, "house", cell)
	_check(_house != null and not _house.constructed, "house foundation placed")
	vills[2].command_build(_house)
	_check(Game.place_building(0, "house", cell) == null, "can't place on occupied tiles")


func _physics_process(_delta: float) -> void:
	_frame += 1
	var t := _frame / FPS
	if not _wave_reached_base and _frame % 30 == 0 and Game.get_town_center(0) != null:
		var ptc := Game.get_town_center(0)
		_wave_reached_base = Game.units.any(func(u): return u.team == 1 and u.attack_move and ptc.distance_to_edge(u.position) < 400.0)
	match _phase:
		0:
			if t >= 40.0:
				_check(Game.alive(_house) and _house.constructed, "villager finished the house")
				_check(Game.get_pop_cap(0) == 10, "house raises population cap to 10")
				_check(_player_villagers().size() == 4, "trained villager spawned")
				_check(Game.players[0].wood > 120 or _carrying(0, "wood"), "wood was gathered")
				_check(Game.players[0].gold > 100 or _carrying(0, "gold"), "gold was gathered")
				_phase = 1
		1:
			if t >= 330.0:
				var barracks := Game.buildings.filter(func(b): return b.team == 1 and b.type == "barracks" and b.constructed)
				_check(not barracks.is_empty(), "AI built a barracks")
				var ai_vills := Game.units.filter(func(u): return u.team == 1 and u.is_villager)
				_check(ai_vills.size() >= 6, "AI grew its economy (%d villagers)" % ai_vills.size())
				_check(Game.get_pop_cap(1) > 5, "AI built houses (cap %d)" % Game.get_pop_cap(1))
				_check(_ai.waves_sent >= 1, "AI sent an attack wave (%d)" % _ai.waves_sent)
				_check(_wave_reached_base, "AI wave reached the player's base")
				var ai_soldiers := Game.units.filter(func(u): return u.team == 1 and not u.is_villager)
				print("  t=330s AI: %d villagers, %d soldiers, res %s" % [ai_vills.size(), ai_soldiers.size(), Game.players[1]])
				_launch_player_assault()
				_phase = 2
		2:
			if Game.is_over:
				_check(Game.winner == Game.PLAYER, "destroying enemy Town Center wins the game")
				print("  game over at t=%.0fs" % t)
				_finish()
			elif t >= TIMEOUT:
				_check(false, "assault destroyed the enemy town center before timeout")
				_finish()


func _launch_player_assault() -> void:
	var etc := Game.get_town_center(1)
	var spawn := Game.map.start_center(1) + Vector2(-260, 260)
	var army := []
	for i in 10:
		army.append(Game.spawn_unit("swordsman", 0, spawn + Vector2(i % 5, i / 5) * 24.0))
	for i in 6:
		army.append(Game.spawn_unit("archer", 0, spawn + Vector2(i % 3, 3 + i / 3) * 24.0))
	for u in army:
		u.command_attack(etc)


## Fresh match: losing your own Town Center must end the game in defeat.
func _test_defeat() -> void:
	_main.free()
	_main = load("res://main/main.tscn").instantiate()
	add_child(_main)
	_check(not Game.is_over and Game.units.size() == 6, "match restarts cleanly")
	Game.get_town_center(0).take_damage(1.0e6)
	_check(Game.is_over and Game.winner == Game.ENEMY, "losing own Town Center is a defeat")


func _player_villagers() -> Array:
	return Game.units.filter(func(u): return u.team == 0 and u.is_villager)


func _carrying(team: int, type: String) -> bool:
	return Game.units.any(func(u): return u.team == team and u.carry_type == type and u.carry_amount > 0)


func _check(ok: bool, what: String) -> void:
	if ok:
		_passed.append(what)
		print("  PASS ", what)
	else:
		_failures.append(what)
		print("  FAIL ", what)


func _finish() -> void:
	set_physics_process(false)
	_test_defeat()
	var ms := (Time.get_ticks_usec() - _start_usec) / 1000.0
	print("Simulated %d frames (%.0fs game time) in %.0f ms real time: %.3f ms/frame (headless, no rendering)" % [
		_frame, _frame / FPS, ms, ms / maxf(1.0, _frame)])
	if _failures.is_empty():
		print("SMOKE TEST PASSED (%d checks)" % _passed.size())
		get_tree().quit(0)
	else:
		print("SMOKE TEST FAILED: ", _failures)
		get_tree().quit(1)
