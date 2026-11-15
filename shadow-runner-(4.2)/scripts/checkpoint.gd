extends Area2D
## Beacon checkpoint. Position the node at the beacon base (ground level).

const Fx = preload("res://scripts/fx.gd")

var active: bool = false
var _off: Sprite2D
var _on: Sprite2D
var _light: PointLight2D


func _ready() -> void:
    collision_layer = 0
    collision_mask = 2
    var cs := CollisionShape2D.new()
    var sh := RectangleShape2D.new()
    sh.size = Vector2(90, 170)
    cs.shape = sh
    cs.position = Vector2(0, -85)
    add_child(cs)
    _off = Sprite2D.new()
    _off.texture = load("res://assets/environments/beacon_off.png")
    _off.position = Vector2(0, -85)
    add_child(_off)
    _on = Sprite2D.new()
    _on.texture = load("res://assets/environments/beacon_on.png")
    _on.position = Vector2(0, -85)
    _on.visible = false
    add_child(_on)
    _light = PointLight2D.new()
    _light.texture = load("res://assets/effects/light.png")
    _light.color = Color(0.4, 0.95, 1.0)
    _light.energy = 0.0
    _light.texture_scale = 2.4
    _light.position = Vector2(0, -120)
    add_child(_light)
    z_index = 2
    body_entered.connect(_on_body)


func _on_body(body: Node) -> void:
    if active or not body.is_in_group("player"):
        return
    if global_position.x < Game.checkpoint_pos.x - 5.0:
        return
    activate()


func activate() -> void:
    active = true
    Game.checkpoint_pos = global_position + Vector2(0, -60)
    _off.visible = false
    _on.visible = true
    var tw := create_tween()
    tw.tween_property(_light, "energy", 1.1, 0.5)
    Game.sfx("checkpoint")
    Game.toast.emit("CHECKPOINT")
    Fx.burst(get_parent(), global_position + Vector2(0, -120), Color(0.5, 0.95, 1.0), 20, 200.0, 0.8, 9.0, 150.0)
