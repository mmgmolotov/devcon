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
			if Game.UNIT_DATA[type].has("machine"):
				var mk := s / 64.0
				draw_set_transform(c + Vector2(0, 14.0 * mk), 0.0, Vector2(mk, mk))
				Art.draw_machine(self, Game.UNIT_DATA[type].machine, col, 1.0, 0.0, -1.0)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				return
			var tex := Game.unit_texture(type, team)
			var src := Rect2(0, 0, 64, 64)
			if Game.UNIT_DATA[type].has("animal"):
				src = {"sheep": Rect2(0, 128, 64, 64), "boar": Rect2(0, 128, 64, 64), "deer": Rect2(0, 0, 48, 48)}[type]
			else:
				var meta := Game.sprite_meta(type)
				var walk: Dictionary = meta.get("walk", meta.get("walk_axe", {}))
				var cell: float = walk.get("cell", 48)
				src = Rect2(0, float(walk.get("y", 0)) + 2.0 * cell, cell, cell)
				# Crop oversized frames to the character in the middle.
				if cell > 64.0:
					src = src.grow(-cell * 0.25)
			var k := s / src.size.y * 1.15
			var dst := Rect2(c - src.size * k * 0.5 + Vector2(0, s * 0.02), src.size * k)
			Art.shadow(self, c + Vector2(0, s * 0.4), s * 0.25, s * 0.08)
			draw_texture_rect_region(tex, dst, src)
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
