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

# Animation (drawing is throttled to ANIM_FPS while something moves).
const ANIM_FPS := 15.0
var walk_phase := 0.0
var _working := false
var _work_time := 0.0
var _last_pos := Vector2.ZERO
var _anim_accum := 0.0
var _was_animated := false
var _dust_timer := 0.0


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
	_last_pos = position


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
	flash_timer = maxf(flash_timer - delta, 0.0)
	_working = false
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
	_animate(delta)


func _animate(delta: float) -> void:
	var moved := position.distance_squared_to(_last_pos) > 0.04
	if moved:
		walk_phase += delta * speed * 0.17
	elif not _working:
		walk_phase = 0.0
	_last_pos = position
	if _working:
		_work_time += delta
	var animated := moved or _working
	if animated:
		_anim_accum += delta
		if _anim_accum >= 1.0 / ANIM_FPS:
			_anim_accum = 0.0
			queue_redraw()
	elif _was_animated:
		queue_redraw()
	_was_animated = animated


## Tool swing phase 0..1 (strike at 1) for the current activity, or -1.
func _work_phase() -> float:
	if not _working:
		return -1.0
	match state:
		State.ATTACK:
			return clampf(1.0 - attack_timer / cooldown, 0.0, 1.0)
		State.GATHER:
			return clampf(gather_timer * Game.GATHER_RATES.get(resource_type, 1.0), 0.0, 1.0)
		State.BUILD:
			return fmod(_work_time * 1.6, 1.0)
	return -1.0


func _tool() -> String:
	match type:
		"swordsman":
			return "sword"
		"archer":
			return "bow"
	if state == State.BUILD:
		return "hammer"
	var r := resource_type if resource_type != "" else carry_type
	if r == "wood":
		return "axe"
	if r == "gold" or r == "stone":
		return "pick"
	return ""


func _face(p: Vector2) -> void:
	if absf(p.x - position.x) > 1.0:
		facing = signf(p.x - position.x)


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
		_working = true
		_face(target.position)
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
		Game.emit_fx("clang" if t is Unit else "dust", t.nearest_point_to(position) + Vector2(0, -8), 4)
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
		_working = true
		_face(resource_target.position)
		gather_timer += delta
		var interval: float = 1.0 / Game.GATHER_RATES[resource_type]
		if gather_timer >= interval:
			gather_timer -= interval
			if carry_type != resource_target.type:
				carry_amount = 0
				carry_type = resource_target.type
			Game.emit_fx(resource_target.type, resource_target.position + Vector2(0, -6), 3)
			carry_amount += resource_target.harvest(1)
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
		_working = true
		_face(target.position)
		target.add_build_work(delta)
		_dust_timer -= delta
		if _dust_timer <= 0.0:
			_dust_timer = 0.6
			Game.emit_fx("dust", target.nearest_point_to(position), 2)


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

func die() -> void:
	if dead:
		return
	Game.spawn_decal("corpse", position, {"team_color": Game.TEAM_COLORS[team], "unit_type": type, "facing": facing})
	Game.emit_fx("dust", position, 4)
	super.die()


func _draw() -> void:
	var col: Color = Game.TEAM_COLORS[team]
	Art.shadow(self, Vector2(0, 7), radius * 0.95, radius * 0.42)
	if selected:
		Art.ellipse_outline(self, Vector2(0, 7), radius + 5.0, (radius + 5.0) * 0.5, Color(0.45, 1.0, 0.45), 2.0)
	var carry := carry_type if carry_amount > 0 else ""
	draw_set_transform(Vector2(0, 7), 0.0, Vector2.ONE)
	Art.draw_person(self, type, col, facing, walk_phase, _work_phase(), _tool(), carry)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if selected or hp < max_hp:
		draw_health_bar(22.0, -radius - 20.0)
