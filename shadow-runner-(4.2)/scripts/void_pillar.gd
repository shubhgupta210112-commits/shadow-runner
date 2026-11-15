extends Node2D
## Boss attack: a flashing warning column that erupts into a damaging pillar of void energy.

const WARN_TIME := 1.05
const ACTIVE_TIME := 0.4
const Fx = preload("res://scripts/fx.gd")

var ground_y: float = 560.0
var half_width: float = 34.0
var _t: float = 0.0
var _rect: ColorRect
var _area: Area2D
var _fired: bool = false


func _ready() -> void:
    z_index = 5
    _rect = ColorRect.new()
    _rect.size = Vector2(half_width * 2.0, 520)
    _rect.position = Vector2(-half_width, -520)
    _rect.color = Color(1.0, 0.2, 0.7, 0.12)
    add_child(_rect)
    _area = Area2D.new()
    _area.collision_layer = 0
    _area.collision_mask = 2
    _area.monitoring = false
    var cs := CollisionShape2D.new()
    var sh := RectangleShape2D.new()
    sh.size = Vector2(half_width * 1.7, 520)
    cs.shape = sh
    cs.position = Vector2(0, -260)
    _area.add_child(cs)
    add_child(_area)


func _physics_process(delta: float) -> void:
    _t += delta
    if _t < WARN_TIME:
        var f := 0.5 + 0.5 * sin(_t * 26.0)
        _rect.color = Color(1.0, 0.25, 0.7, 0.10 + 0.16 * f)
    elif _t < WARN_TIME + ACTIVE_TIME:
        if not _fired:
            _fired = true
            _area.monitoring = true
            Game.sfx("boss_slam", -6.0, 1.4)
            Fx.burst(get_parent(), global_position + Vector2(0, -10), Color(1.0, 0.5, 0.95), 18, 260.0, 0.6, 12.0, 300.0)
            var sc := get_tree().get_first_node_in_group("player")
            if sc and sc.has_method("shake"):
                sc.call("shake", 7.0, 0.25)
        _rect.color = Color(1.0, 0.7, 1.0, 0.85)
        _rect.size.x = half_width * 1.6
        _rect.position.x = -half_width * 0.8
        for b in _area.get_overlapping_bodies():
            if b.is_in_group("player"):
                b.call("take_damage", 20, global_position)
    else:
        queue_free()
