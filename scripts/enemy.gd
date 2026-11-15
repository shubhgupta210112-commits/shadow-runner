extends CharacterBody2D
## Fantasy enemies of the Whispering Grove. One script, three behaviours:
##  MOSSLING  - patrols platforms, spots the player and charges.
##  WISP      - hovers, then swoops at the player when detected.
##  SPORECAP  - stationary mushroom that lobs arcing spores.
## Defeat by stomping from above or by Shadow Bolt.

const Fx := preload("res://scripts/fx.gd")

signal defeated(enemy: Node)

enum Kind { MOSSLING, WISP, SPORECAP }

const FRAMES := {
	Kind.MOSSLING: preload("res://assets/sprites/mossling_frames.tres"),
	Kind.WISP: preload("res://assets/sprites/wisp_frames.tres"),
	Kind.SPORECAP: preload("res://assets/sprites/sporecap_frames.tres"),
}
const GRAVITY := 900.0
const PROJECTILE_SCENE := "res://scenes/projectile.tscn"

@export var kind: Kind = Kind.MOSSLING
@export var patrol_range: float = 64.0

var hp: int = 1
var points: int = 100
var stomp_height: float = 10.0
var dir: int = -1

var _home: Vector2
var _dead: bool = false
var _t: float = 0.0
var _turn_cd: float = 0.0
var _flash: float = 0.0
var _wisp_state: int = 0  # 0 hover, 1 dive, 2 return
var _wisp_cd: float = 0.0
var _dive_dir: Vector2 = Vector2.ZERO
var _dive_time: float = 0.0
var _shoot_cd: float = 1.0
var _shoot_windup: float = -1.0
var _player: Node2D
var _projectile_scene: PackedScene
var _stun: float = 0.0
var _knock: Vector2 = Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var body_shape: CollisionShape2D = $Body
@onready var hitbox: Area2D = $Hitbox
@onready var hit_shape: CollisionShape2D = $Hitbox/Shape
@onready var floor_ray: RayCast2D = $FloorRay
@onready var wall_ray: RayCast2D = $WallRay


func _ready() -> void:
	add_to_group("enemies")
	_home = global_position
	_t = randf() * 6.0
	_projectile_scene = load(PROJECTILE_SCENE) as PackedScene
	sprite.sprite_frames = FRAMES[kind]
	var body := RectangleShape2D.new()
	var hb := RectangleShape2D.new()
	match kind:
		Kind.MOSSLING:
			hp = 2
			points = 100
			stomp_height = 9.0
			body.size = Vector2(20, 14)
			body_shape.position = Vector2(0, -7)
			hb.size = Vector2(22, 14)
			hit_shape.position = Vector2(0, -8)
			sprite.position = Vector2(0, -12)
			sprite.play("walk")
		Kind.WISP:
			hp = 2
			points = 150
			stomp_height = 20.0
			collision_mask = 0
			body.size = Vector2(14, 14)
			body_shape.position = Vector2(0, -18)
			hb.size = Vector2(18, 20)
			hit_shape.position = Vector2(0, -18)
			sprite.position = Vector2(0, -16)
			sprite.play("fly")
		Kind.SPORECAP:
			hp = 3
			points = 200
			stomp_height = 20.0
			body.size = Vector2(18, 26)
			body_shape.position = Vector2(0, -13)
			hb.size = Vector2(24, 24)
			hit_shape.position = Vector2(0, -14)
			sprite.position = Vector2(0, -16)
			sprite.play("idle")
	body_shape.shape = body
	hit_shape.shape = hb
	floor_ray.add_exception(self)
	wall_ray.add_exception(self)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	_turn_cd = maxf(0.0, _turn_cd - delta)
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			sprite.modulate = Color.WHITE
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	if _stun > 0.0:
		_stun -= delta
		_knockback_step(delta)
		return
	match kind:
		Kind.MOSSLING:
			_ai_mossling(delta)
		Kind.WISP:
			_ai_wisp(delta)
		Kind.SPORECAP:
			_ai_sporecap(delta)


