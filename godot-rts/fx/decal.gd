extends Node2D
## Ground decal that slowly fades: fallen unit, building rubble or tree stump.

var kind := "corpse"
var life := 12.0
var team_color := Color.WHITE
var unit_type := "villager"
var facing := 1.0
var size := Vector2(64, 64)
var texture: Texture2D
var region := Rect2()
var offset := Vector2.ZERO
var scale_factor := 1.0
var flip := false
var _age := 0.0


func _ready() -> void:
	set_process(life > 0.0)


func _process(delta: float) -> void:
	_age += delta
	var fade_start := life * 0.6
	if _age > fade_start:
		modulate.a = clampf(1.0 - (_age - fade_start) / (life - fade_start), 0.0, 1.0)
	if _age >= life:
		queue_free()


func _draw() -> void:
	match kind:
		"corpse":
			Art.shadow(self, Vector2(0, 2), 12.0, 4.0, 0.25)
			draw_set_transform(Vector2(-10.0 * facing, 2), facing * PI * 0.5, Vector2.ONE)
			Art.draw_person(self, unit_type, team_color.darkened(0.35), facing, 0.0, -1.0, "", "")
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"sprite":
			if texture != null:
				Art.shadow(self, Vector2(0, 5), 12.0, 4.0, 0.2)
				var size := region.size * scale_factor
				var dst := Rect2(offset, size)
				if flip:  # a negative width mirrors the image
					dst = Rect2(offset + Vector2(size.x, 0), Vector2(-size.x, size.y))
				draw_texture_rect_region(texture, dst, region, Color(0.85, 0.8, 0.8))
		"rubble":
			Art.draw_rubble(self, size, get_instance_id())
		"stump":
			Art.draw_stump(self)
