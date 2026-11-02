class_name FogOfWar
extends Sprite2D
## Player fog of war on the 64x64 tile grid.
##
## 0 = unexplored (black), 1 = explored (dimmed), 2 = currently visible.
## A tiny alpha texture is scaled over the map with linear filtering, which
## gives soft edges for free. Enemy units are hidden outside vision; enemy
## buildings stay visible once explored (last known position).

const N := 64
const T := 32
const UPDATE_INTERVAL := 0.2
const ALPHA := [255, 130, 0]
const BUILDING_SIGHT := 150.0

var state := PackedByteArray()
var _img: Image
var _tex: ImageTexture
var _bytes := PackedByteArray()
var _t := 0.0


func setup() -> void:
	state.resize(N * N)
	state.fill(0)
	_bytes.resize(N * N * 2)
	_img = Image.create(N, N, false, Image.FORMAT_LA8)
	_tex = ImageTexture.create_from_image(_img)
	texture = _tex
	centered = false
	scale = Vector2(T, T)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	Game.fog = self
	refresh()


func _process(delta: float) -> void:
	if state.is_empty():
		return
	_t -= delta
	if _t <= 0.0:
		_t = UPDATE_INTERVAL
		refresh()


func refresh() -> void:
	for i in state.size():
		if state[i] == 2:
			state[i] = 1
	for u in Game.units:
		if u.team == Game.PLAYER and not u.dead:
			_reveal(u.position, u.sight + 20.0)
	for b in Game.buildings:
		if b.team == Game.PLAYER and not b.dead:
			_reveal(b.position, b.get_radius() + BUILDING_SIGHT)
	for i in N * N:
		_bytes[i * 2] = 0
		_bytes[i * 2 + 1] = ALPHA[state[i]]
	_img.set_data(N, N, false, Image.FORMAT_LA8, _bytes)
	_tex.update(_img)
	var lost := false
	for u in Game.units:
		if u.team != Game.PLAYER:
			u.visible = is_visible_at(u.position)
			if not u.visible and u.selected:
				lost = true
	if lost:
		Game.set_selection(Game.selected.filter(func(e): return e.visible))
	for b in Game.buildings:
		if b.team != Game.PLAYER:
			b.visible = is_explored_at(b.position)


func _reveal(pos: Vector2, radius: float) -> void:
	var c := Vector2i(floori(pos.x / T), floori(pos.y / T))
	var r := ceili(radius / T)
	var r2 := (radius / T) * (radius / T)
	for y in range(maxi(c.y - r, 0), mini(c.y + r, N - 1) + 1):
		for x in range(maxi(c.x - r, 0), mini(c.x + r, N - 1) + 1):
			var dx := x - c.x
			var dy := y - c.y
			if dx * dx + dy * dy <= r2:
				state[y * N + x] = 2


func _state_at(pos: Vector2) -> int:
	var x := floori(pos.x / T)
	var y := floori(pos.y / T)
	if x < 0 or y < 0 or x >= N or y >= N or state.is_empty():
		return 0
	return state[y * N + x]


func is_visible_at(pos: Vector2) -> bool:
	return _state_at(pos) == 2


func is_explored_at(pos: Vector2) -> bool:
	return _state_at(pos) >= 1
