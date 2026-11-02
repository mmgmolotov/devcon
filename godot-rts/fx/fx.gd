class_name FX
extends Node2D
## Lightweight particle system: every particle is drawn by this one node,
## which keeps draw calls low on mobile. Off-screen emits are skipped.

const MAX_PARTICLES := 450

# Each particle: [pos, vel, age, life, size0, size1, color0, color1, gravity]
var _p: Array = []


func _ready() -> void:
	Game.fx = self


func emit(kind: String, pos: Vector2, count := 4) -> void:
	if not Game.on_screen(pos, 80.0):
		return
	for i in count:
		if _p.size() >= MAX_PARTICLES:
			return
		match kind:
			"wood":
				_add(pos, Vector2(randf_range(-45, 45), randf_range(-70, -25)), 0.55, 2.2, 1.2,
					Color(0.75, 0.55, 0.3), Color(0.55, 0.38, 0.2, 0.0), 220.0)
			"gold":
				_add(pos, Vector2(randf_range(-40, 40), randf_range(-60, -20)), 0.45, 1.8, 0.6,
					Color(1.0, 0.95, 0.5), Color(1.0, 0.75, 0.1, 0.0), 160.0)
			"stone":
				_add(pos, Vector2(randf_range(-40, 40), randf_range(-60, -20)), 0.5, 2.0, 1.2,
					Color(0.78, 0.76, 0.72), Color(0.5, 0.5, 0.5, 0.0), 220.0)
			"dust":
				_add(pos + Vector2(randf_range(-6, 6), randf_range(-3, 3)), Vector2(randf_range(-18, 18), randf_range(-14, -2)),
					0.8, 3.0, 8.0, Color(0.68, 0.6, 0.45, 0.55), Color(0.68, 0.6, 0.45, 0.0), 0.0)
			"smoke":
				_add(pos + Vector2(randf_range(-2, 2), 0), Vector2(randf_range(2, 9), randf_range(-22, -14)),
					2.4, 3.0, 10.0, Color(0.55, 0.55, 0.55, 0.5), Color(0.75, 0.75, 0.75, 0.0), -2.0)
			"fire":
				_add(pos + Vector2(randf_range(-5, 5), 0), Vector2(randf_range(-8, 8), randf_range(-38, -22)),
					0.6, 5.0, 1.0, Color(1.0, 0.9, 0.35, 0.95), Color(0.9, 0.2, 0.05, 0.0), -10.0)
			"clang":
				_add(pos, Vector2(randf_range(-70, 70), randf_range(-70, 20)), 0.22, 1.6, 0.5,
					Color(1, 1, 0.9), Color(1, 0.8, 0.4, 0.0), 0.0)
			"heal":
				_add(pos + Vector2(randf_range(-8, 8), randf_range(-6, 6)), Vector2(randf_range(-6, 6), randf_range(-30, -18)),
					0.8, 2.4, 0.8, Color(0.6, 1.0, 0.6, 0.95), Color(1.0, 1.0, 0.7, 0.0), 0.0)
			"debris":
				_add(pos + Vector2(randf_range(-30, 30), randf_range(-20, 20)), Vector2(randf_range(-40, 40), randf_range(-90, -30)),
					0.9, 3.0, 1.5, Color(0.5, 0.45, 0.4), Color(0.35, 0.3, 0.25, 0.0), 200.0)
	set_process(true)


func _add(pos: Vector2, vel: Vector2, life: float, s0: float, s1: float, c0: Color, c1: Color, g: float) -> void:
	_p.append([pos, vel, 0.0, life * randf_range(0.8, 1.2), s0, s1, c0, c1, g])


func _process(delta: float) -> void:
	var i := _p.size() - 1
	while i >= 0:
		var p: Array = _p[i]
		p[2] += delta
		if p[2] >= p[3]:
			_p[i] = _p[_p.size() - 1]
			_p.pop_back()
		else:
			p[1].y += p[8] * delta
			p[0] += p[1] * delta
		i -= 1
	queue_redraw()
	if _p.is_empty():
		set_process(false)


func _draw() -> void:
	for p in _p:
		var t: float = p[2] / p[3]
		draw_circle(p[0], lerpf(p[4], p[5], t), p[6].lerp(p[7], t))
