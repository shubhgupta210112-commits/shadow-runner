extends CharacterBody2D
## Three enemy types sharing one state machine: "crawler" (lunging ground beast),
## "drone" (flying shooter) and "brute" (heavy slammer).

const SpriteUtil = preload("res://scripts/sprite_util.gd")
const Fx = preload("res://scripts/fx.gd")
const ProjectileScript = preload("res://scripts/projectile.gd")
const PickupScript = preload("res://scripts/pickup.gd")

const GRAVITY := 2200.0
const ANIM_NAMES := ["idle", "move", "attack", "hurt", "dead"]
const ANIM_LOOPS := [true, true, false, false, false]

const CFG := {
	"crawler": {"sheet": "res://assets/enemies/crawler_sheet.png", "fw": 160, "counts": [4, 6, 6, 3, 6],
		"fps": [8.0, 14.0, 14.0, 14.0, 12.0], "scale": 0.95, "feet": 66.0, "hp": 2, "touch": 10, "xoff": 0.0},
	"drone": {"sheet": "res://assets/enemies/drone_sheet.png", "fw": 160, "counts": [4, 6, 6, 3, 6],
		"fps": [8.0, 12.0, 12.0, 14.0, 10.0], "scale": 0.9, "feet": 0.0, "hp": 2, "touch": 8, "xoff": 0.0},
	"brute": {"sheet": "res://assets/enemies/brute_sheet.png", "fw": 224, "counts": [4, 6, 6, 3, 6],
		"fps": [6.0, 9.0, 10.0, 12.0, 8.0], "scale": 0.85, "feet": 103.0, "hp": 6, "touch": 14, "xoff": 13.0},
}

var kind: String = "crawler"
var patrol_a: float = 0.0
var patrol_b: float = 0.0
var hp: int = 2
var facing: int = -1
var sprite: AnimatedSprite2D
var state: String = "patrol"

var _scale: float = 1.0
var _xoff: float = 0.0
var _touch: int = 10
var _dead: bool = false
var _hurt_t: float = 0.0
var _state_t: float = 0.0
var _attack_cd: float = 1.0
var _did_hit: bool = false
var _flash: float = 0.0
var _hit_area: Area2D
var _player: Node2D
var _home_y: float = 0.0
var _t: float = 0.0


func _ready() -> void:
	add_to_group("enemy")
	collision_layer = 8
	collision_mask = 1
	var cfg: Dictionary = CFG[kind]
	hp = int(cfg["hp"])
	_scale = float(cfg["scale"])
	_touch = int(cfg["touch"])
	_xoff = float(cfg["xoff"])
	var fw: int = int(cfg["fw"])
	var counts: Array = cfg["counts"]
	var fps: Array = cfg["fps"]
	var anims: Array = []
	for i in range(ANIM_NAMES.size()):
		anims.append([ANIM_NAMES[i], counts[i], fps[i], ANIM_LOOPS[i]])

	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = SpriteUtil.make_frames(String(cfg["sheet"]), fw, fw, anims)
	sprite.scale = Vector2(_scale, _scale)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.play("idle")
	add_child(sprite)

	var body_size := Vector2(84, 66)
	var body_pos := Vector2(0, -34)
	match kind:
		"crawler":
			body_size = Vector2(88, 72)
			body_pos = Vector2(0, -36)
			sprite.position = Vector2(0, -float(cfg["feet"]) * _scale)
		"drone":
			body_size = Vector2(70, 70)
			body_pos = Vector2(0, 0)
			sprite.position = Vector2(0, 2)
			_home_y = global_position.y
		"brute":
			body_size = Vector2(84, 150)
			body_pos = Vector2(0, -75)
			sprite.position = Vector2(0, -float(cfg["feet"]) * _scale)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = body_size
	cs.shape = sh
	cs.position = body_pos
	add_child(cs)

	_hit_area = Area2D.new()
	_hit_area.collision_layer = 0
	_hit_area.collision_mask = 2
	var hcs := CollisionShape2D.new()
	var hsh := RectangleShape2D.new()
	hsh.size = body_size * 0.9
	hcs.shape = hsh
	hcs.position = body_pos
	_hit_area.add_child(hcs)
	add_child(_hit_area)

	var eye := PointLight2D.new()
	eye.texture = load("res://assets/effects/light.png")
	eye.color = Color(1.0, 0.4, 0.3) if kind != "drone" else Color(1.0, 0.3, 0.3)
	eye.energy = 0.45
	eye.texture_scale = 1.1 if kind != "brute" else 1.6
	eye.position = body_pos
	add_child(eye)
	z_index = 4
	_attack_cd = randf_range(0.8, 1.6)
	_t = randf() * 6.0
	if patrol_b <= patrol_a:
		patrol_a = global_position.x - 150.0
		patrol_b = global_position.x + 150.0
	_face(facing)


func _face(dir: int) -> void:
	if dir == 0:
		return
	facing = dir
	sprite.flip_h = facing < 0
	sprite.position.x = -_xoff * _scale * float(facing)


func _get_player() -> Node2D:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	return _player


