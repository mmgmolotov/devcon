extends Node2D
## Short-lived ring shown where a command was given.

const LIFETIME := 0.45

var color := Color.WHITE
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var f := _t / LIFETIME
	draw_arc(Vector2.ZERO, 6.0 + f * 22.0, 0.0, TAU, 24, Color(color, 1.0 - f), 3.0)
