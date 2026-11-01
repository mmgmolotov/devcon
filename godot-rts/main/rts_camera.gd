class_name RTSCamera
extends Camera2D
## Top-down camera with pan/zoom helpers, clamped to the map.

const MIN_ZOOM := 0.5
const MAX_ZOOM := 2.2
const KEY_PAN_SPEED := 900.0
const EDGE_MARGIN := 120.0


func _ready() -> void:
	Game.camera = self
	make_current()


func _process(delta: float) -> void:
	var dir := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down"))
	if dir != Vector2.ZERO:
		position += dir * KEY_PAN_SPEED * delta / zoom.x
		clamp_to_map()


func screen_to_world(p: Vector2) -> Vector2:
	var vp := get_viewport_rect().size
	return position + (p - vp * 0.5) / zoom.x


func world_to_screen(p: Vector2) -> Vector2:
	var vp := get_viewport_rect().size
	return (p - position) * zoom.x + vp * 0.5


func pan_screen(delta: Vector2) -> void:
	position -= delta / zoom.x
	clamp_to_map()


## Zooms by `factor`, keeping the world point under `screen_point` fixed.
func zoom_at(factor: float, screen_point: Vector2) -> void:
	var before := screen_to_world(screen_point)
	var z := clampf(zoom.x * factor, MIN_ZOOM, MAX_ZOOM)
	zoom = Vector2(z, z)
	var vp := get_viewport_rect().size
	position = before - (screen_point - vp * 0.5) / z
	clamp_to_map()


func center_on(p: Vector2) -> void:
	position = p
	clamp_to_map()


func visible_world_rect() -> Rect2:
	var vp := get_viewport_rect().size / zoom.x
	return Rect2(position - vp * 0.5, vp)


func clamp_to_map() -> void:
	if Game.map == null:
		return
	var world := Game.map.get_world_size()
	var half := get_viewport_rect().size * 0.5 / zoom.x
	for i in 2:
		var lo := half[i] - EDGE_MARGIN
		var hi := world[i] - half[i] + EDGE_MARGIN
		position[i] = world[i] * 0.5 if lo > hi else clampf(position[i], lo, hi)