func _physics_process(delta: float) -> void:
	_t += delta
	_hurt_t = maxf(_hurt_t - delta, 0.0)
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_state_t += delta
	if _flash > 0.0:
		_flash -= delta
		sprite.modulate = Color(2.2, 2.2, 2.2, 1.0) if _flash > 0.0 else Color(1, 1, 1, 1)

	if _dead:
		if kind != "drone":
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			velocity.y += GRAVITY * delta
			move_and_slide()
		else:
			velocity.y = minf(velocity.y + 500.0 * delta, 300.0)
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
			global_position += velocity * delta
		return

	var pl = _get_player()
	var dx := 9999.0
	var dy := 9999.0
	if pl != null and not pl.get("dead"):
		dx = pl.global_position.x - global_position.x
		dy = pl.global_position.y - global_position.y

	if _hurt_t > 0.0:
		_apply_gravity(delta)
		velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
		if kind == "drone":
			global_position += velocity * delta
		else:
			move_and_slide()
		return

	match kind:
		"crawler":
			_ai_crawler(delta, dx, dy)
		"drone":
			_ai_drone(delta, dx, dy)
		"brute":
			_ai_brute(delta, dx, dy)

	# contact damage
	var touching: Array = _hit_area.get_overlapping_bodies()
	for b in touching:
		if b.is_in_group("player"):
			b.take_damage(_touch, global_position)


func _apply_gravity(delta: float) -> void:
	if kind != "drone":
		velocity.y = minf(velocity.y + GRAVITY * delta, 1200.0)


func _play(anim: String) -> void:
	if sprite.animation != anim:
		sprite.play(anim)


# ------------------------------------------------------------------ crawler
func _ai_crawler(delta: float, dx: float, dy: float) -> void:
	_apply_gravity(delta)
	var seen := absf(dx) < 420.0 and absf(dy) < 160.0
	if state == "lunge":
		velocity.x = float(facing) * 430.0
		if _state_t > 0.3:
			_enter("recover")
			velocity.x = 0.0
	elif state == "windup":
		velocity.x = 0.0
		if _state_t > 0.28:
			_enter("lunge")
			_play("attack")
			sprite.frame = 2
	elif state == "recover":
		velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)
		if _state_t > 0.5:
			_enter("patrol")
			_attack_cd = randf_range(1.4, 2.2)
	else:
		if seen:
			_face(1 if dx > 0.0 else -1)
			if absf(dx) < 240.0 and _attack_cd <= 0.0:
				_enter("windup")
				_play("attack")
				sprite.frame = 0
				Game.sfx("boss_orb", -12.0, 1.6)
			else:
				velocity.x = float(facing) * 120.0
				_play("move")
		else:
			velocity.x = float(facing) * 70.0
			_play("move")
			if global_position.x < patrol_a:
				_face(1)
			elif global_position.x > patrol_b:
				_face(-1)
	# never leave the patrol zone while chasing
	if global_position.x < patrol_a - 60.0 and velocity.x < 0.0:
		velocity.x = 0.0
	if global_position.x > patrol_b + 60.0 and velocity.x > 0.0:
		velocity.x = 0.0
	move_and_slide()


# ------------------------------------------------------------------ drone
func _ai_drone(delta: float, dx: float, dy: float) -> void:
	var aggro := absf(dx) < 640.0
	var target_x := global_position.x
	var target_y := _home_y + sin(_t * 1.7) * 14.0
	if aggro:
		_face(1 if dx > 0.0 else -1)
		var pl = _get_player()
		var want := 330.0
		if absf(dx) > want + 40.0:
			target_x = global_position.x + signf(dx) * 160.0
		elif absf(dx) < want - 80.0:
			target_x = global_position.x - signf(dx) * 140.0
		if pl != null:
			target_y = clampf(pl.global_position.y - 150.0, _home_y - 90.0, _home_y + 40.0) + sin(_t * 2.0) * 10.0
	else:
		target_x = global_position.x + sin(_t * 0.7) * 60.0
	var vx := clampf(target_x - global_position.x, -170.0, 170.0)
	var vy := clampf((target_y - global_position.y) * 3.0, -160.0, 160.0)
	velocity = velocity.lerp(Vector2(vx, vy), clampf(delta * 4.0, 0.0, 1.0))
	global_position += velocity * delta
	global_position.x = clampf(global_position.x, patrol_a - 300.0, patrol_b + 300.0)

	if state == "charge":
		velocity = velocity * 0.9
		if not _did_hit and _state_t > 0.38:
			_did_hit = true
			_fire_drone_shot()
		if _state_t > 0.55:
			_enter("patrol")
			_attack_cd = randf_range(1.8, 2.6)
	else:
		_play("move" if aggro else "idle")
		if aggro and _attack_cd <= 0.0 and absf(dy) < 420.0:
			_enter("charge")
			_did_hit = false
			_play("attack")
			sprite.frame = 0
			Game.sfx("boss_warn", -14.0, 1.9)


