extends Node2D
## Scrolling parallax scene used behind menus: sky, mountains, forest, a lit
## platform with the Runner idling on it, fireflies and drifting fog.

const LAYERS := [
	["res://assets/backgrounds/sky.png", 0.0],
	["res://assets/backgrounds/mountains_far.png", 4.0],
	["res://assets/backgrounds/mountains_near.png", 8.0],
	["res://assets/backgrounds/forest_mid.png", 14.0],
	["res://assets/backgrounds/trees_near.png", 26.0],
	["res://assets/backgrounds/fog.png", 18.0],
]

var _sprites: Array[Sprite2D] = []
var _speeds: Array[float] = []
var _offsets: Array[float] = []


func _ready() -> void:
	for entry in LAYERS:
		var s := Sprite2D.new()
		s.texture = load(entry[0]) as Texture2D
		s.centered = false
		s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		s.region_enabled = true
		s.region_rect = Rect2(0, 0, 640, 360)
		add_child(s)
		_sprites.append(s)
		_speeds.append(entry[1])
		_offsets.append(0.0)
	var runner := AnimatedSprite2D.new()
	runner.sprite_frames = load("res://assets/sprites/player_frames.tres") as SpriteFrames
	runner.play("idle")
	runner.position = Vector2(112, 306)
	runner.offset = Vector2(0, -16)
	add_child(runner)
	var ground := ColorRect.new()
	ground.color = Color(0.06, 0.05, 0.12)
	ground.position = Vector2(0, 306)
	ground.size = Vector2(640, 60)
	add_child(ground)
	var edge := ColorRect.new()
	edge.color = Color(0.31, 0.71, 0.6)
	edge.position = Vector2(0, 306)
	edge.size = Vector2(640, 2)
	add_child(edge)
	var ff := CPUParticles2D.new()
	ff.texture = load("res://assets/sprites/particle_dot.png") as Texture2D
	ff.amount = 36
	ff.lifetime = 7.0
	ff.preprocess = 7.0
	ff.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	ff.emission_rect_extents = Vector2(330, 100)
	ff.position = Vector2(320, 230)
	ff.direction = Vector2(0, -1)
	ff.spread = 180.0
	ff.gravity = Vector2.ZERO
	ff.initial_velocity_min = 3.0
	ff.initial_velocity_max = 10.0
	ff.color = Color(0.5, 0.97, 1.0, 0.9)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.add_point(0.3, Color(1, 1, 1, 1))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
	ff.color_ramp = g
	add_child(ff)


func _process(delta: float) -> void:
	for i in _sprites.size():
		_offsets[i] += _speeds[i] * delta
		var sz := _sprites[i].texture.get_size()
		var x := fmod(_offsets[i], sz.x)
		_sprites[i].region_rect = Rect2(x, 0, 640, sz.y)
