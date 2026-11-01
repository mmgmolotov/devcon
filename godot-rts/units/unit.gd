class_name Unit
extends Entity
## A mobile unit (villager, swordsman or archer).
##
## Behaviour is a small state machine. Movement follows waypoints from the
## map's AStarGrid2D; approach logic repaths periodically for moving targets.

enum State { IDLE, MOVE, ATTACK, GATHER, RETURN, BUILD }

const WORK_RANGE := 14.0
const SCAN_INTERVAL := 0.5

var type := "villager"
var data: Dictionary = {}
var state: State = State.IDLE
var speed := 70.0
var damage := 3.0
var attack_range := 14.0
var cooldown := 1.5
var sight := 150.0
var radius := 9.0
var ranged := false
var is_villager := false

var path := PackedVector2Array()
var path_index := 0
var repath_timer := 0.0
var scan_timer := 0.0
var attack_timer := 0.0
var flash_timer := 0.0
var facing := 1.0

var target = null           ## Entity being attacked or built.
var attack_move := false    ## Retarget to nearby enemies (used by AI waves).
var resource_target = null  ## ResourceNode being gathered.
var resource_type := ""     ## Resource this villager keeps working on.
var dropoff = null
var carry_type := ""
var carry_amount := 0
var gather_timer := 0.0


func setup(unit_type: String, unit_team: int) -> void:
	type = unit_type
	team = unit_team
	data = Game.UNIT_DATA[type]
	max_hp = data.hp
	hp = max_hp
	speed = data.speed
	damage = data.damage
	attack_range = data.range
	cooldown = data.cooldown
	sight = data.sight
	radius = data.radius
	ranged = data.get("ranged", false)
	is_villager = type == "villager"
	scan_timer = randf() * SCAN_INTERVAL


func _ready() -> void:
	Game.register_unit(self)


func get_display_name() -> String:
	return data.name


func get_radius() -> float:
	return radius


func get_status_text() -> String:
	match state:
		State.MOVE:
			return "Moving"
		State.ATTACK:
			return "Attacking"
		State.GATHER:
			return "Gathering %s (%d)" % [resource_type, carry_amount]
		State.RETURN:
			return "Returning %d %s" % [carry_amount, carry_type]
		State.BUILD:
			return "Building"
	if carry_amount > 0:
		return "Idle (carrying %d %s)" % [carry_amount, carry_type]
	return "Idle"


# --- Commands ------------------------------------------------------------------

func _clear_path() -> void:
	path = PackedVector2Array()
	path_index = 0
	repath_timer = 0.0


func _reset_orders() -> void:
	target = null
	attack_move = false
	_clear_path()


func command_move(pos: Vector2) -> void:
	_reset_orders()
	resource_type = ""
	path = Game.map.find_path(position, pos)
	state = State.MOVE if not path.is_empty() else State.IDLE


func command_stop() -> void:
	_reset_orders()
	resource_type = ""
	state = State.IDLE


func command_attack(e: Entity, aggressive := false) -> void:
	if e == self or not Game.alive(e) or e.team == team:
		return
	_reset_orders()
	target = e
	attack_move = aggressive
	state = State.ATTACK


func command_gather(r: ResourceNode) -> void:
	if not is_villager:
		command_move(r.position)
		return
	_reset_orders()
	resource_target = r
	resource_type = r.type
	if carry_amount > 0 and carry_type != r.type:
		carry_amount = 0
		queue_redraw()
	state = State.GATHER


func command_build(b: Building) -> void:
	if not is_villager:
		command_move(b.position)
		return
	_reset_orders()
	target = b
	state = State.BUILD


func command_return() -> void:
	if not is_villager or carry_amount <= 0:
		return
	_reset_orders()
	dropoff = null
	state = State.RETURN


# --- Simulation ----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if dead or Game.is_over:
		return
	attack_timer = maxf(attack_timer - delta, 0.0)
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			queue_redraw()
	match state:
		State.IDLE:
			_process_idle(delta)
		State.MOVE:
			if _follow_path(delta):
				state = State.IDLE
		State.ATTACK:
			_process_attack(delta)
		State.GATHER:
			_process_gather(delta)
		State.RETURN:
			_process_return(delta)
		State.BUILD:
			_process_build(delta)


func _process_idle(delta: float) -> void:
	if is_villager:
		return
	scan_timer -= delta
	if scan_timer > 0.0:
		return
	scan_timer = SCAN_INTERVAL
	var e := Game.find_nearest_enemy(team, position, sight)
	if e != null:
		command_attack(e)


func _process_attack(delta: float) -> void:
	if not Game.alive(target):
		target = null
		if attack_move:
			var nxt := Game.find_nearest_enemy(team, position, Game.FAR)
			if nxt != null:
				target = nxt
				_clear_path()
				return
		attack_move = false
		state = State.IDLE
		scan_timer = 0.0
		return
	# Units on an attack-move (and soldiers hitting buildings) switch to
	# enemy units that come close, so waves fight back instead of ignoring them.
	if not is_villager and target is Building:
		scan_timer -= delta
		if scan_timer <= 0.0:
			scan_timer = SCAN_INTERVAL
			var e := Game.find_nearest_enemy(team, position, sight * 0.8, true)
			if e != null:
				target = e
				_clear_path()
	if _approach(target, attack_range, delta):
		if attack_timer <= 0.0:
			attack_timer = cooldown
			_strike(target)


func _strike(t: Entity) -> void:
	flash_timer = 0.12
	facing = signf(t.position.x - position.x) if t.position.x != position.x else facing
	queue_redraw()
	var dmg := damage
	if t is Building:
		dmg *= data.building_mult
	if ranged:
		Game.spawn_projectile(self, t, dmg)
	else:
		t.take_damage(dmg, self)


