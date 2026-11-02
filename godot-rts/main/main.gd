extends Node2D
## Match bootstrap: generates the map, spawns both bases and frames the camera.

const MAP_SEED := 20240611
const START_VILLAGERS := 3
const DEFAULT_ZOOM := 1.3

@onready var game_map: GameMap = $GameMap
@onready var entities: Node2D = $Entities
@onready var effects: Node2D = $Effects
@onready var decals: Node2D = $Decals
@onready var overlay: Node2D = $Overlay
@onready var camera: RTSCamera = $Camera


func _enter_tree() -> void:
	# Runs before any child's _ready, so the HUD never sees a stale match.
	Game.reset()
	Game.map = null


func _ready() -> void:
	Game.map = game_map
	Game.entities = entities
	Game.effects = effects
	Game.decals = decals
	Game.overlay = overlay
	game_map.generate(randi() if Game.random_map else MAP_SEED)
	_spawn_base(Game.PLAYER)
	if Game.mode != "survival":
		_spawn_base(Game.ENEMY)
	for a in game_map.animal_spawns:
		Game.spawn_unit(a[0], Game.GAIA, game_map.cell_center(a[1]))
	$Fog.setup()
	camera.zoom = Vector2(DEFAULT_ZOOM, DEFAULT_ZOOM)
	camera.center_on(game_map.start_center(Game.PLAYER) + Vector2(140, -20))
	match Game.mode:
		"survival":
			$EnemyAI.queue_free()
			var director := Node.new()
			director.name = "SurvivalDirector"
			director.set_script(preload("res://ai/survival_director.gd"))
			add_child(director)
		"demo":
			_setup_demo()
	if Game.mode != "demo":
		Sound.set_in_game(true)
		Sound.play_music("village")
		Sound.play("survival_mode" if Game.mode == "survival" else "fight")


# --- Demo (menu background): the AI plays both sides ----------------------------------

var _demo_t := 0.0


func _setup_demo() -> void:
	$HUD.queue_free()
	$InputController.queue_free()
	Game.fog.reveal_all = true
	Game.fog.visible = false
	var ai2 := Node.new()
	ai2.set_script(preload("res://ai/enemy_ai.gd"))
	ai2.set("team", Game.PLAYER)
	add_child(ai2)
	camera.zoom = Vector2(1.15, 1.15)
	Game.game_over.connect(func(_w):
		await get_tree().create_timer(5.0).timeout
		get_tree().reload_current_scene())


func _process(delta: float) -> void:
	if Game.mode != "demo":
		return
	# Slow cinematic drift across the map.
	_demo_t += delta * 0.025
	var world := game_map.get_world_size()
	var p := world * 0.5 + Vector2(cos(_demo_t) * world.x * 0.3, sin(_demo_t * 1.7) * world.y * 0.3)
	camera.position = camera.position.lerp(p, minf(1.0, delta * 0.5))


func _spawn_base(team: int) -> void:
	var cell := game_map.start_cells[team]
	var tc := Game.spawn_building("town_center", team, cell, true)
	var toward := game_map.get_world_size() * 0.5
	var ring := game_map.ring_cells(cell, tc.size, toward)
	for i in START_VILLAGERS:
		Game.spawn_unit("villager", team, game_map.cell_center(ring[i * 2]))
