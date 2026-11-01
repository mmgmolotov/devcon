class_name GameMap
extends Node2D
## 64x64 tile map: ground rendering, resource placement and grid pathfinding.
##
## The ground is baked into a single 64x64 texture scaled up with nearest
## filtering (one draw call). Trees, mines and buildings mark their tiles as
## solid in an AStarGrid2D that units use for pathfinding.

const N := 64  # keep in sync with Game.MAP_SIZE
const T := 32  # keep in sync with Game.TILE
const RESOURCE_SCENE := preload("res://map/resource_node.tscn")

## Top-left cell of each team's starting Town Center (point-symmetric map).
var start_cells: Array[Vector2i] = [Vector2i(8, 52), Vector2i(53, 9)]
var astar := AStarGrid2D.new()
var occupancy := {}  # Vector2i -> Building or ResourceNode
var ground_image: Image
var rng := RandomNumberGenerator.new()


func generate(seed_value: int) -> void:
	rng.seed = seed_value
	occupancy.clear()
	astar.region = Rect2i(0, 0, N, N)
	astar.cell_size = Vector2(T, T)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.update()
	_build_ground()
	_place_resources()


func get_world_size() -> Vector2:
	return Vector2(N * T, N * T)


func start_center(team: int) -> Vector2:
	return cell_to_world(start_cells[team]) + Vector2(1.5, 1.5) * T


# --- Coordinates ---------------------------------------------------------------

func world_to_cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / T), floori(p.y / T))


func cell_to_world(c: Vector2i) -> Vector2:
	return Vector2(c * T)


func cell_center(c: Vector2i) -> Vector2:
	return Vector2(c * T) + Vector2(T, T) * 0.5


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < N and c.y < N


func is_walkable(c: Vector2i) -> bool:
	return in_bounds(c) and not astar.is_point_solid(c)


func is_walkable_world(p: Vector2) -> bool:
	return is_walkable(world_to_cell(p))


# --- Occupancy -----------------------------------------------------------------

## True if every tile of the footprint is inside the map and empty. A margin
## also requires the surrounding ring to be empty (keeps paths open for AI).
func is_area_free(cell: Vector2i, size: Vector2i, margin := 0) -> bool:
	for y in range(cell.y - margin, cell.y + size.y + margin):
		for x in range(cell.x - margin, cell.x + size.x + margin):
			var c := Vector2i(x, y)
			var inside := x >= cell.x and y >= cell.y and x < cell.x + size.x and y < cell.y + size.y
			if not in_bounds(c):
				if inside:
					return false
				continue
			if occupancy.has(c):
				return false
	return true


func occupy(cell: Vector2i, size: Vector2i, node: Node2D) -> void:
	for y in range(cell.y, cell.y + size.y):
		for x in range(cell.x, cell.x + size.x):
			var c := Vector2i(x, y)
			if in_bounds(c):
				occupancy[c] = node
				astar.set_point_solid(c, true)


func free_area(cell: Vector2i, size: Vector2i) -> void:
	for y in range(cell.y, cell.y + size.y):
		for x in range(cell.x, cell.x + size.x):
			var c := Vector2i(x, y)
			if in_bounds(c):
				occupancy.erase(c)
				astar.set_point_solid(c, false)


## Walkable tiles touching the footprint, sorted by distance to `toward`.
func ring_cells(cell: Vector2i, size: Vector2i, toward: Vector2) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(cell.y - 1, cell.y + size.y + 1):
		for x in range(cell.x - 1, cell.x + size.x + 1):
			var inside := x >= cell.x and y >= cell.y and x < cell.x + size.x and y < cell.y + size.y
			var c := Vector2i(x, y)
			if not inside and is_walkable(c):
				out.append(c)
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return cell_center(a).distance_squared_to(toward) < cell_center(b).distance_squared_to(toward))
	return out


func nearest_walkable(c: Vector2i, toward := Vector2(-1, -1)) -> Vector2i:
	if is_walkable(c):
		return c
	var ref := toward if toward.x >= 0.0 else cell_center(c)
	for r in range(1, 16):
		var best := Vector2i(-1, -1)
		var best_d := INF
		for y in range(c.y - r, c.y + r + 1):
			for x in range(c.x - r, c.x + r + 1):
				if absi(x - c.x) != r and absi(y - c.y) != r:
					continue
				var cc := Vector2i(x, y)
				if is_walkable(cc):
					var d := cell_center(cc).distance_squared_to(ref)
					if d < best_d:
						best_d = d
						best = cc
		if best.x >= 0:
			return best
	return c


# --- Pathfinding ---------------------------------------------------------------

## Returns world-space waypoints from `from` to `to` (excluding the start).
## Unreachable or blocked goals resolve to the closest reachable tile.
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var start_cell := world_to_cell(from)
	var start_blocked := not is_walkable(start_cell)
	var s := nearest_walkable(start_cell, from)
	var goal := world_to_cell(to).clamp(Vector2i.ZERO, Vector2i(N - 1, N - 1))
	var exact := is_walkable(goal) and in_bounds(world_to_cell(to))
	var t := goal if exact else nearest_walkable(goal, from)
	var ids := astar.get_id_path(s, t, true)
	var out := PackedVector2Array()
	var first := 0 if start_blocked else 1
	for i in range(first, ids.size()):
		out.append(cell_center(ids[i]))
	if exact and not ids.is_empty() and ids[ids.size() - 1] == t:
		if out.is_empty():
			out.append(to)
		else:
			out[out.size() - 1] = to
	return out


