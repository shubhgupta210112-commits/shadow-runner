extends CharacterBody2D
## The Shadow Runner: tight platforming controls (coyote time, jump buffering,
## variable jump height), health, stomp + Shadow Bolt combat and interaction.

const Fx := preload("res://scripts/fx.gd")

signal health_changed(current: int, maximum: int)
signal hurt(amount: int)
signal died
signal fell_into_pit
signal prompt_changed(text: String)

const MAX_SPEED := 132.0
const GROUND_ACCEL := 1100.0
const GROUND_FRICTION := 1300.0
const AIR_ACCEL := 760.0
const AIR_FRICTION := 320.0
const JUMP_VELOCITY := -335.0
const GRAVITY_UP := 900.0
const GRAVITY_DOWN := 1350.0
const MAX_FALL_SPEED := 400.0
const JUMP_CUT := 0.45
const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.12
const STOMP_BOUNCE := -250.0
const INVULN_TIME := 1.4
const HURT_TIME := 0.32
const SHOOT_COOLDOWN := 0.36
const DROP_THROUGH_TIME := 0.2
const PROJECTILE_SCENE := "res://scenes/projectile.tscn"

enum State { NORMAL, HURT, DEAD, LOCKED }

@export var max_health: int = 5
@export var death_y: float = 560.0

var health: int = 5
var state: State = State.NORMAL
var facing: int = 1
var projectile_parent: Node
var invulnerable_override: bool = false

var _coyote: float = 0.0
var _jump_buffer: float = 0.0
var _was_on_floor: bool = false
var _invuln: float = 0.0
var _hurt_timer: float = 0.0
var _shoot_cd: float = 0.0
var _cast_timer: float = 0.0
var _land_timer: float = 0.0
var _drop_timer: float = 0.0
var _step_timer: float = 0.0
var _interactable: Node = null
var _pit_reported: bool = false
var _shake_time: float = 0.0
var _shake_total: float = 0.1
var _shake_amount: float = 0.0
var _look_ahead: float = 0.0
var _projectile_scene: PackedScene

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hurtbox: Area2D = $Hurtbox
@onready var interact_sensor: Area2D = $InteractSensor
@onready var glow: PointLight2D = $Glow
@onready var camera: Camera2D = $Camera
@onready var bolt_spawn: Marker2D = $BoltSpawn


func _ready() -> void:
	add_to_group("player")
	health = max_health
	floor_snap_length = 6.0
	_projectile_scene = load(PROJECTILE_SCENE) as PackedScene
	if projectile_parent == null:
		projectile_parent = get_parent()
	health_changed.emit(health, max_health)
	sprite.play("idle")


func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	if state == State.DEAD:
		velocity.y = minf(velocity.y + GRAVITY_DOWN * delta, MAX_FALL_SPEED)
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		move_and_slide()
		_update_animation()
		return

	var can_act := state == State.NORMAL
	var dir := 0.0
	if can_act:
		dir = Input.get_axis("move_left", "move_right")
	var on_floor := is_on_floor()

	# ---- horizontal movement
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1
		var accel := GROUND_ACCEL if on_floor else AIR_ACCEL
		if signf(velocity.x) != 0.0 and signf(velocity.x) != signf(dir):
			accel *= 1.6
		velocity.x = move_toward(velocity.x, dir * MAX_SPEED, accel * delta)
	else:
		var fr := GROUND_FRICTION if on_floor else AIR_FRICTION
		if state == State.HURT:
			fr *= 0.35
		velocity.x = move_toward(velocity.x, 0.0, fr * delta)

	# ---- gravity
	var g := GRAVITY_UP if velocity.y < 0.0 else GRAVITY_DOWN
	velocity.y = minf(velocity.y + g * delta, MAX_FALL_SPEED)

	# ---- jumping (coyote time + buffer + variable height)
	if on_floor:
		_coyote = COYOTE_TIME
	if can_act and Input.is_action_just_pressed("jump"):
		_jump_buffer = JUMP_BUFFER
	if can_act and _jump_buffer > 0.0 and _coyote > 0.0:
		if Input.is_action_pressed("move_down") and _standing_on_one_way():
			_start_drop_through()
		else:
			velocity.y = JUMP_VELOCITY
			AudioManager.play_sfx(&"jump", -3.0, 1.0, 0.04)
			Fx.dust(get_parent(), global_position)
		_jump_buffer = 0.0
		_coyote = 0.0
	if can_act and Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

	# ---- shooting
	if can_act and Input.is_action_just_pressed("shoot") and _shoot_cd <= 0.0:
		_shoot()

	# ---- interaction
	_update_interactable()
	if can_act and Input.is_action_just_pressed("interact") and _interactable != null:
		_interactable.interact(self)

	var pre_vy := velocity.y
	move_and_slide()

	# ---- landing
	if is_on_floor() and not _was_on_floor and pre_vy > 140.0:
		_land_timer = 0.12
		AudioManager.play_sfx(&"land", -6.0, 1.0, 0.05)
		Fx.dust(get_parent(), global_position, true)
	_was_on_floor = is_on_floor()

	# ---- footsteps dust
	if is_on_floor() and absf(velocity.x) > 90.0:
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_timer = 0.2
			Fx.dust(get_parent(), global_position + Vector2(-facing * 4, 0))
	else:
		_step_timer = 0.0

	# ---- contacts and pits
	if state != State.DEAD:
		_check_contacts()
	if global_position.y > death_y and not _pit_reported and state != State.DEAD:
		_pit_reported = true
		fell_into_pit.emit()

	_update_animation()


