extends Area2D
## Enemy / boss projectile. Can be destroyed by the player's sword.

const Fx = preload("res://scripts/fx.gd")

var velocity: Vector2 = Vector2.ZERO
var damage: int = 15
var color: Color = Color(1.0, 0.35, 0.3)
var radius: float = 12.0
var life: float = 4.0
#var gravity: float = 0.0
var stretch: Vector2 = Vector2(1, 1)
var _glow: Sprite2D


func _ready() -> void:
	add_to_group("enemy_projectile")
	collision_layer = 4
	collision_mask = 3
	monitoring = true
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = radius
	cs.shape = sh
	add_child(cs)
	_glow = Sprite2D.new()
	_glow.texture = load("res://assets/effects/glow.png")
	_glow.modulate = color
	_glow.scale = Vector2(radius / 20.0, radius / 20.0) * stretch
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = mat
	add_child(_glow)
	var core := Sprite2D.new()
	core.texture = load("res://assets/effects/glow.png")
	core.modulate = Color(1, 1, 1, 0.95)
	core.scale = Vector2(radius / 50.0, radius / 50.0) * stretch
	var mat2 := CanvasItemMaterial.new()
	mat2.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	core.material = mat2
	add_child(core)
	z_index = 6
	body_entered.connect(_on_body)


func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	global_position += velocity * delta
	life -= delta
	_glow.rotation += delta * 6.0
	if life <= 0.0:
		queue_free()


func _on_body(body: Node) -> void:
	if body.is_in_group("player"):
		body.call("take_damage", damage, global_position)
		_pop()
	else:
		_pop()


func take_damage(_amount: int = 1, _from: Vector2 = Vector2.ZERO) -> void:
	Game.add_score(10)
	_pop()


func _pop() -> void:
	Fx.burst(get_parent(), global_position, color, 10, 150.0, 0.4, 7.0, 0.0)
	queue_free()
