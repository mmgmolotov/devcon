class_name Unit
extends Entity
## A mobile unit: villager, soldier, monk or animal.
##
## Behaviour is a small state machine. Movement follows waypoints from the
## map's AStarGrid2D. Visuals come from LPC sprite sheets (see
## tools/build_unit_sprites.py): 4-direction walk, attack/work and death
## animations, animated at ANIM_FPS through a Sprite2D region.

enum State { IDLE, MOVE, ATTACK, GATHER, RETURN, BUILD, HEAL }

const WORK_RANGE := 14.0
const SCAN_INTERVAL := 0.5
const ANIM_FPS := 10.0
const DIR_UP := 0
const DIR_LEFT := 1
const DIR_DOWN := 2
const DIR_RIGHT := 3

var type := "villager"
var data: Dictionary = {}
var state: State = State.IDLE
var speed := 70.0
var damage := 3.0
var attack_range := 14.0
var cooldown := 1.5
var sight := 150.0
var radius := 10.0
var ranged := false
var is_villager := false
var is_animal := false
var is_monk := false
var animal_mode := ""

var path := PackedVector2Array()
var path_index := 0
var repath_timer := 0.0
var scan_timer := 0.0
var attack_timer := 0.0
var flash_timer := 0.0
var facing := 1.0
var move_dir := Vector2.ZERO  ## Unit vector of current movement (zero when still).

var target = null           ## Entity being attacked, built or healed.
var attack_move := false    ## Retarget to nearby enemies (used by AI waves).
var resource_target = null  ## ResourceNode being gathered.
var resource_type := ""     ## Resource this villager keeps working on.
var dropoff = null
var carry_type := ""
var carry_amount := 0
var gather_timer := 0.0
var home := Vector2.ZERO     ## Animals wander around here.

var _working := false
var _work_time := 0.0
var _last_pos := Vector2.ZERO
var _dir := DIR_DOWN
var _anim := ""
var _frame := 0
var _anim_t := 0.0
var _dust_timer := 0.0
var _wander_timer := 0.0
var _hunting := false
var _sprite: Sprite2D
var _ground: GroundMark
var _meta := {}


## Shadow and selection ring, drawn underneath the sprite.
class GroundMark extends Node2D:
	var unit: Unit

	func _draw() -> void:
		Art.shadow(self, Vector2(0, 6), unit.radius * 0.95, unit.radius * 0.4)
		if unit.selected:
			Art.ellipse_outline(self, Vector2(0, 6), unit.radius + 5.0, (unit.radius + 5.0) * 0.5, Color(0.45, 1.0, 0.45), 2.0)


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
	is_monk = data.has("heal")
	animal_mode = data.get("animal", "")
	is_animal = animal_mode != ""
	scan_timer = randf() * SCAN_INTERVAL
	_wander_timer = randf_range(1.0, 5.0)


func _ready() -> void:
	Game.register_unit(self)
	_last_pos = position
	home = position
	_ground = GroundMark.new()
	_ground.unit = self
	_ground.show_behind_parent = true
	add_child(_ground)
	_sprite = Sprite2D.new()
	_sprite.texture = Game.unit_texture(type, team)
	_sprite.centered = false
	_sprite.region_enabled = true
	_sprite.show_behind_parent = true
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_sprite)
	if not is_animal:
		_meta = Game.sprite_meta(type)
	_set_anim(_idle_anim(), true)


func get_display_name() -> String:
	return data.name


func get_radius() -> float:
	return radius


func get_status_text() -> String:
	match state:
		State.MOVE:
			return "Moving"
		State.ATTACK:
			return "Hunting" if _hunting else "Attacking"
		State.GATHER:
			return "Gathering %s (%d)" % [resource_type, carry_amount]
		State.RETURN:
			return "Returning %d %s" % [carry_amount, carry_type]
		State.BUILD:
			return "Building"
		State.HEAL:
			return "Healing"
	if is_animal:
		return "Grazing"
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
	_hunting = false
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
	if is_monk:
		command_move(e.position)
		return
	_reset_orders()
	target = e
	attack_move = aggressive
	_hunting = e is Unit and e.is_animal
	state = State.ATTACK


func command_heal(e: Unit) -> void:
	if not is_monk or not Game.alive(e) or e.team != team or e == self:
		return
	_reset_orders()
	target = e
	state = State.HEAL


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
		State.HEAL:
			_process_heal(delta)
	_animate(delta)


func _process_idle(delta: float) -> void:
	if is_animal:
		_process_animal_idle(delta)
		return
	if is_villager:
		return
	scan_timer -= delta
	if scan_timer > 0.0:
		return
	scan_timer = SCAN_INTERVAL
	if is_monk:
		var hurt := _find_hurt_ally()
		if hurt != null:
			command_heal(hurt)
		return
	var e := Game.find_nearest_enemy(team, position, sight)
	if e != null:
		command_attack(e)


