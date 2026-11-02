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
var _patient: Unit
var _ram_bad_target := false
var _ram_seen := false
var _sheep_start := 0


func _ready() -> void:
	var seed_value := 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			seed_value = int(a.substr(7))
	seed(seed_value)
	_start_usec = Time.get_ticks_usec()
	var args := OS.get_cmdline_user_args()
	if args.has("--survival"):
		_run_survival()
		return
	if args.has("--menu"):
		_run_menu()
		return
	Game.mode = "skirmish"
	Game.difficulty = 1
	Game.random_map = false
	_main = load("res://main/main.tscn").instantiate()
	add_child(_main)
	_ai = _main.get_node("EnemyAI")
	_check(Game.buildings.size() == 2, "two town centers spawned")
	_check(Game.units.filter(func(u): return u.team < 2).size() == 6, "three villagers per side")
	_check(Game.units.any(func(u): return u.type == "sheep") and Game.units.any(func(u): return u.type == "deer"), "animals spawned")
	_check(Game.resources.size() > 200, "map has resources (%d)" % Game.resources.size())
	_check(Game.players[0].food == 200 and Game.players[0].wood == 200 and Game.players[0].gold == 100, "starting resources")
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
	_check(Game.players[0].food == 150, "training costs resources")
	_check(Game.get_pop(0) == 4, "queued unit counts toward population")
	var cell := tc.cell + Vector2i(5, -4)
	_house = Game.place_building(0, "house", cell)
	_check(_house != null and not _house.constructed, "house foundation placed")
	vills[2].command_build(_house)
	_check(Game.place_building(0, "house", cell) == null, "can't place on occupied tiles")
	# New mechanics: hunting, farms, monks.
	_sheep_start = Game.units.filter(func(u): return u.type == "sheep").size()
	var sheep := Game.units.filter(func(u): return u.type == "sheep")
	sheep.sort_custom(func(a, b): return a.position.distance_to(tc.position) < b.position.distance_to(tc.position))
	vills[0].command_attack(sheep[0])
	_check(vills[0].state == Unit.State.ATTACK, "villager can hunt a sheep")
	var farm := Game.place_building(0, "farm", tc.cell + Vector2i(-4, -4))
	_check(farm != null, "farm foundation placed")
	var monk := Game.spawn_unit("monk", 0, tc.position + Vector2(140, 40))
	_patient = Game.spawn_unit("swordsman", 0, tc.position + Vector2(170, 40))
	_patient.hp = 30.0
	_check(monk.is_monk, "monk spawned")


func _physics_process(_delta: float) -> void:
	_frame += 1
	var t := _frame / FPS
	if _phase >= 200:
		_menu_tick(t)
		return
	if _phase >= 100:
		_survival_tick(t)
		return
	if not _wave_reached_base and _frame % 30 == 0 and Game.get_town_center(0) != null:
		var ptc := Game.get_town_center(0)
		_wave_reached_base = Game.units.any(func(u): return u.team == 1 and u.attack_move and ptc.distance_to_edge(u.position) < 400.0)
	if _frame % 30 == 0:
		for u in Game.units:
			if u.type == "ram" and Game.alive(u.target):
				_ram_seen = true
				if not u.target is Building:
					if not _ram_bad_target:
						print("  ram targeting ", u.target.get_display_name(), " state=", Unit.State.keys()[u.state])
					_ram_bad_target = true
	match _phase:
		0:
			if t >= 40.0:
				_check(Game.alive(_house) and _house.constructed, "villager finished the house")
				_check(Game.get_pop_cap(0) == 10, "house raises population cap to 10")
				_check(_player_villagers().size() == 4, "trained villager spawned")
				_check(Game.players[0].gold > 100 or _carrying(0, "gold"), "gold was gathered")
				_check(Game.units.filter(func(u): return u.type == "sheep").size() < _sheep_start, "a sheep was hunted")
				_check(Game.players[0].food > 150 or _carrying(0, "food"), "meat was gathered as food")
				_check(Game.resources.any(func(r): return r.kind == "farm" and r.team == 0), "finished farm became a food field")
				_check(Game.alive(_patient) and _patient.hp > 30.0, "monk healed a wounded soldier (hp %d)" % (_patient.hp if Game.alive(_patient) else 0))
				_phase = 1
		1:
			if t >= 345.0:
				var barracks := Game.buildings.filter(func(b): return b.team == 1 and b.type == "barracks" and b.constructed)
				_check(not barracks.is_empty(), "AI built a barracks")
				var ai_vills := Game.units.filter(func(u): return u.team == 1 and u.is_villager)
				_check(ai_vills.size() >= 6, "AI grew its economy (%d villagers)" % ai_vills.size())
				_check(Game.get_pop_cap(1) > 5, "AI built houses (cap %d)" % Game.get_pop_cap(1))
				_check(_ai.waves_sent >= 1, "AI sent an attack wave (%d)" % _ai.waves_sent)
				_check(_wave_reached_base, "AI wave reached the player's base")
				var ai_soldiers := Game.units.filter(func(u): return u.team == 1 and not u.is_villager)
				for b in Game.buildings.filter(func(b): return b.team == 1):
					print("    AI building %s constructed=%s progress=%.1f cell=%s" % [b.type, b.constructed, b.build_progress, b.cell])
				var states := {}
				for u in ai_vills:
					states[Unit.State.keys()[u.state] + "/" + u.resource_type] = states.get(Unit.State.keys()[u.state] + "/" + u.resource_type, 0) + 1
				print("    AI villager states: ", states)
				if OS.get_cmdline_user_args().has("--debug"):
					for u in ai_vills:
						var tp = u.target.position if Game.alive(u.target) else (u.dropoff.position if Game.alive(u.dropoff) else Vector2.ZERO)
						print("      %s pos=%s cell=%s tgt=%s path=%d/%d walkable=%s" % [Unit.State.keys()[u.state], u.position.round(), Game.map.world_to_cell(u.position), tp, u.path_index, u.path.size(), Game.map.is_walkable_world(u.position)])
				print("  t=345s AI: %d villagers, %d soldiers, res %s" % [ai_vills.size(), ai_soldiers.size(), Game.players[1]])
				_launch_player_assault()
				_phase = 2
		2:
			if Game.is_over:
				_check(Game.winner == Game.PLAYER, "destroying enemy Town Center wins the game")
				_check(not _ram_bad_target, "battering rams only target buildings (seen=%s bad=%s)" % [_ram_seen, _ram_bad_target])
				print("  game over at t=%.0fs" % t)
				_finish()
			elif t >= TIMEOUT:
				_check(false, "assault destroyed the enemy town center before timeout")
				_finish()


