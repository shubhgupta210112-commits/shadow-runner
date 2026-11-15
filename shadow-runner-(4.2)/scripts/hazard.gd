extends Area2D
## Hazards: "spikes" (width in px) and "saw" (moves between two x positions).

var kind: String = "spikes"
var width: float = 96.0
var damage: int = 15
var x_a: float = 0.0
var x_b: float = 0.0
var speed: float = 110.0
var _dir: float = 1.0
var _spr: Sprite2D


func _ready() -> void:
    collision_layer = 0
    collision_mask = 2
    var cs := CollisionShape2D.new()
    if kind == "spikes":
        var sh := RectangleShape2D.new()
        sh.size = Vector2(width - 14.0, 26.0)
        cs.shape = sh
        cs.position = Vector2(width * 0.5, -17)
        var t := Sprite2D.new()
        t.texture = load("res://assets/environments/spikes.png")
        t.centered = false
        t.position = Vector2(0, -44)
        t.region_enabled = true
        t.region_rect = Rect2(0, 0, width, 44)
        t.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
        add_child(t)
        z_index = 3
    else:
        var sh2 := CircleShape2D.new()
        sh2.radius = 38.0
        cs.shape = sh2
        _spr = Sprite2D.new()
        _spr.texture = load("res://assets/environments/saw.png")
        add_child(_spr)
        damage = 20
        z_index = 3
    add_child(cs)


func _physics_process(delta: float) -> void:
    if kind == "saw":
        _spr.rotation += delta * 9.0
        position.x += _dir * speed * delta
        if position.x > x_b:
            _dir = -1.0
        elif position.x < x_a:
            _dir = 1.0
    for b in get_overlapping_bodies():
        if b.is_in_group("player"):
            b.call("take_damage", damage, global_position)
