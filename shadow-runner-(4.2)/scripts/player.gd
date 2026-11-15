extends CharacterBody2D
## KAI, the Shadow Runner. Responsive platforming + sword combat.

signal health_changed(current: int, maximum: int)
signal died

const SpriteUtil = preload("res://scripts/sprite_util.gd")
const Fx = preload("res://scripts/fx.gd")

const MAX_HEALTH := 100
const RUN_SPEED := 340.0
const ACCEL := 2800.0
const AIR_ACCEL := 2000.0
const FRICTION := 3200.0
const GRAVITY := 2300.0
const MAX_FALL := 1100.0
const JUMP_VELOCITY := -840.0
const COYOTE_TIME := 0.12
const JUMP_BUFFER := 0.13
const SPRITE_SCALE := 0.85
const ATTACK_TIME := 0.32
const ATTACK_COOLDOWN := 0.08
const FRAME := 192
const ANIMS := [
    ["idle", 8, 10.0, true],
    ["run", 10, 17.0, true],
    ["jump", 6, 12.0, false],
    ["fall", 4, 10.0, true],
    ["land", 4, 18.0, false],
    ["attack", 6, 20.0, false],
    ["damage", 4, 14.0, false],
    ["victory", 6, 8.0, true],
]

var health: int = MAX_HEALTH
var facing: int = 1
var dead: bool = false
var frozen: bool = false
var victory: bool = false
var cinematic_offset: Vector2 = Vector2.ZERO
var camera: Camera2D
var sprite: AnimatedSprite2D

var _coyote: float = 0.0
var _jump_buffer: float = 0.0
var _attack_t: float = 0.0
var _attack_cd: float = 0.0
var _hurt_t: float = 0.0
var _land_t: float = 0.0
var _invuln: float = 0.0
var _hits: Array = []
var _attack_area: Area2D
var _was_on_floor: bool = false
var _last_vy: float = 0.0
var _safe_pos: Vector2 = Vector2.ZERO
var _safe_timer: float = 0.0
var _shake_str: float = 0.0
var _shake_time: float = 0.0
var _shake_total: float = 0.1
var _look_x: float = 0.0
var _run_dust: float = 0.0


func _ready() -> void:
    add_to_group("player")
    collision_layer = 2
    collision_mask = 1
    floor_snap_length = 12.0
    floor_max_angle = deg_to_rad(50.0)

    var cs := CollisionShape2D.new()
    var sh := RectangleShape2D.new()
    sh.size = Vector2(38, 108)
    cs.shape = sh
    cs.position = Vector2(0, -54)
    add_child(cs)

    sprite = AnimatedSprite2D.new()
    sprite.sprite_frames = SpriteUtil.make_frames("res://assets/characters/hero_sheet.png", FRAME, FRAME, ANIMS)
    sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
    sprite.position = Vector2(0, -82.0 * SPRITE_SCALE)
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    sprite.play("idle")
    add_child(sprite)

    _attack_area = Area2D.new()
    _attack_area.collision_layer = 0
    _attack_area.collision_mask = 8 | 4
    _attack_area.monitoring = true
    var acs := CollisionShape2D.new()
    var ash := RectangleShape2D.new()
    ash.size = Vector2(150, 120)
    acs.shape = ash
    _attack_area.position = Vector2(80, -62)
    _attack_area.add_child(acs)
    add_child(_attack_area)

    var light := PointLight2D.new()
    light.texture = load("res://assets/effects/light.png")
    light.color = Color(0.45, 0.9, 1.0)
    light.energy = 0.55
    light.texture_scale = 2.2
    light.position = Vector2(0, -70)
    add_child(light)

    camera = Camera2D.new()
    camera.position = Vector2(0, -150)
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 7.0
    camera.limit_left = 0
    camera.limit_right = 7680
    camera.limit_top = -400
    camera.limit_bottom = 800
    add_child(camera)
    camera.make_current()

    _safe_pos = global_position
    z_index = 5
    health_changed.emit(health, MAX_HEALTH)


