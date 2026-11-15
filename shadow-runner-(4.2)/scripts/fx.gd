extends RefCounted
## Small one-shot particle helpers (CPUParticles2D keeps Android/web compatibility and cost low).

const PARTICLE_TEX := "res://assets/effects/particle.png"


static func burst(parent: Node, pos: Vector2, color: Color, amount: int = 12, speed: float = 160.0, life: float = 0.5,
        size: float = 8.0, gravity: float = 420.0, spread: float = 180.0, dir: Vector2 = Vector2.UP) -> void:
    if parent == null or not parent.is_inside_tree():
        return
    var p := CPUParticles2D.new()
    p.emitting = false
    p.one_shot = true
    p.amount = amount
    p.lifetime = life
    p.explosiveness = 1.0
    p.direction = dir
    p.spread = spread
    p.initial_velocity_min = speed * 0.45
    p.initial_velocity_max = speed
    p.gravity = Vector2(0, gravity)
    p.scale_amount_min = size * 0.5 / 32.0
    p.scale_amount_max = size / 32.0
    p.color = color
    p.texture = load(PARTICLE_TEX)
    var g := Gradient.new()
    g.set_color(0, Color(1, 1, 1, 1))
    g.set_color(1, Color(1, 1, 1, 0))
    p.color_ramp = g
    var m := CanvasItemMaterial.new()
    m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    p.material = m
    p.z_index = 20
    parent.add_child(p)
    p.global_position = pos
    p.emitting = true
    parent.get_tree().create_timer(life + 0.4).timeout.connect(p.queue_free)


static func embers(parent: Node, extents: Vector2, amount: int = 36) -> CPUParticles2D:
    var p := CPUParticles2D.new()
    p.amount = amount
    p.lifetime = 7.0
    p.preprocess = 7.0
    p.local_coords = false
    p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
    p.emission_rect_extents = extents
    p.direction = Vector2(0.4, -1.0)
    p.spread = 25.0
    p.initial_velocity_min = 12.0
    p.initial_velocity_max = 40.0
    p.gravity = Vector2(14, -6)
    p.scale_amount_min = 4.0 / 32.0
    p.scale_amount_max = 9.0 / 32.0
    p.color = Color(1.0, 0.62, 0.9, 0.8)
    p.texture = load(PARTICLE_TEX)
    var g := Gradient.new()
    g.set_color(0, Color(1, 1, 1, 0))
    g.add_point(0.25, Color(1, 1, 1, 1))
    g.set_color(1, Color(1, 1, 1, 0))
    p.color_ramp = g
    var m := CanvasItemMaterial.new()
    m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    p.material = m
    p.z_index = 15
    parent.add_child(p)
    return p