func _process_gather(delta: float) -> void:
	if carry_amount >= Game.CARRY_CAPACITY:
		_go_return()
		return
	if not Game.alive(resource_target):
		resource_target = Game.find_nearest_resource(resource_type, position, 480.0)
		_clear_path()
		if resource_target == null:
			if carry_amount > 0:
				_go_return()
			else:
				state = State.IDLE
			return
	if _approach(resource_target, WORK_RANGE, delta):
		gather_timer += delta
		var interval: float = 1.0 / Game.GATHER_RATES[resource_type]
		if gather_timer >= interval:
			gather_timer -= interval
			if carry_type != resource_target.type:
				carry_amount = 0
				carry_type = resource_target.type
			carry_amount += resource_target.harvest(1)
			flash_timer = 0.08
			queue_redraw()


func _go_return() -> void:
	dropoff = null
	_clear_path()
	state = State.RETURN


func _process_return(delta: float) -> void:
	if not Game.alive(dropoff):
		dropoff = Game.find_nearest_dropoff(team, position)
		_clear_path()
		if dropoff == null:
			state = State.IDLE
			return
	if _approach(dropoff, WORK_RANGE, delta):
		if carry_amount > 0:
			Game.add_resource(team, carry_type, carry_amount)
		carry_amount = 0
		queue_redraw()
		_clear_path()
		state = State.GATHER if resource_type != "" else State.IDLE


func _process_build(delta: float) -> void:
	if not Game.alive(target) or target.constructed:
		target = Game.find_unfinished_building(team, position, 260.0)
		_clear_path()
		if target == null:
			state = State.GATHER if resource_type != "" else State.IDLE
		return
	if _approach(target, WORK_RANGE, delta):
		target.add_build_work(delta)


# --- Movement --------------------------------------------------------------------

## Moves toward obj until within `reach` of its edge. Returns true when in range.
func _approach(obj, reach: float, delta: float) -> bool:
	if obj.distance_to_edge(position) - radius <= reach:
		return true
	repath_timer -= delta
	if repath_timer <= 0.0:
		if obj is Unit:
			repath_timer = 0.7
			path = Game.map.find_path(position, obj.position)
		else:
			repath_timer = 3.0
			path = Game.map.find_path_to_rect(position, obj.get_rect())
		path_index = 0
	if path_index < path.size():
		_follow_path(delta)
	else:
		_move_toward(obj.nearest_point_to(position), delta)
	return false


## Advances along the current path. Returns true when the path is finished.
func _follow_path(delta: float) -> bool:
	if path_index >= path.size():
		return true
	if _move_toward(path[path_index], delta):
		path_index += 1
	return path_index >= path.size()


func _move_toward(p: Vector2, delta: float) -> bool:
	var to := p - position
	var step := speed * delta
	var dist := to.length()
	if absf(to.x) > 0.5:
		facing = signf(to.x)
	if dist <= step:
		position = p
		return true
	position += to / dist * step
	return false


func _on_damaged(attacker) -> void:
	if not Game.alive(attacker) or attacker.team == team:
		return
	if state == State.IDLE:
		command_attack(attacker)
	elif state == State.ATTACK and not is_villager and target is Building and attacker is Unit:
		target = attacker
		_clear_path()


# --- Drawing ---------------------------------------------------------------------

func _draw() -> void:
	var col: Color = Game.TEAM_COLORS[team]
	var outline := col.darkened(0.55)
	draw_set_transform(Vector2(0, radius * 0.7), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, radius + 1.0, Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if selected:
		draw_arc(Vector2(0, 2), radius + 5.0, 0.0, TAU, 28, Color(0.45, 1.0, 0.45), 2.0)
	match type:
		"villager":
			draw_circle(Vector2.ZERO, radius, outline)
			draw_circle(Vector2.ZERO, radius - 2.0, col)
			draw_circle(Vector2(0, -2), 3.5, Color(0.96, 0.8, 0.62))
			if carry_amount > 0:
				draw_rect(Rect2(3, -1, 7, 7), Game.RESOURCE_COLORS[carry_type])
				draw_rect(Rect2(3, -1, 7, 7), Color(0, 0, 0, 0.6), false, 1.0)
		"swordsman":
			var r := Rect2(-radius, -radius, radius * 2.0, radius * 2.0)
			draw_rect(r, outline)
			draw_rect(r.grow(-2.0), col)
			draw_rect(Rect2(-4, -5, 8, 6), Color(0.75, 0.75, 0.8))
			draw_line(Vector2(6 * facing, 4), Vector2(15 * facing, -9), Color(0.85, 0.85, 0.9), 2.5)
			draw_line(Vector2(4 * facing, -1), Vector2(9 * facing, 3), Color(0.45, 0.3, 0.15), 2.0)
		"archer":
			var pts := PackedVector2Array([Vector2(0, -radius - 2), Vector2(radius + 1, radius), Vector2(-radius - 1, radius)])
			draw_colored_polygon(pts, outline)
			var inner := PackedVector2Array([Vector2(0, -radius + 2), Vector2(radius - 2, radius - 2), Vector2(-radius + 2, radius - 2)])
			draw_colored_polygon(inner, col)
			draw_arc(Vector2(5 * facing, 0), 9.0, -1.2 + (0.0 if facing > 0 else PI), 1.2 + (0.0 if facing > 0 else PI), 10, Color(0.5, 0.32, 0.12), 2.0)
	if flash_timer > 0.0:
		draw_circle(Vector2.ZERO, radius + 2.0, Color(1, 1, 1, 0.3))
	if selected or hp < max_hp:
		draw_health_bar(22.0, -radius - 10.0)
