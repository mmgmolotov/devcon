class_name ResourceNode
extends Node2D
## A gatherable resource: tree (wood), gold mine, stone quarry, berry bush,
## farm field (food, walkable, 2x2) or animal carcass (food, non-blocking).

var type := "wood"      ## Resource given: food, wood, gold, stone.
var kind := "tree"      ## tree, gold, stone, berries, farm, carcass.
var amount := 100
var cell := Vector2i.ZERO
var size := Vector2i.ONE
var blocking := true    ## Marks its tiles solid for pathfinding.
var occupies := true    ## Registers in the map occupancy grid.
var gather_mult := 1.0
var team := -1          ## Owner (farms only).
var dead := false
var carcass_texture: Texture2D
var carcass_region := Rect2()
var _seed := 0

const KINDS := {
	"tree": {"type": "wood", "amount": 100, "mult": 1.0},
	"gold": {"type": "gold", "amount": 400, "mult": 1.0},
	"stone": {"type": "stone", "amount": 300, "mult": 1.0},
	"berries": {"type": "food", "amount": 150, "mult": 0.85},
	"farm": {"type": "food", "amount": 300, "mult": 0.65},
	"carcass": {"type": "food", "amount": 100, "mult": 1.3},
}


func setup(node_kind: String, at_cell: Vector2i, rng: RandomNumberGenerator, footprint := Vector2i.ONE) -> void:
	kind = node_kind
	var k: Dictionary = KINDS[kind]
	type = k.type
	amount = k.amount
	gather_mult = k.mult
	cell = at_cell
	size = footprint
	blocking = kind not in ["farm", "carcass"]
	occupies = kind != "carcass"
	_seed = rng.randi()
	position = Game.map.cell_to_world(cell) + Vector2(size) * Game.TILE * 0.5


func _ready() -> void:
	Game.resources.append(self)


func _exit_tree() -> void:
	Game.resources.erase(self)


func get_display_name() -> String:
	return {"tree": "Tree", "gold": "Gold Mine", "stone": "Stone Quarry", "berries": "Berry Bush",
		"farm": "Farm", "carcass": "Carcass"}.get(kind, kind)


func get_status_text() -> String:
	return "%d %s left" % [amount, type]


func get_rect() -> Rect2:
	var s := Vector2(size) * Game.TILE
	if kind == "carcass":
		s = Vector2(20, 14)
	return Rect2(position - s * 0.5, s)


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
	if kind == "farm" or kind == "berries":
		queue_redraw()
	if amount <= 0:
		deplete()
	return got


func deplete() -> void:
	if dead:
		return
	dead = true
	if kind == "tree":
		Game.spawn_decal("stump", position + Vector2(0, 6), {"life": 0.0})
	Game.resources.erase(self)
	if occupies:
		Game.map.free_area(cell, size)
	if kind == "farm":
		Game.notify_player(team, "A farm is exhausted")
	queue_free()


func _draw() -> void:
	var pdef := ArtPack.resource_def(kind)
	if not pdef.is_empty():
		var tex := ArtPack.resource_texture(kind, _seed)
		if tex != null:
			ArtPack.draw_image(self, tex, pdef)
			return
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	match kind:
		"tree":
			Art.draw_tree(self, rng)
		"gold", "stone":
			Art.draw_rocks(self, rng, kind == "gold")
		"berries":
			Art.draw_berry_bush(self, rng, float(amount) / KINDS.berries.amount)
		"farm":
			Art.draw_farm(self, Vector2(size) * Game.TILE, float(amount) / KINDS.farm.amount)
		"carcass":
			if carcass_texture != null:
				draw_set_transform(Vector2(0, 2), PI * 0.5, Vector2.ONE)
				var s := carcass_region.size
				draw_texture_rect_region(carcass_texture, Rect2(-s * 0.5, s), carcass_region, Color(0.75, 0.6, 0.55))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				Art.ellipse(self, Vector2.ZERO, 9.0, 5.0, Color(0.6, 0.3, 0.25))
