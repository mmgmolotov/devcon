extends Node
## Dev helper: runs the game for a while (villagers gathering, a few soldiers
## fighting) and saves a screenshot. Needs a display (e.g. xvfb-run):
##   godot --path . res://tests/screenshot.tscn -- --out=/tmp/shot.png --time=20

## Extra args: --speed=10 (fast-forward), --focus=enemy (watch the AI base).
var out_path := "user://screenshot.png"
var run_time := 20.0
var _t := 0.0
var _done := false
var _focus := ""
var _zoom := 0.0
var _reveal := false
var _assault := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_path = a.substr(6)
		elif a.begins_with("--time="):
			run_time = float(a.substr(7))
		elif a.begins_with("--speed="):
			Engine.max_physics_steps_per_frame = 64
			Engine.time_scale = float(a.substr(8))
		elif a.begins_with("--zoom="):
			_zoom = float(a.substr(7))
		elif a == "--reveal":
			_reveal = true
		elif a.begins_with("--focus="):
			_focus = a.substr(8)
	add_child(load("res://main/main.tscn").instantiate())
	var vills := Game.units.filter(func(u): return u.team == Game.PLAYER)
	var tc := Game.get_town_center(Game.PLAYER)
	vills[0].command_gather(Game.find_nearest_resource("wood", tc.position))
	vills[1].command_gather(Game.find_nearest_resource("gold", tc.position))
	tc.enqueue("villager")
	var c := Game.map.start_center(Game.PLAYER) + Vector2(260, -40)
	for i in 3:
		Game.spawn_unit("swordsman", Game.PLAYER, c + Vector2(0, i * 26))
		Game.spawn_unit("archer", Game.ENEMY, c + Vector2(180, i * 26))
	var b := Game.place_building(Game.PLAYER, "house", Game.map.start_cells[0] + Vector2i(5, -3))
	vills[2].command_build(b)
	Game.set_selection([vills[0], vills[1]])
	Game.fog.reveal_all = _reveal
	if _zoom > 0.0:
		Game.camera.zoom = Vector2(_zoom, _zoom)
		Game.camera.center_on(tc.position + Vector2(120, -40))


func _process(delta: float) -> void:
	_t += delta
	if _focus == "enemy" and Game.get_town_center(Game.ENEMY) != null:
		Game.camera.center_on(Game.get_town_center(Game.ENEMY).position + Vector2(-120, 60))
	elif _focus == "battle" and Game.get_town_center(Game.ENEMY) != null:
		Game.camera.center_on(Game.get_town_center(Game.ENEMY).position + Vector2(-60, 40))
	if _focus == "battle" and _t > run_time - 25.0 and not _assault:
		_assault = true
		var etc := Game.get_town_center(Game.ENEMY)
		var at := etc.position + Vector2(-200, 160)
		for i in 10:
			var u := Game.spawn_unit("swordsman" if i % 2 == 0 else "archer", Game.PLAYER, at + Vector2(i % 5, i / 5) * 24.0)
			u.command_attack(etc)
	if _t >= run_time and not _done:
		_done = true
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out_path)
		print("Saved ", out_path)
		get_tree().quit()
