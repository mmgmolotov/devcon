extends Node2D
## Arrow fired by archers and Town Centers. Homes in on its target.

const SPEED := 420.0

var target = null
var attacker = null
var damage := 1.0
var _aim := Vector2.ZERO


func setup(from: Entity, to: Entity, dmg: float) -> void:
	attacker = from
	target = to
	damage = dmg
	position = from.position + Vector2(0, -6)
	_aim = to.position
	rotation = (_aim - position).angle()


func _physics_process(delta: float) -> void:
	if Game.alive(target):
		_aim = target.position
	var to := _aim - position
	var step := SPEED * delta
	if to.length() <= step + 4.0:
		if Game.alive(target):
			target.take_damage(damage, attacker if Game.alive(attacker) else null)
		queue_free()
		return
	rotation = to.angle()
	position += to.normalized() * step


func _draw() -> void:
	draw_line(Vector2(-8, 0), Vector2(5, 0), Color(0.35, 0.22, 0.1), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(8, 0), Vector2(3, -3), Vector2(3, 3)]), Color(0.85, 0.85, 0.85))
