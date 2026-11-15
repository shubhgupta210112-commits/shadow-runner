extends CharacterBody2D
## VOID GUARDIAN - three telegraphed attack patterns, two phases, cinematic intro and defeat.

signal health_changed(current: int, maximum: int)
signal intro_started
signal intro_finished
signal defeated

const SpriteUtil = preload("res://scripts/sprite_util.gd")
const Fx = preload("res://scripts/fx.gd")
const ProjectileScript = preload("res://scripts/projectile.gd")
const PillarScript = preload("res://scripts/void_pillar.gd")

const MAX_HP := 30
const FRAME := 320
const SCALE := 0.9
const ANIMS := [
    ["idle", 6, 8.0, true],
    ["slam", 8, 10.0, false],
    ["cast", 8, 10.0, false],
    ["hurt", 3, 10.0, false],
    ["dead", 8, 8.0, false],
]

var arena_l: float = 6400.0
var arena_r: float = 7680.0
var ground_y: float = 560.0
var hp: int = MAX_HP
var sprite: AnimatedSprite2D
var vulnerable: bool = false
var active: bool = false

var _dead: bool = false
var _phase: int = 1
var _player: Node2D
var _tween: Tween
var _flash: float = 0.0
var _tint: Color = Color(1, 1, 1, 1)
var _last_attack: String = ""
var _hit_area: Area2D
var _light: PointLight2D
var _t: float = 0.0

# centre of the sprite when hovering / when sitting low
var _hover_y: float
var _low_y: float


func _ready() -> void:
    add_to_group("boss")
    collision_layer = 8
    collision_mask = 0
    _low_y = ground_y - 133.0 - 6.0
    _hover_y = ground_y - 133.0 - 85.0

    sprite = AnimatedSprite2D.new()
    sprite.sprite_frames = SpriteUtil.make_frames("res://assets/enemies/guardian_sheet.png", FRAME, FRAME, ANIMS)
    sprite.scale = Vector2(SCALE, SCALE)
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    sprite.play("idle")
    add_child(sprite)

    var cs := CollisionShape2D.new()
    var sh := RectangleShape2D.new()
    sh.size = Vector2(190, 250)
    cs.shape = sh
    add_child(cs)

    _hit_area = Area2D.new()
    _hit_area.collision_layer = 0
    _hit_area.collision_mask = 2
    var hcs := CollisionShape2D.new()
    var hsh := RectangleShape2D.new()
    hsh.size = Vector2(170, 230)
    hcs.shape = hsh
    _hit_area.add_child(hcs)
    add_child(_hit_area)

    _light = PointLight2D.new()
    _light.texture = load("res://assets/effects/light.png")
    _light.color = Color(0.9, 0.4, 1.0)
    _light.energy = 1.0
    _light.texture_scale = 3.2
    add_child(_light)

    z_index = 4
    position = Vector2((arena_l + arena_r) * 0.5 + 220.0, ground_y - 800.0)
    visible = false


func _get_player() -> Node2D:
    if _player == null or not is_instance_valid(_player):
        _player = get_tree().get_first_node_in_group("player") as Node2D
    return _player


func _process(delta: float) -> void:
    _t += delta
    if _dead:
        _light.energy = maxf(_light.energy - delta * 0.6, 0.0)
        return
    if _flash > 0.0:
        _flash -= delta
    var col := _tint
    if _flash > 0.0:
        col = Color(2.4, 2.4, 2.4, 1.0)
    elif vulnerable and not _dead:
        var k := 0.5 + 0.5 * sin(_t * 9.0)
        col = Color(1.0 + 0.0 * k, 1.0 + 0.25 * k, 1.0 + 0.5 * k, 1.0)
    sprite.modulate = col
    _light.energy = 0.8 + 0.4 * sin(_t * 3.0) + (0.5 if _phase == 2 else 0.0)


func _physics_process(_delta: float) -> void:
    if not active or _dead:
        return
    var touching: Array = _hit_area.get_overlapping_bodies()
    for b in touching:
        if b.is_in_group("player"):
            b.take_damage(14, global_position)


func _play(anim: String) -> void:
    sprite.play(anim)
    sprite.frame = 0


func _wait(t: float) -> void:
    await get_tree().create_timer(t).timeout


func _move_to(x: float, y: float, t: float, trans: Tween.TransitionType = Tween.TRANS_SINE) -> void:
    if _tween and _tween.is_valid():
        _tween.kill()
    var cx := clampf(x, arena_l + 230.0, arena_r - 230.0)
    _tween = create_tween()
    _tween.set_parallel(true)
    _tween.tween_property(self, "position:x", cx, t).set_trans(trans).set_ease(Tween.EASE_IN_OUT)
    _tween.tween_property(self, "position:y", y, t).set_trans(trans).set_ease(Tween.EASE_IN_OUT)
    await _tween.finished