func _process_animal_idle(delta: float) -> void:
	scan_timer -= delta
	if animal_mode == "flee" and scan_timer <= 0.0:
		scan_timer = SCAN_INTERVAL
		var threat := Game.find_nearest_enemy(team, position, sight, true)
		if threat != null:
			_flee_from(threat.position)
			return
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(3.0, 8.0)
		var p := home + Vector2(randf_range(-60, 60), randf_range(-60, 60))
		path = Game.map.find_path(position, p)
		path_index = 0
		if not path.is_empty():
			state = State.MOVE


func _flee_from(p: Vector2) -> void:
	var away := (position - p).normalized()
	if away == Vector2.ZERO:
		away = Vector2.RIGHT.rotated(randf() * TAU)
	path = Game.map.find_path(position, position + away * 160.0)
	path_index = 0
	state = State.MOVE if not path.is_empty() else State.IDLE
	home = position + away * 160.0


func _find_hurt_ally() -> Unit:
	var best: Unit = null
	var best_d := sight
	for u in Game.units:
		if u.team == team and u != self and not u.dead and u.hp < u.max_hp:
			var d: float = u.position.distance_to(position)
			if d < best_d:
				best_d = d
				best = u
	return best


func _process_heal(delta: float) -> void:
	if not Game.alive(target) or target.hp >= target.max_hp:
		target = null
		state = State.IDLE
		scan_timer = 0.0
		return
	if _approach(target, attack_range, delta):
		_working = true
		_face(target.position)
		target.hp = minf(target.max_hp, target.hp + data.heal * delta)
		target.queue_redraw()
		_dust_timer -= delta
		if _dust_timer <= 0.0:
			_dust_timer = 0.5
			Game.emit_fx("heal", target.position + Vector2(0, -18), 3)


func _process_attack(delta: float) -> void:
	if not Game.alive(target):
		var was_hunting := _hunting
		target = null
		_hunting = false
		if was_hunting and is_villager:
			var meat := Game.find_nearest_resource("food", position, 60.0)
			if meat != null:
				command_gather(meat)
				return
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
	if is_animal and target.position.distance_to(home) > 280.0:
		target = null
		command_move(home)
		return
	# Soldiers hitting buildings switch to enemy units that come close.
	if not is_villager and not is_animal and target is Building:
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
	var dmg := damage
	if t is Building:
		dmg *= data.get("building_mult", 1.0)
	elif t is Unit:
		dmg *= data.get("bonus", {}).get(t.type, 1.0)
	if ranged:
		Game.spawn_projectile(self, t, dmg)
	else:
		Game.emit_fx("clang" if t is Unit else "dust", t.nearest_point_to(position) + Vector2(0, -10), 4)
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
		var interval: float = 1.0 / (Game.GATHER_RATES[resource_type] * resource_target.gather_mult)
		if gather_timer >= interval:
			gather_timer -= interval
			if carry_type != resource_target.type:
				carry_amount = 0
				carry_type = resource_target.type
			var fx_kind: String = {"wood": "wood", "gold": "gold", "stone": "stone"}.get(resource_target.type, "dust")
			Game.emit_fx(fx_kind, resource_target.nearest_point_to(position) + Vector2(0, -6), 3)
			carry_amount += resource_target.harvest(1)
			queue_redraw()


func _go_return() -> void:
	dropoff = null
	_clear_path()
	state = State.RETURN


func _process_return(delta: float) -> void:
	if not Game.alive(dropoff):
		dropoff = Game.find_nearest_dropoff(team, position, carry_type)
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
		elif obj is ResourceNode and not obj.blocking:
			repath_timer = 3.0
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
	if dist > 0.001:
		move_dir = to / dist
	if dist <= step:
		position = p
		return true
	position += to / dist * step
	return false


func _face(p: Vector2) -> void:
	_set_dir(p - position)


func _set_dir(v: Vector2) -> void:
	if v.length_squared() < 0.01:
		return
	if absf(v.x) > absf(v.y) * 0.8:
		_dir = DIR_RIGHT if v.x > 0.0 else DIR_LEFT
	else:
		_dir = DIR_DOWN if v.y > 0.0 else DIR_UP
	facing = -1.0 if _dir == DIR_LEFT else 1.0


func _on_damaged(attacker) -> void:
	if not Game.alive(attacker) or attacker.team == team:
		return
	if is_animal:
		match animal_mode:
			"flee":
				_flee_from(attacker.position)
			"aggressive":
				if state != State.ATTACK:
					command_attack(attacker)
		return
	if state == State.IDLE:
		command_attack(attacker)
	elif state == State.ATTACK and not is_villager and Game.alive(target) and target is Building and attacker is Unit:
		target = attacker
		_clear_path()


