extends Node2D
## World-space preview for placing a new building (green = valid, red = blocked).

signal changed

var type := ""
var cell := Vector2i.ZERO
var size := Vector2i.ONE
var valid := false


func _ready() -> void:
	Game.placement_ghost = self
	z_index = 5


func is_active() -> bool:
	return type != ""


func begin(building_type: String, world_pos: Vector2) -> void:
	type = building_type
	size = Game.BUILDING_DATA[type].size
	set_target(world_pos)


func set_target(world_pos: Vector2) -> void:
	cell = Game.map.world_to_cell(world_pos) - size / 2
	valid = Game.map.is_area_free(cell, size)
	queue_redraw()
	changed.emit()


func contains(world_pos: Vector2) -> bool:
	return Rect2(Game.map.cell_to_world(cell), Vector2(size) * Game.TILE).has_point(world_pos)


## Lays the foundation and sends the selected villagers to build it.
func confirm() -> bool:
	if not is_active():
		return false
	if not valid:
		Game.notify.emit("Can't build there")
		return false
	var b := Game.place_building(Game.PLAYER, type, cell)
	if b == null:
		return false
	for u in Game.selected_own_units():
		if u.is_villager:
			u.command_build(b)
	cancel()
	return true


func cancel() -> void:
	type = ""
	queue_redraw()
	changed.emit()


func _draw() -> void:
	if not is_active():
		return
	var r := Rect2(Game.map.cell_to_world(cell), Vector2(size) * Game.TILE)
	var c := Color(0.3, 1.0, 0.4) if valid else Color(1.0, 0.3, 0.25)
	draw_rect(r, Color(c, 0.35))
	draw_rect(r, c, false, 3.0)
	for x in size.x:
		for y in size.y:
			draw_rect(Rect2(r.position + Vector2(x, y) * Game.TILE, Vector2(Game.TILE, Game.TILE)), Color(c, 0.5), false, 1.0)