func _fire_drone_shot() -> void:
	var pl = _get_player()
	if pl == null:
		return
	var from := global_position + Vector2(float(facing) * 30.0, 22.0)
	var target = pl.global_position + Vector2(0, -55)
	var dirv = (target - from).normalized()
	var p = ProjectileScript.new()
	p.velocity = dirv * 360.0
	p.damage = 12
 	p.radius = 12.0
	p.color = Color(1.0, 0.3, 0.3)
	p.life = 3.5
	p.position = from
	get_parent().add_child(p)
	Game.sfx("boss_orb", -8.0, 1.5)


# ------------------------------------------------------------------ brute
func _ai_brute(delta: float, dx: float, dy: float) -> void:
	_apply_gravity(delta)
	var seen := absf(dx) < 520.0 and absf(dy) < 200.0
	if state == "slam":
		velocity.x = 0.0
		if not _did_hit and _state_t > 0.42:
			_did_hit = true
			_brute_impact()
		if _state_t > 0.72:
			_enter("patrol")
			_attack_cd = randf_range(2.0, 3.0)
	else:
		if seen:
			_face(1 if dx > 0.0 else -1)
			if absf(dx) < 220.0 and _attack_cd <= 0.0:
				_enter("slam")
				_did_hit = false
				_play("attack")
				sprite.frame = 0
				Game.sfx("boss_warn", -8.0, 0.8)
			elif absf(dx) > 120.0:
				velocity.x = float(facing) * 105.0
				_play("move")
			else:
				velocity.x = 0.0
				_play("idle")
		else:
			velocity.x = float(facing) * 55.0
			_play("move")
			if global_position.x < patrol_a:
				_face(1)
			elif global_position.x > patrol_b:
				_face(-1)
	if global_position.x < patrol_a - 80.0 and velocity.x < 0.0:
		velocity.x = 0.0
	if global_position.x > patrol_b + 80.0 and velocity.x > 0.0:
		velocity.x = 0.0
	move_and_slide()


func _brute_impact() -> void:
	Game.sfx("boss_slam", -4.0, 1.2)
	var impact := global_position + Vector2(float(facing) * 110.0, 0)
	Fx.burst(get_parent(), impact, Color(1.0, 0.6, 0.3), 16, 280.0, 0.55, 12.0, 320.0)
	var pl = _get_player()
	if pl != null and pl.has_method("shake"):
		pl.shake(6.0, 0.2)
	# shockwave rolling along the floor - jump it!
	var p = ProjectileScript.new()
	p.velocity = Vector2(float(facing) * 330.0, 0)
	p.damage = 16
	p.radius = 20.0
	p.color = Color(1.0, 0.6, 0.25)
	p.life = 1.3
	p.stretch = Vector2(1.5, 0.8)
	p.position = global_position + Vector2(float(facing) * 90.0, -22.0)
	get_parent().add_child(p)


# ------------------------------------------------------------------ shared
func _enter(s: String) -> void:
	state = s
	_state_t = 0.0


func take_damage(amount: int, from_pos: Vector2 = Vector2.ZERO) -> void:
	if _dead:
		return
	hp -= amount
	_flash = 0.09
	var dirx := signf(global_position.x - from_pos.x)
	if dirx == 0.0:
		dirx = 1.0
	var stagger := 0.28
	var kb := 260.0
	if kind == "brute":
		kb = 110.0
		stagger = 0.2 if state != "slam" else 0.0
	if stagger > 0.0:
		_hurt_t = stagger
		_enter("patrol")
		_play("hurt")
		sprite.frame = 0
		velocity.x = dirx * kb
		if kind == "drone":
			velocity.y = -60.0
	Fx.burst(get_parent(), global_position + Vector2(0, -40 if kind != "drone" else 0), Color(1.0, 0.9, 0.6), 10, 210.0, 0.35, 9.0, 300.0)
	if hp <= 0:
		_die()


func _die() -> void:
	_dead = true
	collision_layer = 0
	_hit_area.set_deferred("monitoring", false)
	_play("dead")
	sprite.frame = 0
	Game.sfx("enemy_die", 0.0, randf_range(0.9, 1.1))
	var pts := 200
	var gems := 2
	if kind == "brute":
		pts = 600
		gems = 5
	elif kind == "drone":
		pts = 300
		gems = 3
	Game.add_score(pts)
	Game.toast.emit("+%d" % pts)
	Fx.burst(get_parent(), global_position + Vector2(0, -40 if kind != "drone" else 0), Color(1.0, 0.6, 0.9), 18, 260.0, 0.7, 11.0, 260.0)
	var pl = _get_player()
	if pl != null and pl.has_method("shake"):
		pl.shake(4.0, 0.15)
	for i in range(gems):
		var g = PickupScript.new()
		g.kind = "crystal"
		g.position = global_position + Vector2(randf_range(-40, 40), -50 if kind != "drone" else -10)
		get_parent().call_deferred("add_child", g)
	await get_tree().create_timer(1.1).timeout
	if not is_inside_tree():
		return
	var tw := create_tween()
	tw.tween_property(sprite, "modulate:a", 0.0, 0.5)
	await tw.finished
	queue_free()