## Path to the free tile next to a rectangular obstacle closest to `from`.
func find_path_to_rect(from: Vector2, rect: Rect2) -> PackedVector2Array:
	var c0 := world_to_cell(rect.position + Vector2(1, 1))
	var c1 := world_to_cell(rect.end - Vector2(1, 1))
	var ring := ring_cells(c0, c1 - c0 + Vector2i.ONE, from)
	if ring.is_empty():
		return find_path(from, rect.get_center())
	return find_path(from, cell_center(ring[0]))


# --- Generation ----------------------------------------------------------------

func _mirror(c: Vector2i) -> Vector2i:
	return Vector2i(N - 1 - c.x, N - 1 - c.y)


func _build_ground() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 0.09
	ground_image = Image.create(N, N, false, Image.FORMAT_RGB8)
	var centers := [start_center(0) / T, start_center(1) / T]
	for y in N:
		for x in N:
			var v := (noise.get_noise_2d(x, y) + 1.0) * 0.5
			var c := Color(0.34, 0.56, 0.25).lerp(Color(0.45, 0.66, 0.3), v)
			if (x + y) % 2 == 0:
				c = c.darkened(0.035)
			for ctr in centers:
				var d: float = ctr.distance_to(Vector2(x + 0.5, y + 0.5))
				if d < 5.5:
					c = c.lerp(Color(0.6, 0.52, 0.36), clampf((5.5 - d) / 2.5, 0.0, 0.75))
			ground_image.set_pixel(x, y, c)
	var s := Sprite2D.new()
	s.name = "Ground"
	s.texture = ImageTexture.create_from_image(ground_image)
	s.centered = false
	s.scale = Vector2(T, T)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(s)


func _place_resources() -> void:
	var plan := {}  # Vector2i -> type, for the player's half; mirrored after.
	# Guaranteed resources near each base.
	for c in _blob(Vector2(3.5, 45.5), 3.3):
		plan[c] = "wood"
	for c in _blob(Vector2(21.5, 58.5), 2.2):
		plan[c] = "wood"
	for c in [Vector2i(16, 48), Vector2i(17, 48), Vector2i(16, 49), Vector2i(17, 49)]:
		plan[c] = "gold"
	for c in [Vector2i(12, 59), Vector2i(13, 59), Vector2i(13, 60)]:
		plan[c] = "stone"

	var pc := start_center(0) / T
	var ec := start_center(1) / T
	# Noise forests, generated for half the map and mirrored for fairness.
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 0.075
	for y in N:
		for x in N:
			var c := Vector2i(x, y)
			if y * N + x >= (N - 1 - y) * N + (N - 1 - x):
				continue
			var p := Vector2(x + 0.5, y + 0.5)
			if p.distance_to(pc) < 9.0 or p.distance_to(ec) < 9.0:
				continue
			if _dist_to_segment(p, pc, ec) < 3.0:
				continue
			if x == 0 or y == 0 or x == N - 1 or y == N - 1:
				if noise.get_noise_2d(x, y) > 0.05:
					plan[c] = "wood"
				continue
			if noise.get_noise_2d(x, y) > 0.28:
				plan[c] = "wood"
	# Extra mines away from the bases.
	_scatter_clusters(plan, "gold", 3, 4, pc, ec)
	_scatter_clusters(plan, "stone", 2, 3, pc, ec)

	for c in plan:
		_add_resource(c, plan[c])
		var m := _mirror(c)
		if not plan.has(m):
			_add_resource(m, plan[c])


func _scatter_clusters(plan: Dictionary, type: String, count: int, size: int, pc: Vector2, ec: Vector2) -> void:
	var placed := 0
	var tries := 0
	while placed < count and tries < 200:
		tries += 1
		var c := Vector2i(rng.randi_range(3, N - 4), rng.randi_range(3, N - 4))
		var p := Vector2(c) + Vector2(0.5, 0.5)
		if p.distance_to(pc) < 15.0 or p.distance_to(ec) < 15.0 or _dist_to_segment(p, pc, ec) < 4.0:
			continue
		if p.distance_to(Vector2(_mirror(c))) < 6.0:
			continue
		var cells := [c, c + Vector2i(1, 0), c + Vector2i(0, 1), c + Vector2i(1, 1)]
		for i in size:
			plan[cells[i]] = type
		placed += 1


func _blob(center: Vector2, radius: float) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(floori(center.y - radius), ceili(center.y + radius) + 1):
		for x in range(floori(center.x - radius), ceili(center.x + radius) + 1):
			var c := Vector2i(x, y)
			if in_bounds(c) and Vector2(x + 0.5, y + 0.5).distance_to(center) <= radius + rng.randf_range(-0.6, 0.3):
				out.append(c)
	return out


func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))


func _add_resource(c: Vector2i, type: String) -> void:
	if not in_bounds(c) or occupancy.has(c):
		return
	var r: ResourceNode = RESOURCE_SCENE.instantiate()
	r.setup(type, c, rng)
	occupy(c, Vector2i.ONE, r)
	Game.entities.add_child(r)