func die() -> void:
	if dead:
		return
	if is_animal:
		var r := Game.map.add_resource_node("carcass", Game.map.world_to_cell(position), Vector2i.ONE)
		r.position = position
		r.amount = int(data.food)
		r.carcass_texture = _sprite.texture
		r.carcass_region = _sprite.region_rect
	else:
		var hurt: Dictionary = _meta.get("hurt", {})
		if not hurt.is_empty():
			var c: float = hurt.cell
			Game.spawn_decal("sprite", position, {"texture": _sprite.texture,
				"region": Rect2((hurt.frames - 1) * c, hurt.y, c, c), "offset": _sprite.offset})
	Game.emit_fx("dust", position, 4)
	super.die()


# --- Animation -------------------------------------------------------------------

func _tool() -> String:
	if state == State.BUILD:
		return "hammer"
	var r := resource_type if resource_type != "" else carry_type
	if state == State.ATTACK and _hunting:
		return "axe"
	match r:
		"wood":
			return "axe"
		"gold", "stone":
			return "pickaxe"
	return "axe"


func _idle_anim() -> String:
	if is_animal:
		return "walk"
	return "walk_" + _tool() if is_villager else "walk"


func _animate(delta: float) -> void:
	var moved := position.distance_squared_to(_last_pos) > 0.04
	if not moved and state != State.MOVE and path_index >= path.size():
		move_dir = Vector2.ZERO
	if moved:
		_set_dir(position - _last_pos)
	_last_pos = position
	var anim := _idle_anim()
	if _working:
		_work_time += delta
		if is_animal:
			anim = "walk"
		elif is_villager:
			anim = "work_" + _tool()
		else:
			anim = "attack"
	elif not moved and is_animal and animal_mode != "flee":
		anim = "eat"
	_set_anim(anim)
	var info := _anim_info(_anim)
	var frames: int = info.frames
	if _working and not is_animal and state == State.ATTACK and not is_villager:
		# Attack animation is timed so the blow lands when the cooldown ends.
		_set_frame(clampi(int((1.0 - attack_timer / cooldown) * frames), 0, frames - 1))
	elif _working or moved or _anim == "eat":
		_anim_t += delta * ANIM_FPS
		if _anim_t >= 1.0:
			_anim_t -= 1.0
			var first := 1 if _anim.begins_with("walk") and not is_animal else 0
			var nf := _frame + 1
			if nf >= frames:
				nf = first
			_set_frame(nf)
	elif _frame != 0:
		_set_frame(0)


## Frame layout for an animation: {y, cell, frames, rows}.
func _anim_info(anim: String) -> Dictionary:
	if is_animal:
		match type:
			"sheep":
				return {"y": 0 if anim == "walk" else 256, "cell": 64, "frames": 4, "rows": 4}
			"boar":
				return {"y": 0, "cell": 64, "frames": 4, "rows": 4}
			"deer":
				var row := 2 if state == State.MOVE and animal_mode == "flee" else (0 if anim == "walk" else 1)
				return {"y": row * 48, "cell": 48, "frames": 5, "rows": 1}
	return _meta.get(anim, _meta.get("walk", {"y": 0, "cell": 48, "frames": 1, "rows": 4}))


func _set_anim(anim: String, force := false) -> void:
	if anim == _anim and not force:
		return
	_anim = anim
	_frame = 0
	_anim_t = 0.0
	_update_region()


func _set_frame(f: int) -> void:
	if f == _frame:
		return
	_frame = f
	_update_region()


func _update_region() -> void:
	if _sprite == null:
		return
	var info := _anim_info(_anim)
	var c: float = info.cell
	var row := 0
	if info.rows == 4:
		row = _dir
	var frame := mini(_frame, int(info.frames) - 1)
	_sprite.region_rect = Rect2(frame * c, float(info.y) + row * c, c, c)
	_sprite.flip_h = type == "deer" and _dir == DIR_LEFT
	# Feet sit ~94% down a 64 px LPC frame; oversized frames are centred.
	var feet := c * 0.94 if c <= 64.0 else c * 0.5 + c * 0.22
	if is_animal:
		feet = c * 0.78 if type != "deer" else c * 0.9
	_sprite.offset = Vector2(-c * 0.5, 7.0 - feet)


# --- Drawing ---------------------------------------------------------------------

func _draw() -> void:
	if _ground != null:
		_ground.queue_redraw()
	if carry_amount > 0:
		var c: Color = Game.RESOURCE_COLORS.get(carry_type, Color.WHITE)
		var p := Vector2(-9.0 * facing, -20.0)
		Art.ellipse(self, p, 5.0, 4.0, Art.OUTLINE, 10)
		Art.ellipse(self, p, 4.0, 3.2, c, 10)
	if selected or hp < max_hp:
		draw_health_bar(24.0, -46.0 if not is_animal else -26.0)
