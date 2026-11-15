extends AnimatableBody2D
## One-way moving platform. node origin = centre of the top surface.

var travel: Vector2 = Vector2(140, 0)
var rate: float = 1.0
var width: float = 160.0
var _origin: Vector2
var _t: float = 0.0


func _ready() -> void:
    collision_layer = 1
    collision_mask = 0
    sync_to_physics = true
    _origin = position
    var cs := CollisionShape2D.new()
    var sh := RectangleShape2D.new()
    sh.size = Vector2(width - 10.0, 22.0)
    cs.shape = sh
    cs.position = Vector2(0, 11)
    cs.one_way_collision = true
    add_child(cs)
    var spr := Sprite2D.new()
    spr.texture = load("res://assets/environments/plat_move.png")
    spr.position = Vector2(0, 22)
    spr.scale = Vector2(width / 160.0, 1.0)
    add_child(spr)
    z_index = 2
    _t = randf() * 0.0


func _physics_process(delta: float) -> void:
    _t += delta * rate
    var k := 0.5 - 0.5 * cos(_t)
    position = _origin + travel * k
