extends Area2D
## Generic projectile: the player's Shadow Bolt, spores, boss orbs, falling
## spears and ground shockwaves. Call setup() before adding to the tree.

const Fx := preload("res://scripts/fx.gd")
const LIGHT := preload("res://assets/lights/light_soft.png")

const STYLES := {
	&"bolt": {
		"frames": preload("res://assets/sprites/bolt_frames.tres"),
		"color": Color(0.5, 0.97, 1.0), "shape": Vector2(7, 7), "light": 0.5, "hits_world": true,
	},
	&"spore": {
		"frames": preload("res://assets/sprites/spore_frames.tres"),
		"color": Color(0.88, 0.29, 0.82), "shape": Vector2(8, 8), "light": 0.4, "hits_world": true,
	},
	&"orb": {
		"frames": preload("res://assets/sprites/orb_frames.tres"),
		"color": Color(0.88, 0.29, 0.82), "shape": Vector2(10, 10), "light": 0.6, "hits_world": true,
	},
	&"spear": {
		"frames": preload("res://assets/sprites/spear_frames.tres"),
		"color": Color(0.88, 0.29, 0.82), "shape": Vector2(6, 26), "light": 0.55, "hits_world": true,
	},
	&"wave": {
		"frames": preload("res://assets/sprites/wave_frames.tres"),
		"color": Color(1.0, 0.62, 0.95), "shape": Vector2(14, 14), "light": 0.45, "hits_world": false,
	},
}

var style: StringName = &"bolt"
var team: int = 0  # 0 = player, 1 = enemy
var damage: int = 1
var velocity: Vector2 = Vector2.ZERO
var fall_accel: float = 0.0
var lifetime: float = 2.0
var delay: float = 0.0
var pierce: bool = false
var bounds_x: Vector2 = Vector2(-1e9, 1e9)

var _armed: bool = true
var _hit: bool = false

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var shape: CollisionShape2D = $Shape


func setup(p_style: StringName, p_velocity: Vector2, p_damage: int, p_team: int,
		p_gravity: float = 0.0, p_lifetime: float = 2.0, p_delay: float = 0.0, p_pierce: bool = false) -> void:
	style = p_style
	velocity = p_velocity
	damage = p_damage
	team = p_team
	fall_accel = p_gravity
	lifetime = p_lifetime
	delay = p_delay
	pierce = p_pierce


func _ready() -> void:
	var cfg: Dictionary = STYLES[style]
	sprite.sprite_frames = cfg["frames"]
	sprite.play(sprite.sprite_frames.get_animation_names()[0])
	var rect := RectangleShape2D.new()
	rect.size = cfg["shape"]
	shape.shape = rect
	if team == 0:
		collision_layer = 64
		collision_mask = 1 | 8
	else:
		collision_layer = 128
		collision_mask = 1 if cfg["hits_world"] else 0
	var light := PointLight2D.new()
	light.texture = LIGHT
	light.color = cfg["color"]
	light.energy = cfg["light"]
	light.texture_scale = 0.35
	add_child(light)
	z_index = 10
	if delay > 0.0:
		_armed = false
		monitoring = false
		monitorable = false
		sprite.modulate.a = 0.45
	else:
		_arm()
	if velocity.x < 0.0 and style != &"spear":
		sprite.flip_h = true
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _arm() -> void:
	_armed = true
	monitoring = true
	monitorable = true
	sprite.modulate.a = 1.0


func _physics_process(delta: float) -> void:
	if not _armed:
		delay -= delta
		sprite.modulate.a = 0.35 + 0.35 * absf(sin(delay * 18.0))
		if delay <= 0.0:
			_arm()
		return
	velocity.y += fall_accel * delta
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0 or position.x < bounds_x.x or position.x > bounds_x.y:
		_expire()


func _expire() -> void:
	if _hit:
		return
	_hit = true
	queue_free()


func _pop() -> void:
	var cfg: Dictionary = STYLES[style]
	Fx.burst(get_parent(), global_position, cfg["color"], 6, 50.0, 0.3, 80.0)


func _on_body_entered(_body: Node) -> void:
	if _hit or not _armed:
		return
	_hit = true
	_pop()
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _hit or team != 0:
		return
	var target: Node = area.get_parent()
	if target != null and target.has_method("take_hit"):
		if target.take_hit(damage, self):
			if not pierce:
				_hit = true
				_pop()
				queue_free()


## Called by the player's hurtbox poll when this (enemy) projectile overlaps it.
func on_player_contact(player: Node) -> void:
	if _hit or team != 1 or not _armed:
		return
	if player.take_damage(damage, global_position.x):
		if not pierce:
			_hit = true
			_pop()
			queue_free()