func _launch_player_assault() -> void:
	var etc := Game.get_town_center(1)
	var spawn := Game.map.start_center(1) + Vector2(-260, 260)
	var army := []
	for i in 14:
		army.append(Game.spawn_unit("knight", 0, spawn + Vector2(i % 5, i / 5) * 26.0))
	for i in 8:
		army.append(Game.spawn_unit(["archer", "crossbowman"][i % 2], 0, spawn + Vector2(i % 4, 3 + i / 4) * 26.0))
	for i in 4:
		army.append(Game.spawn_unit(["axeman", "ram", "catapult", "ram"][i], 0, spawn + Vector2(i * 34, 140)))
	for u in army:
		u.command_attack(etc)


## Fresh match: losing your own Town Center must end the game in defeat.
func _test_defeat() -> void:
	_main.free()
	_main = load("res://main/main.tscn").instantiate()
	add_child(_main)
	_check(not Game.is_over and Game.units.filter(func(u): return u.team < 2).size() == 6, "match restarts cleanly")
	Game.get_town_center(0).take_damage(1.0e6)
	_check(Game.is_over and Game.winner == Game.ENEMY, "losing own Town Center is a defeat")


# --- Survival mode: waves spawn from the edges and attack the player --------------

func _run_survival() -> void:
	Game.mode = "survival"
	Game.difficulty = 1
	_main = load("res://main/main.tscn").instantiate()
	add_child(_main)
	_check(Game.get_town_center(Game.ENEMY) == null, "survival: no enemy base")
	_check(_main.has_node("SurvivalDirector"), "survival: wave director running")
	_check(Game.players[0].wood == 400, "survival: bonus starting resources")
	_phase = 100


func _survival_tick(t: float) -> void:
	if _phase == 100 and t >= 170.0:
		var raiders := Game.units.filter(func(u): return u.team == Game.ENEMY)
		_check(raiders.size() >= 2, "survival: first raider wave spawned (%d)" % raiders.size())
		_check(raiders.all(func(u): return u.attack_move), "survival: raiders march on the player")
		_check(Game.status_text.begins_with("Wave"), "survival: HUD countdown text (%s)" % Game.status_text)
		var director = _main.get_node("SurvivalDirector")
		director.wave = director.TOTAL_WAVES
		for u in raiders:
			u.take_damage(1e6)
		_phase = 101
	elif _phase == 101 and t >= 172.0:
		_check(Game.is_over and Game.winner == Game.PLAYER, "survival: surviving every wave is a victory")
		_finish_simple()


# --- Main menu: builds, runs the AI-vs-AI demo and starts a game ------------------

func _run_menu() -> void:
	_main = load("res://ui/main_menu.tscn").instantiate()
	add_child(_main)
	_check(Game.mode == "demo", "menu: background demo battle running")
	_check(Game.units.filter(func(u): return u.team < 2).size() == 6, "menu: demo spawned both bases")
	_phase = 200


func _menu_tick(t: float) -> void:
	if _phase == 200 and t >= 90.0:
		var ai_count := _main.get_child(0).get_children().filter(func(n): return n.get_script() == preload("res://ai/enemy_ai.gd")).size()
		_check(ai_count == 2, "menu: AI controls both demo teams")
		_check(Game.units.filter(func(u): return u.team == 0 and u.is_villager).size() > 3, "menu: demo AI grows team 0")
		_main._mode = "sandbox"
		_main._start_game()
		# Check before the fade finishes and the scene switches away from the test.
		_check(Game.mode == "sandbox", "menu: START applies the chosen mode")
		_finish_simple()


func _finish_simple() -> void:
	set_physics_process(false)
	if _failures.is_empty():
		print("SMOKE TEST PASSED (%d checks)" % _passed.size())
	else:
		print("SMOKE TEST FAILED: ", _failures)
	for c in get_tree().root.get_children():
		if c != self and c.name not in ["Game", "Sound"]:
			c.queue_free()
	if is_instance_valid(_main):
		_main.queue_free()
	Sound.stop_all()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0 if _failures.is_empty() else 1)


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
	else:
		print("SMOKE TEST FAILED: ", _failures)
	_main.queue_free()
	Sound.stop_all()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0 if _failures.is_empty() else 1)