func _process(delta: float) -> void:
	# camera look-ahead and shake
	var target_look := float(facing) * 26.0 if absf(velocity.x) > 20.0 else 0.0
	_look_ahead = lerpf(_look_ahead, target_look, clampf(delta * 2.5, 0.0, 1.0))
	var off := Vector2(_look_ahead, -26.0)
	if _shake_time > 0.0:
		var k := _shake_time / _shake_total
		off += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_amount * k
	camera.offset = off
	# glow breathing
	glow.energy = 0.75 + sin(Time.get_ticks_msec() * 0.004) * 0.08


func _tick_timers(delta: float) -> void:
	_coyote = maxf(0.0, _coyote - delta)
	_jump_buffer = maxf(0.0, _jump_buffer - delta)
	_shoot_cd = maxf(0.0, _shoot_cd - delta)
	_cast_timer = maxf(0.0, _cast_timer - delta)
	_land_timer = maxf(0.0, _land_timer - delta)
	_shake_time = maxf(0.0, _shake_time - delta)
	if _invuln > 0.0:
		_invuln = maxf(0.0, _invuln - delta)
	if _hurt_timer > 0.0:
		_hurt_timer -= delta
		if _hurt_timer <= 0.0 and state == State.HURT:
			state = State.NORMAL
	if _drop_timer > 0.0:
		_drop_timer -= delta
		if _drop_timer <= 0.0:
			collision_mask = 3


# ------------------------------------------------------------------ actions
func _shoot() -> void:
	_shoot_cd = SHOOT_COOLDOWN
	_cast_timer = 0.22
	var b := _projectile_scene.instantiate()
	b.setup(&"bolt", Vector2(facing * 280.0, 0.0), 1, 0, 0.0, 0.9)
	projectile_parent.add_child(b)
	b.global_position = global_position + Vector2(facing * 12.0, -14.0)
	AudioManager.play_sfx(&"shoot", -4.0, 1.0, 0.05)


func _standing_on_one_way() -> bool:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_normal().y < -0.5:
			var col := c.get_collider()
			if col is CollisionObject2D:
				var layer := (col as CollisionObject2D).collision_layer
				if (layer & 2) != 0 and (layer & 1) == 0:
					return true
	return false


func _start_drop_through() -> void:
	collision_mask = 1
	_drop_timer = DROP_THROUGH_TIME
	position.y += 2.0
	velocity.y = 60.0


func _check_contacts() -> void:
	for area in hurtbox.get_overlapping_areas():
		var target: Node = area
		if not target.has_method("on_player_contact"):
			target = area.get_parent()
		if target != null and target.has_method("on_player_contact"):
			target.on_player_contact(self)
		if state == State.DEAD:
			return


func _update_interactable() -> void:
	var best: Node = null
	var best_d := INF
	for area in interact_sensor.get_overlapping_areas():
		if area.has_method("interact") and area.has_method("can_interact") and area.can_interact():
			var d := area.global_position.distance_squared_to(global_position)
			if d < best_d:
				best_d = d
				best = area
	if best != _interactable:
		_interactable = best
		prompt_changed.emit("" if best == null else str(best.get("prompt_text")))


