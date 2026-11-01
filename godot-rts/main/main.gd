extends Node2D
## Match bootstrap: generates the map, spawns both bases and frames the camera.

const MAP_SEED := 20240611
const START_VILLAGERS := 3

@onready var game_map: GameMap = $GameMap
@onready var entities: Node2D = $Entities
@onready var effects: Node2D = $Effects
@onready var camera: RTSCamera = $Camera


func _enter_tree() -> void:
	# Runs before any child's _ready, so the HUD never sees a stale match.
	Game.reset()
	Game.map = null


func _ready() -> void:
	Game.map = game_map
	Game.entities = entities
	Game.effects = effects
	game_map.generate(MAP_SEED)
	for team in 2:
		_spawn_base(team)
	camera.center_on(game_map.start_center(Game.PLAYER) + Vector2(160, -60))


func _spawn_base(team: int) -> void:
	var cell := game_map.start_cells[team]
	var tc := Game.spawn_building("town_center", team, cell, true)
	var toward := game_map.get_world_size() * 0.5
	var ring := game_map.ring_cells(cell, tc.size, toward)
	for i in START_VILLAGERS:
		Game.spawn_unit("villager", team, game_map.cell_center(ring[i * 2]))
