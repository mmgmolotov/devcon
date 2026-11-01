class_name Entity
extends Node2D
## Base class for anything with a team and hit points (units and buildings).

signal died(entity: Entity)

var team := 0
var max_hp := 100.0
var hp := 100.0
var dead := false
var selected := false:
	set(value):
		selected = value
		queue_redraw()


## Keeps the global registry free of stale references when a scene is
## unloaded (e.g. "Play Again") without the entity dying normally.
func _exit_tree() -> void:
	Game.units.erase(self)
	Game.buildings.erase(self)
	Game.selected.erase(self)


func get_display_name() -> String:
	return "Entity"


func get_radius() -> float:
	return 10.0


## Distance from a point to this entity's outline (0 when inside).
func distance_to_edge(p: Vector2) -> float:
	return maxf(position.distance_to(p) - get_radius(), 0.0)


## Closest point of this entity to p; used to approach large targets.
func nearest_point_to(_p: Vector2) -> Vector2:
	return position


func take_damage(amount: float, attacker = null) -> void:
	if dead:
		return
	hp -= amount
	queue_redraw()
	if hp <= 0.0:
		die()
	else:
		_on_damaged(attacker)


func _on_damaged(_attacker) -> void:
	pass


func die() -> void:
	if dead:
		return
	dead = true
	selected = false
	died.emit(self)
	Game.on_entity_died(self)
	queue_free()


func draw_health_bar(width: float, y: float) -> void:
	var r := Rect2(-width * 0.5, y, width, 4.0)
	draw_rect(r.grow(1.0), Color(0, 0, 0, 0.75))
	var f := clampf(hp / max_hp, 0.0, 1.0)
	var c := Color(0.25, 0.9, 0.3)
	if f < 0.25:
		c = Color(0.95, 0.25, 0.2)
	elif f < 0.5:
		c = Color(0.95, 0.8, 0.2)
	draw_rect(Rect2(r.position, Vector2(width * f, 4.0)), c)