func _process(delta: float) -> void:
    var target_look := float(facing) * 70.0
    if frozen or dead:
        target_look = 0.0
    _look_x = lerpf(_look_x, target_look, 1.0 - exp(-4.0 * delta))
    var off := Vector2(_look_x, 0.0) + cinematic_offset
    if _shake_time > 0.0:
        _shake_time -= delta
        var k := clampf(_shake_time / _shake_total, 0.0, 1.0)
        off += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_str * k
    camera.offset = off
    # invulnerability blink
    if _invuln > 0.0 and not dead:
        sprite.modulate.a = 0.45 + 0.55 * absf(sin(_invuln * 26.0))
    else:
        sprite.modulate.a = 1.0


func shake(strength: float, duration: float) -> void:
    if not Game.screen_shake:
        return
    _shake_str = maxf(_shake_str if _shake_time > 0.0 else 0.0, strength)
    _shake_time = maxf(_shake_time, duration)
    _shake_total = maxf(duration, 0.05)


func _physics_process(delta: float) -> void:
    _invuln = maxf(_invuln - delta, 0.0)
    _hurt_t = maxf(_hurt_t - delta, 0.0)
    _land_t = maxf(_land_t - delta, 0.0)
    _attack_cd = maxf(_attack_cd - delta, 0.0)

    if global_position.y > 900.0 and not dead:
        _fall_reset()

    if dead or frozen:
        velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
        velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
        move_and_slide()
        _update_anim()
        return

    var on_floor := is_on_floor()
    if on_floor:
        _coyote = COYOTE_TIME
    else:
        _coyote -= delta
    if Input.is_action_just_pressed("jump"):
        _jump_buffer = JUMP_BUFFER
    else:
        _jump_buffer -= delta

    var dir := Input.get_axis("move_left", "move_right")
    var speed_mul := 0.72 if _attack_t > 0.0 and on_floor else 1.0
    var target := dir * RUN_SPEED * speed_mul
    if absf(dir) > 0.1:
        var acc := ACCEL if on_floor else AIR_ACCEL
        velocity.x = move_toward(velocity.x, target, acc * delta)
        if _attack_t <= 0.0 or not on_floor:
            facing = 1 if dir > 0.0 else -1
    else:
        velocity.x = move_toward(velocity.x, 0.0, (FRICTION if on_floor else AIR_ACCEL * 0.5) * delta)

    # gravity + jump
    velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
    if _jump_buffer > 0.0 and _coyote > 0.0:
        velocity.y = JUMP_VELOCITY
        _jump_buffer = 0.0
        _coyote = 0.0
        sprite.play("jump")
        Game.sfx("jump", -2.0, randf_range(0.97, 1.05))
        Fx.burst(get_parent(), global_position, Color(0.7, 0.85, 1.0, 0.7), 6, 90.0, 0.35, 8.0, 80.0, 90.0, Vector2.UP)
    if Input.is_action_just_released("jump") and velocity.y < -250.0:
        velocity.y *= 0.5

    # attack
    if Input.is_action_just_pressed("action") and _attack_cd <= 0.0 and _attack_t <= 0.0:
        _start_attack()
    if _attack_t > 0.0:
        _attack_t -= delta
        var elapsed := ATTACK_TIME - _attack_t
        if elapsed > 0.07 and elapsed < 0.24:
            _do_attack_hits()
        if _attack_t <= 0.0:
            _attack_cd = ATTACK_COOLDOWN

    _last_vy = velocity.y
    move_and_slide()

    # landing
    var now_floor := is_on_floor()
    if now_floor and not _was_on_floor:
        if _last_vy > 380.0:
            _land_t = 0.2
            Game.sfx("land", -4.0)
            Fx.burst(get_parent(), global_position, Color(0.75, 0.85, 1.0, 0.7), 8, 130.0, 0.4, 9.0, 120.0, 100.0, Vector2.UP)
            if _last_vy > 800.0:
                shake(3.0, 0.12)
    _was_on_floor = now_floor

    # run dust
    if now_floor and absf(velocity.x) > 200.0:
        _run_dust -= delta
        if _run_dust <= 0.0:
            _run_dust = 0.16
            Fx.burst(get_parent(), global_position + Vector2(-facing * 18, 0), Color(0.65, 0.75, 0.95, 0.5), 2, 50.0, 0.3, 7.0, 20.0, 60.0, Vector2(-facing, -0.3))

    # remember safe spots (solid ground on both sides so a pit respawn is never at an edge)
    _safe_timer -= delta
    if now_floor and _safe_timer <= 0.0 and get_platform_velocity() == Vector2.ZERO:
        _safe_timer = 0.25
        if _has_ground(-55.0) and _has_ground(55.0):
            _safe_pos = global_position

    _update_anim()