# ------------------------------------------------------------------ AI
func _player_close(max_dx: float, max_dy: float) -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	if _player.get("state") == 2:  # dead
		return false
	var d := _player.global_position - global_position
	return absf(d.x) <= max_dx and absf(d.y + 12.0) <= max_dy


func _ai_mossling(delta: float) -> void:
	velocity.y = minf(velocity.y + GRAVITY * delta, 400.0)
	var chasing := _player_close(110.0, 34.0)
	var speed := 28.0
	if chasing:
		var want: int = 1 if _player.global_position.x > global_position.x else -1
		dir = want
		speed = 68.0
		if sprite.animation != "alert":
			sprite.play("alert")
	else:
		if sprite.animation != "walk":
			sprite.play("walk")
		if absf(global_position.x - _home.x) > patrol_range and signi(int(global_position.x - _home.x)) == dir:
			_turn()
	floor_ray.position = Vector2(dir * 12.0, -4.0)
	wall_ray.position = Vector2(0.0, -6.0)
	wall_ray.target_position = Vector2(dir * 13.0, 0.0)
	floor_ray.force_raycast_update()
	wall_ray.force_raycast_update()
	var blocked := wall_ray.is_colliding() or not floor_ray.is_colliding()
	if is_on_floor() and blocked:
		if chasing:
			speed = 0.0
		elif _turn_cd <= 0.0:
			_turn()
	velocity.x = dir * speed
	move_and_slide()
	sprite.flip_h = dir < 0


func _turn() -> void:
	dir = -dir
	_turn_cd = 0.4


func _ai_wisp(delta: float) -> void:
	_wisp_cd = maxf(0.0, _wisp_cd - delta)
	match _wisp_state:
		0:
			var target := _home + Vector2(sin(_t * 1.1) * patrol_range * 0.5, sin(_t * 2.3) * 7.0)
			velocity = (target - global_position) * 3.0
			if _wisp_cd <= 0.0 and _player_close(120.0, 90.0):
				_wisp_state = 1
				_dive_time = 0.75
				_dive_dir = (_player.global_position + Vector2(0, -12) - (global_position + Vector2(0, -16))).normalized()
				sprite.play("dive")
		1:
			_dive_time -= delta
			velocity = _dive_dir * 170.0
			if _dive_time <= 0.0:
				_wisp_state = 2
				sprite.play("fly")
		2:
			var to_home := _home - global_position
			velocity = to_home.normalized() * 90.0
			if to_home.length() < 6.0:
				_wisp_state = 0
				_wisp_cd = 1.6
	global_position += velocity * delta
	if _player != null and is_instance_valid(_player):
		sprite.flip_h = _player.global_position.x < global_position.x


func _ai_sporecap(delta: float) -> void:
	velocity.y = minf(velocity.y + GRAVITY * delta, 400.0)
	velocity.x = 0.0
	move_and_slide()
	_shoot_cd = maxf(0.0, _shoot_cd - delta)
	if _shoot_windup >= 0.0:
		_shoot_windup -= delta
		if _shoot_windup < 0.0:
			_fire_spore()
			_shoot_cd = 2.3
	elif _shoot_cd <= 0.0 and _player_close(170.0, 110.0):
		_shoot_windup = 0.3
		sprite.play("shoot")
	elif sprite.animation == "shoot" and not sprite.is_playing():
		sprite.play("idle")


func _fire_spore() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var start := global_position + Vector2(0, -26)
	var target := _player.global_position + Vector2(0, -12)
	var flight := 0.9
	var g := 240.0
	var vx := clampf((target.x - start.x) / flight, -150.0, 150.0)
	var vy := (target.y - start.y - 0.5 * g * flight * flight) / flight
	var p := _projectile_scene.instantiate()
	p.setup(&"spore", Vector2(vx, vy), 1, 1, g, 2.6)
	get_parent().add_child(p)
	p.global_position = start
	AudioManager.play_sfx(&"spore", -4.0, 1.0, 0.06)
	sprite.play("idle")


