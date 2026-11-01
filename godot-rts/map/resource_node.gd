class_name ResourceNode
extends Node2D
## A gatherable map tile: tree (wood), gold mine or stone quarry.

var type := "wood"
var amount := 100
var cell := Vector2i.ZERO
var dead := false
var _seed := 0


func setup(resource_type: String, at_cell: Vector2i, rng: RandomNumberGenerator) -> void:
	type = resource_type
	cell = at_cell
	amount = Game.RESOURCE_AMOUNTS[type]
	_seed = rng.randi()
	position = Game.map.cell_center(cell)


func _ready() -> void:
	Game.resources.append(self)


func _exit_tree() -> void:
	Game.resources.erase(self)


func get_display_name() -> String:
	match type:
		"wood":
			return "Tree"
		"gold":
			return "Gold Mine"
	return "Stone"


func get_rect() -> Rect2:
	var t := float(Game.TILE)
	return Rect2(position - Vector2(t, t) * 0.5, Vector2(t, t))


func distance_to_edge(p: Vector2) -> float:
	return Game.rect_distance(get_rect(), p)


func nearest_point_to(p: Vector2) -> Vector2:
	var r := get_rect()
	return p.clamp(r.position, r.end)


## Removes up to n units of resource and returns how many were taken.
func harvest(n: int) -> int:
	if dead:
		return 0
	var got := mini(n, amount)
	amount -= got
	if amount <= 0:
		deplete()
	return got


func deplete() -> void:
	if dead:
		return
	dead = true
	Game.resources.erase(self)
	Game.map.free_area(cell, Vector2i.ONE)
	queue_free()


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	var j := Vector2(rng.randf_range(-3, 3), rng.randf_range(-3, 3))
	match type:
		"wood":
			draw_circle(Vector2(2, 10), 11.0, Color(0, 0, 0, 0.22))
			draw_rect(Rect2(-2.5 + j.x * 0.3, 2, 5, 11), Color(0.42, 0.27, 0.12))
			var g := Color(0.13, 0.42, 0.16).lightened(rng.randf_range(0.0, 0.12))
			draw_circle(j + Vector2(0, -3), 13.0, g.darkened(0.25))
			draw_circle(j + Vector2(-2, -5), 10.5, g)
			draw_circle(j + Vector2(-5, -8), 4.0, g.lightened(0.18))
		"gold":
			_draw_rocks(rng, Color(0.47, 0.42, 0.33), true)
		"stone":
			_draw_rocks(rng, Color(0.6, 0.6, 0.64), false)


func _draw_rocks(rng: RandomNumberGenerator, base: Color, nuggets: bool) -> void:
	draw_circle(Vector2(2, 6), 14.0, Color(0, 0, 0, 0.2))
	for i in 3:
		var p := Vector2(rng.randf_range(-7, 7), rng.randf_range(-6, 6))
		var r := rng.randf_range(7.0, 10.0)
		draw_circle(p, r, base.darkened(0.3))
		draw_circle(p + Vector2(-1.5, -1.5), r - 2.0, base)
		if nuggets:
			draw_circle(p + Vector2(rng.randf_range(-3, 3), rng.randf_range(-3, 3)), 3.0, Color(1.0, 0.85, 0.2))
			draw_circle(p + Vector2(rng.randf_range(-3, 3), rng.randf_range(-3, 3)), 2.0, Color(1.0, 0.95, 0.5))
