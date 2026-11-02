extends Node2D
## Arrow fired by archers and Town Centers. Homes in on its target along the
## ground while following a parabolic arc in height (with a ground shadow).

const SPEED := 400.0

var target = null
var attacker = null
var damage := 1.0
var splash := 0.0
var _team := 0
var _aim := Vector2.ZERO
var _total := 1.0
var _travelled := 0.0
var _height := 0.0
var _angle := 0.0


func setup(from: Entity, to: Entity, dmg: float, splash_radius := 0.0) -> void:
	attacker = from
	target = to
	damage = dmg
	splash = splash_radius
	_team = from.team
	position = from.position
	_aim = to.position
	_total = maxf(position.distance_to(_aim), 1.0)


func _physics_process(delta: float) -> void:
	if Game.alive(target):
		_aim = target.position
	var to := _aim - position
	var step := SPEED * delta
	if to.length() <= step + 4.0:
		if splash > 0.0:
			Game.splash_damage(_team, _aim, splash, damage, attacker)
			Game.emit_fx("debris", _aim, 6)
			Game.emit_fx("dust", _aim, 8)
			Sound.play("stone_hit", _aim)
		elif Game.alive(target):
			target.take_damage(damage, attacker if Game.alive(attacker) else null)
		queue_free()
		return
	position += to.normalized() * step
	_travelled += step
	var t := clampf(_travelled / maxf(_total, _travelled + to.length()), 0.0, 1.0)
	var peak := clampf(_total * (0.4 if splash > 0.0 else 0.22), 10.0, 110.0)
	var new_height := sin(PI * t) * peak + 14.0 * (1.0 - t)
	var ground_dir := to.normalized() * step
	_angle = Vector2(ground_dir.x, ground_dir.y - (new_height - _height)).angle()
	_height = new_height
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(0, 2), 1.6 if splash <= 0.0 else 4.0, Color(0, 0, 0, 0.25))
	if splash > 0.0:
		draw_circle(Vector2(0, -_height), 5.5, Color(0.12, 0.1, 0.08))
		draw_circle(Vector2(0, -_height), 4.5, Color(0.55, 0.53, 0.5))
		draw_circle(Vector2(-1.5, -_height - 1.5), 1.8, Color(0.75, 0.73, 0.7))
		return
	draw_set_transform(Vector2(0, -_height), _angle, Vector2.ONE)
	draw_line(Vector2(-9, 0), Vector2(6, 0), Color(0.4, 0.26, 0.12), 1.8)
	draw_line(Vector2(-9, 0), Vector2(-6, -2), Color(0.95, 0.95, 0.9), 1.2)
	draw_line(Vector2(-9, 0), Vector2(-6, 2), Color(0.95, 0.95, 0.9), 1.2)
	draw_colored_polygon(PackedVector2Array([Vector2(9, 0), Vector2(5, -2.2), Vector2(5, 2.2)]), Color(0.8, 0.8, 0.85))