# ------------------------------------------------------------------ intro
func start_fight() -> void:
    visible = true
    active = false
    intro_started.emit()
    Game.sfx("boss_intro", 2.0)
    position.y = ground_y - 900.0
    var pl = _get_player()
    if pl and pl.has_method("shake"):
        pl.shake(5.0, 2.6)
    await _move_to(position.x, _hover_y, 2.4, Tween.TRANS_QUART)
    Game.sfx("boss_slam", 0.0, 0.8)
    if pl and pl.has_method("shake"):
        pl.shake(12.0, 0.5)
    Fx.burst(get_parent(), Vector2(position.x, ground_y - 10.0), Color(0.95, 0.5, 1.0), 26, 380.0, 0.8, 14.0, 300.0)
    _play("cast")
    await _wait(1.0)
    active = true
    health_changed.emit(hp, MAX_HP)
    intro_finished.emit()
    _fight_loop()


func _fight_loop() -> void:
    while not _dead:
        sprite.play("idle")
        vulnerable = true
        var pl = _get_player()
        var px := position.x
        if pl:
            px = pl.global_position.x
        var hover_time := 1.5 if _phase == 1 else 0.9
        await _move_to(px + randf_range(-160.0, 160.0), _hover_y, hover_time)
        if _dead:
            return
        var pick := _pick_attack()
        _last_attack = pick
        vulnerable = false
        match pick:
            "slam":
                await _attack_slam()
            "pillars":
                await _attack_pillars()
            "orbs":
                await _attack_orbs()
        if _dead:
            return
        await _recover(pick)


func _pick_attack() -> String:
    var options: Array = ["slam", "pillars", "orbs"]
    options.erase(_last_attack)
    return String(options[randi() % options.size()])


func _recover(pick: String) -> void:
    # exposed after every attack: stand low (extra reach for the player), flashing cyan
    vulnerable = true
    sprite.play("idle")
    var t := 1.6 if _phase == 1 else 1.1
    if pick != "slam":
        await _move_to(position.x, _low_y, 0.5)
    await _wait(t)


# ------------------------------------------------------------------ attacks
func _attack_slam() -> void:
    var pl = _get_player()
    var px := position.x
    if pl:
        px = pl.global_position.x
    await _move_to(px, _hover_y - 40.0, 0.55)
    if _dead:
        return
    _tint = Color(1.5, 0.7, 0.9, 1.0)
    _play("slam")
    Game.sfx("boss_warn", 0.0)
    # warning marker on the floor under the boss
    var mark := ColorRect.new()
    mark.color = Color(1.0, 0.3, 0.6, 0.25)
    mark.size = Vector2(240, 14)
    mark.position = Vector2(position.x - 120.0, ground_y - 12.0)
    mark.z_index = 3
    get_parent().add_child(mark)
    var mtw := mark.create_tween()
    mtw.set_loops(6)
    mtw.tween_property(mark, "color:a", 0.75, 0.07)
    mtw.tween_property(mark, "color:a", 0.15, 0.07)
    await _wait(0.45 if _phase == 1 else 0.32)
    if _dead:
        mark.queue_free()
        return
    await _move_to(position.x, _low_y, 0.14, Tween.TRANS_QUAD)
    mark.queue_free()
    _tint = Color(1, 1, 1, 1)
    _slam_impact()
    await _wait(0.35)


func _slam_impact() -> void:
    Game.sfx("boss_slam", 3.0)
    var pl = _get_player()
    if pl and pl.has_method("shake"):
        pl.shake(14.0, 0.4)
    Fx.burst(get_parent(), Vector2(position.x, ground_y - 8.0), Color(1.0, 0.5, 0.95), 28, 420.0, 0.7, 14.0, 360.0)
    if pl:
        var close := absf(pl.global_position.x - position.x) < 140.0
        if close and pl.global_position.y > ground_y - 40.0:
            pl.take_damage(20, global_position)
    # two shockwaves racing along the floor: jump them
    for d in [-1.0, 1.0]:
        var p = ProjectileScript.new()
        p.velocity = Vector2(float(d) * (380.0 if _phase == 1 else 470.0), 0)
        p.damage = 16
        p.radius = 22.0
        p.color = Color(1.0, 0.45, 0.85)
        p.life = 3.2
        p.stretch = Vector2(1.5, 1.0)
        p.position = Vector2(position.x + float(d) * 110.0, ground_y - 24.0)
        get_parent().add_child(p)


