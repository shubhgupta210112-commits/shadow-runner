extends Area2D
## Collectibles: "crystal", "gold" (hidden crystal) and "heart" (health).

const Fx = preload("res://scripts/fx.gd")

var kind: String = "crystal"
var _sprite: Sprite2D
var _glow: Sprite2D
var _t: float = 0.0
var _base_y: float = 0.0
var _done: bool = false


func _ready() -> void:
    collision_layer = 0
    collision_mask = 2
    var cs := CollisionShape2D.new()
    var sh := CircleShape2D.new()
    sh.radius = 30.0 if kind != "gold" else 36.0
    cs.shape = sh
    add_child(cs)
    _glow = Sprite2D.new()
    _glow.texture = load("res://assets/effects/glow.png")
    var gcol := Color(0.3, 0.9, 1.0, 0.65)
    if kind == "gold":
        gcol = Color(1.0, 0.75, 0.2, 0.8)
    elif kind == "heart":
        gcol = Color(0.3, 1.0, 0.6, 0.7)
    _glow.modulate = gcol
    _glow.scale = Vector2(0.75, 0.75)
    var mat := CanvasItemMaterial.new()
    mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    _glow.material = mat
    add_child(_glow)
    _sprite = Sprite2D.new()
    var path := "res://assets/environments/crystal.png"
    if kind == "gold":
        path = "res://assets/environments/crystal_gold.png"
    elif kind == "heart":
        path = "res://assets/environments/heart.png"
    _sprite.texture = load(path)
    var s := 0.62 if kind == "crystal" else (0.85 if kind == "gold" else 0.7)
    _sprite.scale = Vector2(s, s)
    add_child(_sprite)
    _base_y = position.y
    _t = randf() * TAU
    z_index = 4
    body_entered.connect(_on_body)


func _process(delta: float) -> void:
    _t += delta * 3.0
    _sprite.position.y = sin(_t) * 5.0
    _glow.scale = Vector2(0.7, 0.7) * (1.0 + 0.12 * sin(_t * 1.7))


func _on_body(body: Node) -> void:
    if _done or not body.is_in_group("player"):
        return
    _done = true
    match kind:
        "crystal":
            Game.add_crystal(1)
            Game.add_score(100)
            Game.sfx("crystal", -3.0, randf_range(0.95, 1.15))
            Fx.burst(get_parent(), global_position, Color(0.5, 0.95, 1.0), 8, 140.0, 0.45, 8.0, 200.0)
        "gold":
            Game.add_crystal(5, true)
            Game.add_score(750)
            Game.sfx("crystal", 0.0, 0.8)
            Game.sfx("checkpoint", -6.0)
            Fx.burst(get_parent(), global_position, Color(1.0, 0.85, 0.3), 22, 220.0, 0.7, 10.0, 260.0)
            Game.toast.emit("HIDDEN CRYSTAL FOUND!  +5")
        "heart":
            if body.has_method("heal"):
                body.call("heal", 35)
            Game.add_score(50)
            Game.sfx("health")
            Fx.burst(get_parent(), global_position, Color(0.4, 1.0, 0.7), 16, 160.0, 0.6, 9.0, 120.0)
            Game.toast.emit("+ HEALTH")
    queue_free()