func _has_ground(x_off: float) -> bool:
    var q := PhysicsRayQueryParameters2D.create(global_position + Vector2(x_off, -12), global_position + Vector2(x_off, 30), 1)
    var r: Dictionary = get_world_2d().direct_space_state.intersect_ray(q)
    return not r.is_empty()


func _start_attack() -> void:
    _attack_t = ATTACK_TIME
    _hits.clear()
    sprite.play("attack")
    sprite.frame = 0
    Game.sfx("sword", -2.0, randf_range(0.95, 1.1))
    _attack_area.position.x = 80.0 * float(facing)
    # a tiny forward lunge makes the swing feel weighty
    if is_on_floor():
        velocity.x += float(facing) * 90.0


func _do_attack_hits() -> void:
    _attack_area.position.x = 80.0 * float(facing)
    var bodies: Array = _attack_area.get_overlapping_bodies()
    for b in bodies:
        if _hits.has(b) or not is_instance_valid(b):
            continue
        if b.has_method("take_damage"):
            _hits.append(b)
            b.take_damage(1, global_position)
            Game.sfx("hit", -2.0, randf_range(0.9, 1.1))
            shake(3.5, 0.12)
            Game.hitstop(0.045, 0.1)
    var areas: Array = _attack_area.get_overlapping_areas()
    for a in areas:
        if _hits.has(a) or not is_instance_valid(a):
            continue
        if a.is_in_group("enemy_projectile") and a.has_method("take_damage"):
            _hits.append(a)
            a.take_damage(1, global_position)
            Game.sfx("hit", -6.0, 1.3)


func take_damage(amount: int, from_pos: Vector2 = Vector2.ZERO) -> void:
    if dead or victory or _invuln > 0.0 or frozen:
        return
    health = maxi(health - amount, 0)
    health_changed.emit(health, MAX_HEALTH)
    _invuln = 1.1
    _hurt_t = 0.29
    _attack_t = 0.0
    sprite.play("damage")
    sprite.frame = 0
    var dirx := signf(global_position.x - from_pos.x)
    if dirx == 0.0:
        dirx = -float(facing)
    velocity = Vector2(dirx * 360.0, -330.0)
    Game.sfx("hurt")
    shake(7.0, 0.25)
    Game.hitstop(0.07, 0.08)
    Fx.burst(get_parent(), global_position + Vector2(0, -60), Color(1.0, 0.45, 0.4), 12, 220.0, 0.45, 9.0, 300.0)
    if health <= 0:
        _die()


func heal(amount: int) -> void:
    health = mini(health + amount, MAX_HEALTH)
    health_changed.emit(health, MAX_HEALTH)


func _die() -> void:
    dead = true
    _hurt_t = 10.0
    velocity.x = 0.0
    sprite.play("damage")
    await get_tree().create_timer(0.9).timeout
    died.emit()


func _fall_reset() -> void:
    health = maxi(health - 20, 0)
    health_changed.emit(health, MAX_HEALTH)
    Game.sfx("hurt")
    if health <= 0:
        _die()
        return
    global_position = _safe_pos
    velocity = Vector2.ZERO
    _invuln = 1.6
    camera.reset_smoothing()
    Game.toast.emit("-20 HP  (FELL)")


func celebrate() -> void:
    victory = true
    frozen = true
    velocity.x = 0.0
    sprite.play("victory")


func _update_anim() -> void:
    var a := "idle"
    if dead:
        a = "damage"
    elif victory:
        a = "victory"
    elif _hurt_t > 0.0:
        a = "damage"
    elif _attack_t > 0.0:
        a = "attack"
    elif not is_on_floor():
        a = "jump" if velocity.y < 0.0 else "fall"
    elif _land_t > 0.0:
        a = "land"
    elif absf(velocity.x) > 40.0:
        a = "run"
    if sprite.animation != a:
        sprite.play(a)
    elif not sprite.is_playing() and (a == "idle" or a == "run" or a == "fall" or a == "victory"):
        sprite.play(a)
    sprite.flip_h = facing < 0
    sprite.position.x = float(facing) * 9.5 * SPRITE_SCALE