func _attack_pillars() -> void:
    _tint = Color(1.2, 0.8, 1.5, 1.0)
    _play("cast")
    Game.sfx("boss_warn", 0.0, 0.9)
    await _wait(0.7)
    if _dead:
        return
    _tint = Color(1, 1, 1, 1)
    var pl = _get_player()
    var count := 3 if _phase == 1 else 5
    for i in range(count):
        var x := position.x
        if pl:
            x = pl.global_position.x + (0.0 if i == 0 else randf_range(-260.0, 260.0))
        x = clampf(x, arena_l + 60.0, arena_r - 60.0)
        var pillar = PillarScript.new()
        pillar.position = Vector2(x, ground_y)
        get_parent().add_child(pillar)
        Game.sfx("boss_orb", -4.0, 0.7)
        await _wait(0.42 if _phase == 1 else 0.3)
        if _dead:
            return
    await _wait(1.0)


func _attack_orbs() -> void:
    _tint = Color(1.3, 0.8, 1.5, 1.0)
    _play("cast")
    Game.sfx("boss_warn", 0.0, 1.2)
    await _wait(0.75)
    if _dead:
        return
    _tint = Color(1, 1, 1, 1)
    var volleys := 2 if _phase == 1 else 3
    for v in range(volleys):
        var pl = _get_player()
        var target := Vector2(position.x - 200.0, ground_y - 60.0)
        if pl:
            target = pl.global_position + Vector2(0, -60)
        var base := (target - position).angle()
        var n := 5 if _phase == 1 else 7
        for i in range(n):
            var ang := base + (float(i) - float(n - 1) * 0.5) * 0.22
            var p = ProjectileScript.new()
            p.velocity = Vector2.from_angle(ang) * 400.0
            p.damage = 13
            p.radius = 15.0
            p.color = Color(0.95, 0.4, 1.0)
            p.life = 4.0
            p.position = position + Vector2(0, 20)
            get_parent().add_child(p)
        Game.sfx("boss_orb", 0.0, 1.0)
        var shake_p = _get_player()
        if shake_p and shake_p.has_method("shake"):
            shake_p.shake(3.0, 0.1)
        await _wait(0.65 if _phase == 1 else 0.5)
        if _dead:
            return
    await _wait(0.4)


# ------------------------------------------------------------------ damage
func take_damage(amount: int, _from: Vector2 = Vector2.ZERO) -> void:
    if _dead or not active:
        return
    var dmg := amount * (2 if vulnerable else 1)
    hp = maxi(hp - dmg, 0)
    _flash = 0.08
    health_changed.emit(hp, MAX_HP)
    Fx.burst(get_parent(), global_position + Vector2(randf_range(-60, 60), randf_range(-60, 60)), Color(1.0, 0.7, 1.0), 10, 260.0, 0.4, 10.0, 200.0)
    if hp <= 0:
        _die()
    elif _phase == 1 and hp <= MAX_HP / 2:
        _phase = 2
        Game.sfx("boss_intro", 0.0, 1.2)
        Game.toast.emit("THE GUARDIAN ENRAGES!")
        var pl = _get_player()
        if pl and pl.has_method("shake"):
            pl.shake(9.0, 0.5)
        Game.fade_flash(Color(0.8, 0.2, 0.9), 0.5)


func _die() -> void:
    _dead = true
    active = false
    vulnerable = false
    if _tween and _tween.is_valid():
        _tween.kill()
    _tint = Color(1, 1, 1, 1)
    for n in get_tree().get_nodes_in_group("enemy_projectile"):
        n.queue_free()
    sprite.play("dead")
    sprite.frame = 0
    Game.sfx("boss_intro", 3.0, 0.6)
    Game.hitstop(0.25, 0.06)
    var pl = _get_player()
    # explosive death sequence
    for i in range(9):
        if pl and pl.has_method("shake"):
            pl.shake(10.0, 0.3)
        Fx.burst(get_parent(), global_position + Vector2(randf_range(-90, 90), randf_range(-110, 90)), Color(1.0, 0.55, 1.0), 20, 340.0, 0.7, 13.0, 200.0)
        Game.sfx("boss_slam", -2.0, randf_range(0.7, 1.4))
        await get_tree().create_timer(0.24).timeout
    Game.fade_flash(Color(1.0, 0.9, 1.0), 0.9)
    var tw := create_tween()
    tw.tween_property(sprite, "modulate:a", 0.0, 0.7)
    await tw.finished
    Game.add_score(5000)
    defeated.emit()
    queue_free()