# ------------------------------------------------------------------ knockback
func _knockback_step(delta: float) -> void:
	## Enemy is stunned: it slides/flies back, then rebounds into its AI.
	if kind == Kind.WISP:
		_knock = _knock.move_toward(Vector2.ZERO, 500.0 * delta)
		global_position += _knock * delta
		return
	velocity.y = minf(velocity.y + GRAVITY * delta, 400.0)
	_knock.x = move_toward(_knock.x, 0.0, 420.0 * delta)
	velocity.x = _knock.x
	move_and_slide()


func _apply_knockback(from_x: float, strength: float) -> void:
	var away := signf(global_position.x - from_x)
	if away == 0.0:
		away = -float(dir)
	_stun = 0.35
	_wisp_state = 0 if kind == Kind.WISP else _wisp_state
	_shoot_windup = -1.0
	if kind == Kind.WISP:
		_knock = Vector2(away * strength, -strength * 0.35)
	else:
		_knock = Vector2(away * strength, 0.0)
		if kind == Kind.MOSSLING:
			velocity.y = -120.0
			dir = int(-away)  # recoils, then turns to face the attacker again
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2(1.25, 0.8), 0.06)
	tw.tween_property(sprite, "scale", Vector2(0.9, 1.15), 0.08)
	tw.tween_property(sprite, "scale", Vector2.ONE, 0.1)


# ------------------------------------------------------------------ combat
## Called by the player's hurtbox poll while overlapping.
func on_player_contact(player: Node) -> void:
	if _dead:
		return
	# Overlaps are detected a frame or two late, so be generous: any falling
	# contact whose feet are above the enemy's base counts as a stomp.
	var base_offset := 4.0 if kind != Kind.WISP else -4.0
	var feet_above: bool = player.global_position.y < global_position.y + base_offset
	if player.is_falling_fast() and feet_above:
		player.bounce()
		AudioManager.play_sfx(&"stomp")
		_hurt(2, true)
	else:
		player.take_damage(1, global_position.x)


## Called by projectiles (Shadow Bolt). Returns true when the hit was consumed.
func take_hit(amount: int, source: Node) -> bool:
	if _dead:
		return false
	var from_x := global_position.x - 1.0
	if source is Node2D:
		from_x = (source as Node2D).global_position.x
	_hurt(amount, false)
	if not _dead:
		_apply_knockback(from_x, 150.0)
	return true


func _hurt(amount: int, by_stomp: bool) -> void:
	hp -= amount
	if hp <= 0:
		_die(by_stomp)
		return
	_flash = 0.12
	sprite.modulate = Color(3, 3, 3)
	AudioManager.play_sfx(&"boss_hit", -10.0, 1.6)
	Fx.burst(get_parent(), global_position + Vector2(0, -14), Color(1, 0.9, 0.6), 6, 60.0, 0.3, 120.0)


func _die(by_stomp: bool) -> void:
	_dead = true
	hitbox.set_deferred("monitorable", false)
	body_shape.set_deferred("disabled", true)
	GameManager.register_enemy_defeated(points)
	AudioManager.play_sfx(&"enemy_die", -2.0, 1.0, 0.05)
	Fx.popup_text(get_parent(), global_position + Vector2(0, -26), "+%d" % points)
	Fx.burst(get_parent(), global_position + Vector2(0, -12), Color(0.8, 0.95, 0.7), 14, 100.0, 0.5, 260.0)
	defeated.emit(self)
	var fling := Vector2(-float(dir) * 50.0, -40.0)
	if _player != null and is_instance_valid(_player):
		fling.x = signf(global_position.x - _player.global_position.x) * 50.0
	var tw := create_tween().set_parallel(true)
	if by_stomp:
		tw.tween_property(sprite, "scale", Vector2(1.4, 0.15), 0.12)
	else:
		tw.tween_property(self, "global_position", global_position + fling, 0.3).set_ease(Tween.EASE_OUT)
		tw.tween_property(sprite, "rotation", signf(fling.x) * 2.5, 0.3)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.22).set_delay(0.08)
	tw.chain().tween_callback(queue_free)
