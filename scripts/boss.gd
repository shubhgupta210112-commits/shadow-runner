extends CharacterBody2D
## GLOOMHORN, the spectral stag guarding the Grove's heart-gate.
##
## Phases (by health): 1 = charge + orb volley, 2 = adds ground slam with
## shockwaves, 3 = enraged: faster, spear rain. After a slam into a wall or a
## successful stomp/bolt streak the boss is STUNNED and takes bonus damage.
## Every hit recoils the boss ("bounce back") before it rebounds into attack.

const Fx := preload("res://scripts/fx.gd")

signal health_changed(current: int, maximum: int)
signal phase_changed(phase: int)
signal defeated
signal roared

enum State { DORMANT, IDLE, WINDUP, CHARGE, SLAM, VOLLEY, SPEARS, STUN, RECOIL, DEAD }

const GRAVITY := 900.0
const PROJECTILE_SCENE := "res://scenes/projectile.tscn"

@export var max_health: int = 24
@export var arena_left: float = 0.0
@export var arena_right: float = 400.0

var health: int = 24
var phase: int = 1
var state: State = State.DORMANT
var facing: int = -1

var _t: float = 0.0
var _state_t: float = 0.0
var _player: Node2D
var _projectile_scene: PackedScene
var _flash: float = 0.0
var _recoil_v: float = 0.0
var _combo: int = 0
var _attack_cd: float = 1.2
var _last_attack: int = -1
var _volley_shots: int = 0
var _slam_done: bool = false
var _spears_left: int = 0
var _wall_hits: int = 0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var body_shape: CollisionShape2D = $Body
@onready var hitbox: Area2D = $Hitbox
@onready var hit_shape: CollisionShape2D = $Hitbox/Shape
@onready var weak_spot: Area2D = $WeakSpot


func _ready() -> void:
	add_to_group("boss")
	health = max_health
	_projectile_scene = load(PROJECTILE_SCENE) as PackedScene
	sprite.play("idle")
	hitbox.monitorable = false
	weak_spot.monitorable = false


func awaken() -> void:
	if state != State.DORMANT:
		return
	hitbox.monitorable = true
	weak_spot.monitorable = true
	_enter(State.IDLE)
	_attack_cd = 1.6
	AudioManager.play_sfx(&"boss_roar")
	roared.emit()
	health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	_t += delta
	_state_t += delta
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			sprite.modulate = Color.WHITE
	if state == State.DORMANT or state == State.DEAD:
		velocity.y = minf(velocity.y + GRAVITY * delta, 500.0)
		velocity.x = 0.0
		move_and_slide()
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	velocity.y = minf(velocity.y + GRAVITY * delta, 500.0)

	match state:
		State.IDLE:
			_do_idle(delta)
		State.WINDUP:
			_do_windup(delta)
		State.CHARGE:
			_do_charge(delta)
		State.SLAM:
			_do_slam(delta)
		State.VOLLEY:
			_do_volley(delta)
		State.SPEARS:
			_do_spears(delta)
		State.STUN:
			_do_stun(delta)
		State.RECOIL:
			_do_recoil(delta)
	move_and_slide()
	global_position.x = clampf(global_position.x, arena_left + 30.0, arena_right - 30.0)
	sprite.flip_h = facing < 0


# ------------------------------------------------------------------ state helpers
func _enter(s: State) -> void:
	state = s
	_state_t = 0.0
	match s:
		State.IDLE:
			sprite.play("idle")
		State.WINDUP:
			sprite.play("windup")
			AudioManager.play_sfx(&"boss_charge")
		State.CHARGE:
			sprite.play("run")
		State.SLAM:
			sprite.play("slam")
			_slam_done = false
		State.VOLLEY:
			sprite.play("windup")
			_volley_shots = 0
		State.SPEARS:
			sprite.play("windup")
			_spears_left = 6 + phase * 2
		State.STUN:
			sprite.play("stun")
		State.RECOIL:
			sprite.play("stun")


func _face_player() -> void:
	if _player != null and is_instance_valid(_player):
		facing = 1 if _player.global_position.x > global_position.x else -1


func _speed_mult() -> float:
	return 1.0 + 0.25 * float(phase - 1)


