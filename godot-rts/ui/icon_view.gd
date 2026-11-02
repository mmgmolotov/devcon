class_name IconView
extends Control
## Draws game art (unit, building, resource node or resource icon) scaled to
## fit the control. Used for HUD buttons, the portrait and counters.

var kind := "unit"     ## unit | building | resource | node
var type := "villager"
var team := 0
var seed_value := 1


func setup(icon_kind: String, icon_type: String, icon_team := 0) -> IconView:
	kind = icon_kind
	type = icon_type
	team = icon_team
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	return self


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var s := minf(size.x, size.y)
	if s <= 2.0:
		return
	var col: Color = Game.TEAM_COLORS[team]
	var c := size * 0.5
	match kind:
		"unit":
			var k := s / 32.0
			draw_set_transform(c + Vector2(0, 12.0 * k), 0.0, Vector2(k, k))
			Art.shadow(self, Vector2.ZERO, 9.0, 3.5)
			var tool: String = {"villager": "axe", "swordsman": "sword", "archer": "bow"}.get(type, "")
			Art.draw_person(self, type, col, 1.0, 0.0, -1.0, tool, "")
		"building":
			var fs := Vector2(Game.BUILDING_DATA[type].size) * Game.TILE
			var up: float = Art.WALL_HEIGHT.get(type, 22.0) + 22.0
			var k := s / maxf(fs.x + 16.0, fs.y + up)
			draw_set_transform(c + Vector2(0, up * 0.5 * k), 0.0, Vector2(k, k))
			Art.draw_building(self, type, col, fs)
		"node":
			var k := s / 44.0
			draw_set_transform(c + Vector2(0, 8.0 * k), 0.0, Vector2(k, k))
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value
			if type == "wood":
				Art.draw_tree(self, rng)
			else:
				Art.draw_rocks(self, rng, type == "gold")
		"resource":
			Art.draw_resource_icon(self, type, c, s * 0.9)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