# ------------------------------------------------------------------ health
func take_damage(amount: int, from_x: float) -> bool:
	if state == State.DEAD or _invuln > 0.0 or invulnerable_override:
		return false
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	hurt.emit(amount)
	AudioManager.play_sfx(&"hurt")
	shake(3.0, 0.3)
	Fx.burst(get_parent(), global_position + Vector2(0, -14), Color(1.0, 0.45, 0.35), 10, 90.0, 0.45, 300.0)
	if health <= 0:
		_die()
		return true
	state = State.HURT
	_hurt_timer = HURT_TIME
	_invuln = INVULN_TIME
	var kb := signf(global_position.x - from_x)
	if kb == 0.0:
		kb = -float(facing)
	velocity = Vector2(kb * 150.0, -210.0)
	return true


func heal(amount: int) -> void:
	health = mini(max_health, health + amount)
	health_changed.emit(health, max_health)
	Fx.sparkle(get_parent(), global_position + Vector2(0, -14), Color(1.0, 0.5, 0.45))


func bounce(strength: float = STOMP_BOUNCE) -> void:
	velocity.y = -330.0 if Input.is_action_pressed("jump") else strength
	_coyote = 0.0
	_invuln = maxf(_invuln, 0.15)


func is_falling_fast() -> bool:
	return velocity.y > 30.0


func _die() -> void:
	state = State.DEAD
	velocity = Vector2(0, -230)
	collision_mask = 0
	collision_layer = 0
	sprite.modulate = Color.WHITE
	await get_tree().create_timer(0.9).timeout
	if is_inside_tree():
		died.emit()


func fall_penalty(respawn_pos: Vector2) -> void:
	## Falling in a pit costs one heart and returns the player to the checkpoint.
	health = maxi(0, health - 1)
	health_changed.emit(health, max_health)
	AudioManager.play_sfx(&"hurt")
	if health <= 0:
		_die()
		return
	teleport(respawn_pos)
	_invuln = 2.0


func teleport(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	state = State.NORMAL
	_pit_reported = false
	camera.reset_smoothing()


func respawn(pos: Vector2) -> void:
	health = max_health
	collision_layer = 4
	collision_mask = 3
	teleport(pos)
	_invuln = 2.0
	health_changed.emit(health, max_health)
	AudioManager.play_sfx(&"respawn")
	Fx.sparkle(get_parent(), pos + Vector2(0, -14), Color(0.5, 0.97, 1.0))


func lock_controls(locked: bool) -> void:
	if state == State.DEAD:
		return
	state = State.LOCKED if locked else State.NORMAL


func shake(amount: float, duration: float = 0.25) -> void:
	if not GameManager.screen_shake:
		return
	_shake_amount = maxf(_shake_amount if _shake_time > 0.0 else 0.0, amount)
	_shake_time = duration
	_shake_total = duration


func set_camera_limits(rect: Rect2i) -> void:
	camera.limit_left = rect.position.x
	camera.limit_top = rect.position.y
	camera.limit_right = rect.end.x
	camera.limit_bottom = rect.end.y


# ------------------------------------------------------------------ visuals
func _update_animation() -> void:
	var anim := "idle"
	if state == State.DEAD or state == State.HURT:
		anim = "hit"
	elif _cast_timer > 0.0:
		anim = "cast"
	elif not is_on_floor():
		anim = "jump" if velocity.y < 0.0 else "fall"
	elif _land_timer > 0.0:
		anim = "land"
	elif absf(velocity.x) > 12.0:
		anim = "run"
	if sprite.animation != anim:
		sprite.play(anim)
	if anim == "run":
		sprite.speed_scale = clampf(absf(velocity.x) / MAX_SPEED, 0.6, 1.2)
	else:
		sprite.speed_scale = 1.0
	sprite.flip_h = facing < 0
	if state != State.DEAD:
		if _invuln > 0.0 and state != State.HURT:
			sprite.modulate.a = 0.35 if int(_invuln * 16.0) % 2 == 0 else 1.0
		else:
			sprite.modulate.a = 1.0