# ------------------------------------------------------------------ behaviours
func _do_idle(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	_face_player()
	_attack_cd -= delta
	if _attack_cd <= 0.0:
		_pick_attack()


func _pick_attack() -> void:
	var options: Array[int] = [0, 1]  # 0 charge, 1 volley
	if phase >= 2:
		options.append(2)  # slam
	if phase >= 3:
		options.append(3)  # spears
	options.erase(_last_attack)
	var choice: int = options[randi() % options.size()]
	_last_attack = choice
	_face_player()
	match choice:
		0:
			_enter(State.WINDUP)
		1:
			_enter(State.VOLLEY)
		2:
			_enter(State.SLAM)
		3:
			_enter(State.SPEARS)


func _do_windup(delta: float) -> void:
	velocity.x = 0.0
	if _state_t >= 0.7 / _speed_mult():
		_enter(State.CHARGE)


func _do_charge(delta: float) -> void:
	velocity.x = float(facing) * 190.0 * _speed_mult()
	if _state_t > 0.12 and int(_state_t * 8.0) != int((_state_t - delta) * 8.0):
		Fx.dust(get_parent(), global_position + Vector2(-facing * 20, 0), true)
	var hit_wall := is_on_wall() or \
		(facing < 0 and global_position.x <= arena_left + 31.0) or \
		(facing > 0 and global_position.x >= arena_right - 31.0)
	if hit_wall and _state_t > 0.25:
		_wall_hits += 1
		AudioManager.play_sfx(&"boss_slam")
		_shake_player(5.0, 0.4)
		Fx.burst(get_parent(), global_position + Vector2(facing * 34, -34), Color(0.7, 0.65, 0.9), 14, 120.0, 0.5, 300.0, 120.0, Vector2(-facing, -1))
		facing = -facing
		velocity.x = float(facing) * 90.0
		velocity.y = -140.0
		# Crashing into the wall stuns it (every time in phase 1-2, every other in 3)
		if phase < 3 or _wall_hits % 2 == 0:
			_enter(State.STUN)
		else:
			_enter(State.IDLE)
			_attack_cd = 0.5
	elif _state_t > 2.2:
		_enter(State.IDLE)
		_attack_cd = 0.8


func _do_slam(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
	if _state_t < 0.45 and is_on_floor():
		velocity.y = -330.0 if _state_t < 0.05 else velocity.y
	if _state_t < 0.1:
		_face_player()
	if not _slam_done and _state_t > 0.5 and is_on_floor():
		_slam_done = true
		AudioManager.play_sfx(&"boss_slam")
		_shake_player(6.0, 0.5)
		Fx.burst(get_parent(), global_position + Vector2(0, -2), Color(0.88, 0.29, 0.82), 18, 140.0, 0.6, 260.0, 180.0)
		for d in [-1, 1]:
			var w := _projectile_scene.instantiate()
			w.setup(&"wave", Vector2(d * 140.0 * _speed_mult(), 0.0), 1, 1, 0.0, 2.2)
			get_parent().add_child(w)
			w.global_position = global_position + Vector2(d * 24, -8)
	if _slam_done and _state_t > 1.2:
		_enter(State.IDLE)
		_attack_cd = 0.9 / _speed_mult()


func _do_volley(delta: float) -> void:
	velocity.x = 0.0
	_face_player()
	var interval := 0.45 / _speed_mult()
	var start := 0.6
	var shots := 3 + phase
	var due := start + float(_volley_shots) * interval
	if _volley_shots < shots and _state_t >= due:
		_volley_shots += 1
		_fire_orb()
	if _volley_shots >= shots and _state_t > start + float(shots) * interval + 0.3:
		_enter(State.IDLE)
		_attack_cd = 1.0 / _speed_mult()


func _fire_orb() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var origin := global_position + Vector2(facing * 42, -58)
	var target := _player.global_position + Vector2(0, -14)
	var v := (target - origin).normalized() * (120.0 + 15.0 * phase)
	v = v.rotated(randf_range(-0.12, 0.12))
	var o := _projectile_scene.instantiate()
	o.setup(&"orb", v, 1, 1, 0.0, 3.0)
	get_parent().add_child(o)
	o.global_position = origin
	AudioManager.play_sfx(&"spore", -2.0, 0.7, 0.05)


func _do_spears(delta: float) -> void:
	velocity.x = 0.0
	_face_player()
	var interval := 0.28
	var n_fired := (6 + phase * 2) - _spears_left
	if _spears_left > 0 and _state_t >= 0.6 + float(n_fired) * interval:
		_spears_left -= 1
		_drop_spear()
	if _spears_left <= 0 and _state_t > 0.6 + float(8 + phase * 2) * interval + 0.9:
		_enter(State.IDLE)
		_attack_cd = 1.2


func _drop_spear() -> void:
	var x := randf_range(arena_left + 24.0, arena_right - 24.0)
	if _player != null and is_instance_valid(_player) and randf() < 0.5:
		x = _player.global_position.x + randf_range(-14.0, 14.0)
	var sp := _projectile_scene.instantiate()
	sp.setup(&"spear", Vector2(0, 240), 1, 1, 0.0, 2.4, 0.55)
	get_parent().add_child(sp)
	sp.global_position = Vector2(x, global_position.y - 230.0)


func _do_stun(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
	if _state_t > 2.4:
		_enter(State.IDLE)
		_attack_cd = 0.6
		sprite.modulate = Color.WHITE


func _do_recoil(delta: float) -> void:
	## Knocked back by a hit; slides away, then rebounds toward the player.
	velocity.x = move_toward(velocity.x, 0.0, 520.0 * delta)
	if _state_t > 0.32:
		_face_player()
		_enter(State.IDLE)
		_attack_cd = 0.1 if _combo < 2 else 0.5
		if _combo >= 2:
			_combo = 0
		# Rebound: lunge back at the player right after recoiling.
		velocity.x = float(facing) * 150.0
		sprite.scale = Vector2(1.12, 0.9)
		create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.2)


# ------------------------------------------------------------------ combat
func on_player_contact(player: Node) -> void:
	if state == State.DEAD or state == State.DORMANT:
		return
	# Landing on the head/back while falling is a stomp.
	var above: bool = player.global_position.y < global_position.y - 36.0
	if player.is_falling_fast() and above:
		player.bounce(-300.0)
		AudioManager.play_sfx(&"stomp")
		_take_damage(3 if state == State.STUN else 2, player.global_position.x)
	elif state != State.STUN and state != State.RECOIL:
		player.take_damage(1, global_position.x)


func take_hit(amount: int, source: Node) -> bool:
	if state == State.DEAD or state == State.DORMANT:
		return false
	var from_x := global_position.x
	if source is Node2D:
		from_x = (source as Node2D).global_position.x
	_take_damage(amount * (2 if state == State.STUN else 1), from_x)
	return true


func _take_damage(amount: int, from_x: float) -> void:
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	AudioManager.play_sfx(&"boss_hit")
	Fx.burst(get_parent(), global_position + Vector2(0, -44), Color(1.0, 0.8, 0.95), 10, 90.0, 0.4, 150.0)
	_flash = 0.1
	sprite.modulate = Color(3, 3, 3)
	if health <= 0:
		_die()
		return
	var new_phase := 1 + int(float(max_health - health) / float(max_health) * 3.0)
	new_phase = clampi(new_phase, 1, 3)
	if new_phase != phase:
		phase = new_phase
		phase_changed.emit(phase)
		AudioManager.play_sfx(&"boss_roar", 0.0, 1.0 + 0.1 * float(phase))
		_shake_player(4.0, 0.5)
		_enter(State.STUN)
		_state_t = 1.4  # short stun so the player can punish the transition
		return
	if state == State.STUN:
		_state_t = maxf(0.0, _state_t - 0.2)  # hits extend the stun a bit
		return
	# bounce back: recoil away from the attacker
	_combo += 1
	var away := signf(global_position.x - from_x)
	if away == 0.0:
		away = -float(facing)
	velocity.x = away * 150.0
	_enter(State.RECOIL)
	sprite.scale = Vector2(0.92, 1.1)
	create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.2)


func _die() -> void:
	state = State.DEAD
	hitbox.set_deferred("monitorable", false)
	weak_spot.set_deferred("monitorable", false)
	sprite.play("stun")
	AudioManager.play_sfx(&"boss_defeat")
	_shake_player(8.0, 1.6)
	GameManager.register_enemy_defeated(2000)
	Fx.popup_text(get_parent(), global_position + Vector2(0, -90), "+2000", Color(1, 0.9, 0.5))
	var tw := create_tween()
	for i in 10:
		tw.tween_callback(func() -> void:
			Fx.burst(get_parent(), global_position + Vector2(randf_range(-36, 36), randf_range(-70, -10)),
					Color(0.95, 0.5, 0.95), 12, 120.0, 0.7, 120.0))
		tw.tween_interval(0.16)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void:
		defeated.emit()
		queue_free())


func _shake_player(amount: float, time: float) -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p != null and p.has_method("shake"):
		p.shake(amount, time)
