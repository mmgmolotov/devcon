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
	if type == "wood":
		Game.spawn_decal("stump", position + Vector2(0, 6), {"life": 0.0})
	Game.resources.erase(self)
	Game.map.free_area(cell, Vector2i.ONE)
	queue_free()


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	if type == "wood":
		Art.draw_tree(self, rng)
	else:
		Art.draw_rocks(self, rng, type == "gold")
