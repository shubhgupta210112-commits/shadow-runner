extends RefCounted
## Static visual-effect helpers (particle bursts, floating text).
## Use:  const Fx := preload("res://scripts/fx.gd")  then  Fx.burst(...)

const DOT := preload("res://assets/sprites/particle_dot.png")
const SQUARE := preload("res://assets/sprites/particle_sq.png")

static var _fade_gradient: Gradient


static func _gradient() -> Gradient:
	if _fade_gradient == null:
		_fade_gradient = Gradient.new()
		_fade_gradient.set_color(0, Color(1, 1, 1, 1))
		_fade_gradient.set_color(1, Color(1, 1, 1, 0))
	return _fade_gradient


static func burst(parent: Node, pos: Vector2, color: Color, amount: int = 10, speed: float = 80.0,
		lifetime: float = 0.5, gravity: float = 200.0, spread: float = 180.0,
		dir: Vector2 = Vector2.UP, size: float = 1.0, square: bool = false) -> CPUParticles2D:
	if parent == null or not parent.is_inside_tree():
		return null
	var p := CPUParticles2D.new()
	p.texture = SQUARE if square else DOT
	p.one_shot = true
	p.amount = amount
	p.lifetime = lifetime
	p.explosiveness = 1.0
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, gravity)
	p.color = color
	p.color_ramp = _gradient()
	p.scale_amount_min = size * 0.8
	p.scale_amount_max = size * 1.4
	p.z_index = 20
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


static func dust(parent: Node, pos: Vector2, strong: bool = false) -> void:
	burst(parent, pos, Color(0.62, 0.58, 0.8, 0.9), 8 if strong else 4, 40.0 if strong else 22.0,
			0.35, 30.0, 70.0, Vector2.UP, 1.0, true)


static func sparkle(parent: Node, pos: Vector2, color: Color) -> void:
	burst(parent, pos, color, 12, 60.0, 0.55, 40.0, 180.0, Vector2.UP, 1.0, false)


static func popup_text(parent: Node, pos: Vector2, text: String, color: Color = Color(1, 0.85, 0.4)) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.1))
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_font_size_override("font_size", 8)
	label.z_index = 50
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	label.global_position = pos - Vector2(label.size.x * 0.5, 0)
	var tw := label.create_tween().set_parallel(true)
	tw.tween_property(label, "global_position:y", pos.y - 22.0, 0.8).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tw.chain().tween_callback(label.queue_free)
