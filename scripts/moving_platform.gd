extends AnimatableBody2D
## One-way moving platform. Oscillates between its start and start+travel.
## Uses sync_to_physics so riders move with it smoothly.

@export var travel: Vector2 = Vector2(96, 0)
@export var period: float = 4.0
@export var phase: float = 0.0
@export var width_tiles: int = 3

var _origin: Vector2
var _t: float = 0.0


func _ready() -> void:
	_origin = position
	collision_layer = 2
	collision_mask = 0
	sync_to_physics = true
	_t = phase * period
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width_tiles * 16.0, 6.0)
	$Shape.shape = rect
	$Shape.position = Vector2(width_tiles * 8.0, 3.0)
	$Shape.one_way_collision = true
	$Shape.one_way_collision_margin = 4.0
	var frames := load("res://assets/sprites/plat_frames.tres") as SpriteFrames
	for i in width_tiles:
		var s := AnimatedSprite2D.new()
		s.sprite_frames = frames
		s.centered = false
		s.position = Vector2(i * 16.0, -3.0)
		s.animation = "l" if i == 0 else ("r" if i == width_tiles - 1 else "mid")
		add_child(s)


func _physics_process(delta: float) -> void:
	_t += delta
	var k := (1.0 - cos(_t / period * TAU)) * 0.5
	position = _origin + travel * k
