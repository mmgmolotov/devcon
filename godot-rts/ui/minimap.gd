extends Control
## Small overview map. Tap or drag on it to move the camera.

const REFRESH := 0.25

var _ground: ImageTexture
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	_t -= delta
	if _t <= 0.0:
		_t = REFRESH
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var p := Vector2(-1, -1)
	if event is InputEventScreenTouch and event.pressed:
		p = event.position
	elif event is InputEventScreenDrag:
		p = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		p = event.position
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		p = event.position
	if p.x >= 0.0 and Game.camera != null and Game.map != null:
		Game.camera.center_on(p / size * Game.map.get_world_size())
		queue_redraw()
		accept_event()


func _draw() -> void:
	if Game.map == null:
		return
	if _ground == null:
		_ground = ImageTexture.create_from_image(Game.map.ground_image)
	var world := Game.map.get_world_size()
	var k := size / world
	draw_rect(Rect2(Vector2.ZERO, size).grow(6), Color(0.2, 0.13, 0.08))
	draw_rect(Rect2(Vector2.ZERO, size).grow(5), Color(0.83, 0.66, 0.32), false, 3.0)
	draw_texture_rect(_ground, Rect2(Vector2.ZERO, size), false)
	var cell := Vector2(Game.TILE, Game.TILE) * k
	for r in Game.resources:
		if not r.dead:
			var c: Color = Color(0.1, 0.3, 0.1) if r.type == "wood" else Game.RESOURCE_COLORS[r.type]
			draw_rect(Rect2(r.position * k - cell * 0.5, cell), c)
	for b in Game.buildings:
		if not b.dead and b.visible:
			var rect: Rect2 = b.get_rect()
			draw_rect(Rect2(rect.position * k, rect.size * k), Game.TEAM_COLORS[b.team])
			draw_rect(Rect2(rect.position * k, rect.size * k), Color.BLACK, false, 1.0)
	for u in Game.units:
		if not u.dead and u.visible:
			draw_rect(Rect2(u.position * k - Vector2(2, 2), Vector2(4, 4)), Game.TEAM_COLORS[u.team].lightened(0.2))
	if Game.fog != null and Game.fog.texture != null:
		draw_texture_rect(Game.fog.texture, Rect2(Vector2.ZERO, size), false)
	if Game.camera != null:
		var v: Rect2 = Game.camera.visible_world_rect()
		draw_rect(Rect2(v.position * k, v.size * k).intersection(Rect2(Vector2.ZERO, size)), Color.WHITE, false, 1.5)
