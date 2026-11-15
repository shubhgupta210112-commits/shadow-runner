extends Node
## Generates the TileSet, UI theme and every .tscn in scenes/ (including the
## full level layout). Run (after tools/build_frames.gd):
##   godot --headless --path . res://tools/builder.tscn
##
## The generated scenes are plain Godot scenes: open and edit them in the editor.

const T := 16
const LIGHT_SOFT := "res://assets/lights/light_soft.png"

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 20260101
	_build_theme()
	_build_tileset()
	_scene_projectile()
	_scene_player()
	_scene_enemy()
	_scene_boss()
	_scene_pickup()
	_scene_hazard()
	_scene_checkpoint()
	_scene_platform()
	_scene_switch_gate()
	_scene_exit()
	_scene_ui_scripts()
	_scene_level()
	_scene_game()
	print("scenes built OK")
	get_tree().quit()


# ------------------------------------------------------------------ helpers
func _add(parent: Node, child: Node, root: Node, node_name: String = "") -> Node:
	if node_name != "":
		child.name = node_name
	parent.add_child(child)
	child.owner = root
	return child


func _save(root: Node, path: String) -> void:
	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err != OK:
		push_error("pack failed for %s (%d)" % [path, err])
		return
	err = ResourceSaver.save(ps, path)
	if err != OK:
		push_error("save failed for %s (%d)" % [path, err])
	root.free()


func _rect(w: float, h: float, pos: Vector2 = Vector2.ZERO) -> CollisionShape2D:
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(w, h)
	cs.shape = r
	cs.position = pos
	return cs


func _anim(frames_name: String, anim_name: String = "", pos: Vector2 = Vector2.ZERO) -> AnimatedSprite2D:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = load("res://assets/sprites/%s_frames.tres" % frames_name) as SpriteFrames
	s.position = pos
	if anim_name == "":
		anim_name = s.sprite_frames.get_animation_names()[0]
	s.animation = anim_name
	s.autoplay = anim_name
	return s


func _light(color: Color, energy: float, scale_f: float, pos: Vector2 = Vector2.ZERO) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = load(LIGHT_SOFT) as Texture2D
	l.color = color
	l.energy = energy
	l.texture_scale = scale_f
	l.position = pos
	return l


# ------------------------------------------------------------------ theme + tileset
func _build_theme() -> void:
	var theme := Theme.new()
	var font := load("res://assets/fonts/Silkscreen-Regular.ttf") as Font
	theme.default_font = font
	theme.default_font_size = 8
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.1, 0.24)
	sb.border_color = Color(0.35, 0.3, 0.6)
	sb.set_border_width_all(2)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	var hv := sb.duplicate() as StyleBoxFlat
	hv.bg_color = Color(0.2, 0.15, 0.38)
	hv.border_color = Color(0.5, 0.97, 1.0)
	theme.set_stylebox("normal", "Button", sb)
	theme.set_stylebox("hover", "Button", hv)
	theme.set_stylebox("focus", "Button", hv)
	theme.set_stylebox("pressed", "Button", hv)
	theme.set_color("font_color", "Button", Color(0.88, 0.92, 1.0))
	theme.set_color("font_color", "Label", Color(0.88, 0.92, 1.0))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/ui"))
	var err := ResourceSaver.save(theme, "res://assets/ui/theme.tres")
	if err != OK:
		push_error("theme save failed")


func _build_tileset() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/tiles/tileset.png") as Texture2D
	src.texture_region_size = Vector2i(T, T)
	ts.add_source(src, 0)
	for y in 2:
		for x in 11:
			src.create_tile(Vector2i(x, y))
			var td := src.get_tile_data(Vector2i(x, y), 0)
			td.add_collision_polygon(0)
			td.set_collision_polygon_points(0, 0, PackedVector2Array([
				Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]))
	var err := ResourceSaver.save(ts, "res://assets/tiles/tileset.tres")
	if err != OK:
		push_error("tileset save failed")


# ------------------------------------------------------------------ simple scenes
func _scene_projectile() -> void:
	var root := Area2D.new()
	root.name = "Projectile"
	root.set_script(load("res://scripts/projectile.gd"))
	_add(root, AnimatedSprite2D.new(), root, "Sprite")
	_add(root, _rect(8, 8), root, "Shape")
	_save(root, "res://scenes/projectile.tscn")


func _scene_player() -> void:
	var root := CharacterBody2D.new()
	root.name = "Player"
	root.set_script(load("res://scripts/player.gd"))
	root.collision_layer = 4
	root.collision_mask = 3
	root.z_index = 5
	_add(root, _anim("player", "idle", Vector2(0, -16)), root, "Sprite")
	_add(root, _rect(12, 26, Vector2(0, -13)), root, "Body")
	var hurt := Area2D.new()
	hurt.collision_layer = 0
	hurt.collision_mask = 8 | 16 | 128
	_add(root, hurt, root, "Hurtbox")
	_add(hurt, _rect(12, 24, Vector2(0, -14)), root, "Shape")
	var sensor := Area2D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 256
	_add(root, sensor, root, "InteractSensor")
	_add(sensor, _rect(34, 30, Vector2(0, -15)), root, "Shape")
	_add(root, _light(Color(0.5, 0.97, 1.0), 0.8, 2.4, Vector2(0, -14)), root, "Glow")
	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 7.0
	cam.limit_smoothed = true
	cam.offset = Vector2(0, -26)
	_add(root, cam, root, "Camera")
	_add(root, Marker2D.new(), root, "BoltSpawn")
	var ff := CPUParticles2D.new()
	ff.texture = load("res://assets/sprites/particle_dot.png") as Texture2D
	ff.amount = 34
	ff.lifetime = 6.0
	ff.preprocess = 6.0
	ff.local_coords = false
	ff.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	ff.emission_rect_extents = Vector2(340, 190)
	ff.position = Vector2(0, -40)
	ff.direction = Vector2(0, -1)
	ff.spread = 180.0
	ff.gravity = Vector2.ZERO
	ff.initial_velocity_min = 2.0
	ff.initial_velocity_max = 9.0
	ff.color = Color(0.7, 1.0, 0.9, 0.9)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.add_point(0.35, Color(1, 1, 1, 1))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
	ff.color_ramp = g
	ff.z_index = -1
	_add(root, ff, root, "Fireflies")
	_save(root, "res://scenes/player.tscn")


func _scene_enemy() -> void:
	var root := CharacterBody2D.new()
	root.name = "Enemy"
	root.set_script(load("res://scripts/enemy.gd"))
	root.collision_layer = 0
	root.collision_mask = 3
	root.z_index = 1
	_add(root, AnimatedSprite2D.new(), root, "Sprite")
	_add(root, CollisionShape2D.new(), root, "Body")
	var hb := Area2D.new()
	hb.collision_layer = 8
	hb.collision_mask = 0
	_add(root, hb, root, "Hitbox")
	_add(hb, CollisionShape2D.new(), root, "Shape")
	var fr := RayCast2D.new()
	fr.target_position = Vector2(0, 14)
	fr.collision_mask = 3
	_add(root, fr, root, "FloorRay")
	var wr := RayCast2D.new()
	wr.target_position = Vector2(14, 0)
	wr.collision_mask = 1
	_add(root, wr, root, "WallRay")
	_save(root, "res://scenes/enemy.tscn")


func _scene_boss() -> void:
	var root := CharacterBody2D.new()
	root.name = "Boss"
	root.set_script(load("res://scripts/boss.gd"))
	root.collision_layer = 0
	root.collision_mask = 1
	root.z_index = 2
	_add(root, _anim("boss", "idle", Vector2(0, -48)), root, "Sprite")
	_add(root, _rect(60, 44, Vector2(0, -22)), root, "Body")
	var hb := Area2D.new()
	hb.collision_layer = 8
	hb.collision_mask = 0
	_add(root, hb, root, "Hitbox")
	_add(hb, _rect(64, 60, Vector2(0, -32)), root, "Shape")
	var ws := Area2D.new()
	ws.collision_layer = 0
	ws.collision_mask = 0
	_add(root, ws, root, "WeakSpot")
	_add(ws, _rect(24, 12, Vector2(20, -62)), root, "Shape")
	_add(root, _light(Color(0.88, 0.29, 0.82), 0.9, 3.0, Vector2(10, -40)), root, "Aura")
	_save(root, "res://scenes/boss.tscn")


func _scene_pickup() -> void:
	var root := Area2D.new()
	root.name = "Pickup"
	root.set_script(load("res://scripts/pickup.gd"))
	var s := AnimatedSprite2D.new()
	_add(root, s, root, "Sprite")
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 8.0
	cs.shape = c
	_add(root, cs, root, "Shape")
	_save(root, "res://scenes/pickup.tscn")


func _scene_hazard() -> void:
	var root := Area2D.new()
	root.name = "Spikes"
	root.set_script(load("res://scripts/hazard.gd"))
	var s := _anim("spikes", "default", Vector2(8, -4))
	_add(root, s, root, "Sprite")
	_add(root, _rect(12, 6, Vector2(8, -3)), root, "Shape")
	_save(root, "res://scenes/hazard.tscn")


func _scene_checkpoint() -> void:
	var root := Area2D.new()
	root.name = "Checkpoint"
	root.set_script(load("res://scripts/checkpoint.gd"))
	_add(root, _anim("checkpoint", "off", Vector2(0, -20)), root, "Sprite")
	_add(root, _rect(24, 40, Vector2(0, -20)), root, "Shape")
	_add(root, _light(Color(0.5, 0.97, 1.0), 0.9, 2.6, Vector2(0, -30)), root, "Light")
	_save(root, "res://scenes/checkpoint.tscn")


func _scene_platform() -> void:
	var root := AnimatableBody2D.new()
	root.name = "Platform"
	root.set_script(load("res://scripts/moving_platform.gd"))
	var cs := CollisionShape2D.new()
	_add(root, cs, root, "Shape")
	_save(root, "res://scenes/moving_platform.tscn")


func _scene_switch_gate() -> void:
	var root := Node2D.new()
	root.name = "SwitchGate"
	root.set_script(load("res://scripts/switch_gate.gd"))
	var lever := Area2D.new()
	lever.set_script(load("res://scripts/interactable.gd"))
	_add(root, lever, root, "Lever")
	_add(lever, _anim("lever", "off", Vector2(0, -8)), root, "Sprite")
	_add(lever, _rect(26, 26, Vector2(0, -12)), root, "Shape")
	var gate := StaticBody2D.new()
	gate.collision_layer = 1
	gate.collision_mask = 0
	_add(root, gate, root, "Gate")
	_add(gate, _anim("gate", "glow", Vector2(0, -32)), root, "Sprite")
	_add(gate, _rect(14, 128, Vector2(0, -64)), root, "Shape")
	_add(gate, _light(Color(0.88, 0.29, 0.82), 0.9, 2.8, Vector2(0, -64)), root, "Light")
	_save(root, "res://scenes/switch_gate.tscn")


func _scene_exit() -> void:
	var root := Area2D.new()
	root.name = "Exit"
	root.set_script(load("res://scripts/level_exit.gd"))
	_add(root, _anim("portal", "swirl", Vector2(0, -24)), root, "Sprite")
	_add(root, _rect(20, 40, Vector2(0, -24)), root, "Shape")
	_add(root, _light(Color(0.5, 0.97, 1.0), 1.1, 3.4, Vector2(0, -24)), root, "Light")
	_save(root, "res://scenes/level_exit.tscn")


func _scene_ui_scripts() -> void:
	var specs := {
		"hud": ["CanvasLayer", "res://scripts/hud.gd"],
		"pause_menu": ["CanvasLayer", "res://scripts/pause_menu.gd"],
		"game_over": ["CanvasLayer", "res://scripts/game_over.gd"],
		"results_screen": ["CanvasLayer", "res://scripts/results_screen.gd"],
		"main_menu": ["Control", "res://scripts/main_menu.gd"],
		"credits": ["Control", "res://scripts/credits.gd"],
	}
	for scene_name in specs:
		var spec: Array = specs[scene_name]
		var root: Node = ClassDB.instantiate(spec[0])
		root.name = scene_name.to_pascal_case()
		root.set_script(load(spec[1]))
		_save(root, "res://scenes/%s.tscn" % scene_name)


func _scene_game() -> void:
	var root := Node.new()
	root.name = "Game"
	root.set_script(load("res://scripts/game.gd"))
	_save(root, "res://scenes/game.tscn")


# ================================================================== LEVEL 01
var _solid: Dictionary = {}
var _level: Node2D
var _decor_back: Node2D
var _decor_front: Node2D
var _ents: Node2D
var _plats: Node2D


const GROUND_SEGMENTS := [
	[0, 34, 19], [39, 43, 19], [44, 64, 17], [83, 110, 17], [115, 256, 19],
]
const THEME_SWITCH_COL := 111
const LEVEL_COLS := 257
const LEVEL_ROWS := 28


func _ground_row(col: int) -> int:
	for seg in GROUND_SEGMENTS:
		if col >= seg[0] and col <= seg[1]:
			return seg[2]
	return -1


func _theme_for(col: int) -> int:
	return 1 if col >= THEME_SWITCH_COL else 0


func _scene_level() -> void:
	var root := Node2D.new()
	root.name = "Level01"
	root.set_script(load("res://scripts/level_manager.gd"))
	_level = root
	root.level_pixel_size = Vector2i(LEVEL_COLS * T, LEVEL_ROWS * T)
	root.arena_left = 215.0 * T
	root.arena_right = 256.0 * T
	root.boss_spawn = Vector2(243 * T, 19 * T)

	_build_background(root)
	var mod := CanvasModulate.new()
	mod.color = Color(0.55, 0.57, 0.78)
	_add(root, mod, root, "Ambient")

	_decor_back = _add(root, Node2D.new(), root, "DecorBack") as Node2D
	_decor_back.z_index = -5
	var ground := TileMapLayer.new()
	ground.tile_set = load("res://assets/tiles/tileset.tres") as TileSet
	_add(root, ground, root, "Ground")
	_plats = _add(root, Node2D.new(), root, "Platforms") as Node2D
	_ents = _add(root, Node2D.new(), root, "Entities") as Node2D
	_decor_front = _add(root, Node2D.new(), root, "DecorFront") as Node2D
	_decor_front.z_index = 8

	_make_terrain(ground, root)
	_place_decor(root)
	_place_platforms(root)
	_place_pickups(root)
	_place_enemies(root)
	_place_hazards(root)
	_place_checkpoints(root)
	_place_gate(root)
	_place_arena(root)

	var start := Marker2D.new()
	start.position = Vector2(3 * T + 8, 19 * T)
	_add(root, start, root, "PlayerStart")
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	player.position = start.position
	_add(root, player, root, "Player")

	_save(root, "res://scenes/level_01.tscn")


func _build_background(root: Node2D) -> void:
	var pb := ParallaxBackground.new()
	_add(root, pb, root, "Parallax")
	var layers := [
		["sky", 0.0, 640, 0.0],
		["mountains_far", 0.04, 1280, 0.0],
		["mountains_near", 0.09, 1280, 0.0],
		["forest_mid", 0.2, 1280, 0.0],
		["trees_near", 0.38, 1280, 0.0],
		["fog", 0.55, 1280, 0.0],
	]
	for l in layers:
		var pl := ParallaxLayer.new()
		pl.motion_scale = Vector2(l[1], 0.0)
		if l[1] > 0.0:
			pl.motion_mirroring = Vector2(l[2], 0)
		_add(pb, pl, root, "L_" + l[0])
		var s := Sprite2D.new()
		s.texture = load("res://assets/backgrounds/%s.png" % l[0]) as Texture2D
		s.centered = false
		_add(pl, s, root, "Sprite")


func _make_terrain(ground: TileMapLayer, _root: Node2D) -> void:
	for seg in GROUND_SEGMENTS:
		for c in range(seg[0], seg[1] + 1):
			for r in range(seg[2], LEVEL_ROWS):
				_solid[Vector2i(c, r)] = true
	# boundary walls
	for r in range(0, 19):
		_solid[Vector2i(0, r)] = true
		_solid[Vector2i(256, r)] = true
	# pillars of ruin around the arena entrance
	for key in _solid.keys():
		var cell: Vector2i = key
		var left := _solid.has(cell + Vector2i(-1, 0))
		var right := _solid.has(cell + Vector2i(1, 0))
		var above := _solid.has(cell + Vector2i(0, -1))
		var below := _solid.has(cell + Vector2i(0, 1))
		var h := (cell.x * 7 + cell.y * 13) % 3
		var ax := 5 + h
		if not above:
			if not left and right:
				ax = 3
			elif not right and left:
				ax = 4
			else:
				ax = h
		else:
			if not left:
				ax = 8
			elif not right:
				ax = 9
			elif not below:
				ax = 10
		ground.set_cell(cell, 0, Vector2i(ax, _theme_for(cell.x)))


# ------------------------------------------------------------------ decor
func _tex_sprite(parent: Node2D, root: Node2D, tex_name: String, feet: Vector2, z: int = 0, tint: Color = Color.WHITE) -> Sprite2D:
	var s := Sprite2D.new()
	var tex := load("res://assets/sprites/decor/%s.png" % tex_name) as Texture2D
	s.texture = tex
	s.centered = false
	s.position = feet - Vector2(tex.get_width() * 0.5, tex.get_height())
	s.z_index = z
	s.modulate = tint
	_add(parent, s, root)
	return s


func _place_decor(root: Node2D) -> void:
	for c in range(1, 256):
		var gr := _ground_row(c)
		if gr < 0:
			continue
		var top_y := float(gr * T)
		var x := float(c * T + _rng.randi_range(2, 14))
		var th := _theme_for(c)
		var roll := _rng.randf()
		if th == 0:
			if roll < 0.35:
				_tex_sprite(_decor_back, root, ["grass_a", "grass_b", "grass_c"][_rng.randi() % 3], Vector2(x, top_y + 2), 1)
			elif roll < 0.44:
				_tex_sprite(_decor_back, root, "flower", Vector2(x, top_y + 2), 1)
			elif roll < 0.5:
				var m := _tex_sprite(_decor_back, root, "mush_s", Vector2(x, top_y + 2), 1)
				_add(_decor_back, _light(Color(0.2, 0.9, 0.8), 0.35, 0.6, m.position + Vector2(5, 4)), root)
			elif roll < 0.53:
				_tex_sprite(_decor_back, root, "fern", Vector2(x, top_y + 2), 1)
			elif roll < 0.56:
				_tex_sprite(_decor_back, root, "rock", Vector2(x, top_y + 2), 1)
		else:
			if roll < 0.22:
				_tex_sprite(_decor_back, root, ["grass_a", "grass_c"][_rng.randi() % 2], Vector2(x, top_y + 2), 1)
			elif roll < 0.30:
				var cr := _tex_sprite(_decor_back, root, "crystal", Vector2(x, top_y + 2), 1)
				_add(_decor_back, _light(Color(0.5, 0.97, 1.0), 0.55, 0.9, cr.position + Vector2(6, 8)), root)
			elif roll < 0.35:
				var m2 := _tex_sprite(_decor_back, root, "mush_l", Vector2(x, top_y + 2), 1)
				_add(_decor_back, _light(Color(0.88, 0.29, 0.82), 0.45, 0.9, m2.position + Vector2(9, 6)), root)
			elif roll < 0.38:
				_tex_sprite(_decor_back, root, "rock", Vector2(x, top_y + 2), 1)

	# large background trees (forest) and ruined pillars
	for c in range(6, 108, 9):
		var gr := _ground_row(c)
		if gr < 0:
			continue
		var tn := "tree_a" if (c / 9) % 2 == 0 else "tree_b"
		_tex_sprite(_decor_back, root, tn, Vector2(c * T + 8, gr * T + 4), -2, Color(0.72, 0.76, 0.95))
	for c in range(118, 205, 7):
		var gr2 := _ground_row(c)
		if gr2 < 0 or (c >= 147 and c <= 170):
			continue
		_tex_sprite(_decor_back, root, "pillar", Vector2(c * T + 8, gr2 * T + 2), -2, Color(0.8, 0.82, 1.0))
	for c in range(207, 256, 10):
		_tex_sprite(_decor_back, root, "pillar", Vector2(c * T + 8, 19 * T + 2), -2, Color(0.85, 0.75, 1.0))

	# lanterns (warm light) at key points
	for c in [8, 40, 72 + 0, 100, 118, 142, 174, 206]:
		var gr3 := _ground_row(c)
		if gr3 < 0:
			c += 2
			gr3 = _ground_row(c)
			if gr3 < 0:
				continue
		var lan := _tex_sprite(_decor_back, root, "lantern", Vector2(c * T + 8, gr3 * T + 2), 0)
		_add(_decor_back, _light(Color(1.0, 0.8, 0.45), 1.0, 3.0, lan.position + Vector2(7, 12)), root)

	# signs
	_tex_sprite(_decor_back, root, "sign", Vector2(5 * T + 8, 19 * T + 2), 0)
	_tex_sprite(_decor_back, root, "sign", Vector2(46 * T + 8, 17 * T + 2), 0)
	_tex_sprite(_decor_back, root, "sign", Vector2(204 * T + 8, 19 * T + 2), 0)

	# foreground bushes
	for c in range(10, 250, 13):
		var g4 := _ground_row(c)
		if g4 < 0 or _theme_for(c) == 1:
			continue
		_tex_sprite(_decor_front, root, "bush", Vector2(c * T + 8, g4 * T + 6), 0, Color(0.6, 0.65, 0.85))


# ------------------------------------------------------------------ platforms
func _plat(root: Node2D, col: float, row: float, w: int, travel: Vector2 = Vector2.ZERO, period: float = 4.0, phase: float = 0.0) -> void:
	var p := (load("res://scenes/moving_platform.tscn") as PackedScene).instantiate()
	p.position = Vector2(col * T, row * T)
	p.travel = travel
	p.period = period
	p.phase = phase
	p.width_tiles = w
	_add(_plats, p, root)


func _place_platforms(root: Node2D) -> void:
	# static one-way ledges
	_plat(root, 36, 16, 2)
	_plat(root, 46, 14, 3)
	_plat(root, 50, 11, 3)
	_plat(root, 103, 14, 3)
	_plat(root, 107, 11, 3)
	_plat(root, 147, 16, 3)
	_plat(root, 152, 14, 3)
	_plat(root, 157, 12, 3)
	_plat(root, 160, 9, 3)
	_plat(root, 164, 6, 3)
	_plat(root, 162, 14, 3)
	_plat(root, 167, 16, 3)
	_plat(root, 190, 15, 4)
	_plat(root, 222, 15, 3)
	_plat(root, 246, 15, 3)
	_plat(root, 234, 12, 4)
	# moving platforms over the long pit (cols 65-82)
	_plat(root, 65, 17, 3, Vector2(80, 0), 4.0, 0.0)
	_plat(root, 73, 15, 3, Vector2(0, 32), 3.0, 0.0)
	_plat(root, 79, 17, 3, Vector2(48, 0), 3.5, 0.25)
	# a vertical elevator in the ruins
	_plat(root, 126, 16, 3, Vector2(0, -48), 3.2, 0.0)


# ------------------------------------------------------------------ pickups
func _pickup(root: Node2D, kind: int, col: float, row: float) -> void:
	var p := (load("res://scenes/pickup.tscn") as PackedScene).instantiate()
	p.kind = kind
	p.position = Vector2(col * T + 8, row * T + 8)
	p.add_to_group("pickups", true)
	_add(_ents, p, root)


func _coins_line(root: Node2D, c0: float, c1: float, row: float, arc: float = 0.0) -> void:
	var n := int(c1 - c0) + 1
	for i in n:
		var t := float(i) / float(max(1, n - 1))
		_pickup(root, 0, c0 + i, row - arc * sin(t * PI))


func _place_pickups(root: Node2D) -> void:
	_coins_line(root, 12, 17, 17, 2.0)
	_coins_line(root, 20, 23, 17)
	_coins_line(root, 35, 38, 15, 2.0)
	_coins_line(root, 47, 49, 12)
	_coins_line(root, 40, 42, 17)
	_pickup(root, 1, 51, 9)  # Shadow Shard 1 (hidden up the stairs)
	_coins_line(root, 53, 58, 15, 1.5)
	_coins_line(root, 66, 71, 14, 2.0)
	_coins_line(root, 74, 77, 12)
	_coins_line(root, 80, 84, 14, 2.0)
	_coins_line(root, 86, 89, 15)
	_coins_line(root, 90, 93, 13, 2.0)
	_coins_line(root, 96, 99, 13, 2.0)
	_pickup(root, 2, 98, 15)
	_coins_line(root, 103, 105, 12)
	_pickup(root, 2, 104, 13)
	_pickup(root, 1, 108, 9)  # Shadow Shard 2
	_coins_line(root, 111, 114, 16, 2.0)
	_coins_line(root, 116, 121, 17)
	_coins_line(root, 126, 128, 12)
	_coins_line(root, 131, 135, 16, 1.5)
	_coins_line(root, 148, 150, 14)
	_coins_line(root, 153, 155, 12)
	_pickup(root, 2, 158, 10)
	_coins_line(root, 162, 164, 12)
	_coins_line(root, 167, 169, 14)
	_pickup(root, 1, 165, 4)  # Shadow Shard 3 (top of the climb)
	_coins_line(root, 161, 163, 7)
	_coins_line(root, 175, 181, 16, 2.0)
	_coins_line(root, 191, 194, 13)
	_coins_line(root, 196, 202, 16, 2.0)
	_pickup(root, 2, 210, 17)
	_coins_line(root, 222, 224, 13)
	_coins_line(root, 246, 248, 13)
	_coins_line(root, 234, 237, 10)


# ------------------------------------------------------------------ enemies
func _enemy(root: Node2D, kind: int, col: float, row: float, patrol: float = 56.0, on_ground: bool = true) -> void:
	var e := (load("res://scenes/enemy.tscn") as PackedScene).instantiate()
	e.kind = kind
	e.patrol_range = patrol
	var y := float(row * T)
	if on_ground:
		y = float(_ground_row(int(col)) * T)
	e.position = Vector2(col * T + 8, y)
	_add(_ents, e, root)


func _place_enemies(root: Node2D) -> void:
	_enemy(root, 0, 24, 0, 64)
	_enemy(root, 0, 47, 0, 40)
	_enemy(root, 0, 60, 0, 32)
	_enemy(root, 1, 72, 11, 80, false)
	_enemy(root, 1, 81, 10, 60, false)
	_enemy(root, 0, 88, 0, 40)
	_enemy(root, 2, 100, 0)
	_enemy(root, 0, 106, 0, 24)
	_enemy(root, 0, 120, 0, 56)
	_enemy(root, 1, 122, 12, 64, false)
	_enemy(root, 2, 124, 0)
	_enemy(root, 1, 130, 11, 64, false)
	_enemy(root, 0, 136, 0, 40)
	_enemy(root, 1, 155, 10, 72, false)
	_enemy(root, 1, 166, 12, 72, false)
	_enemy(root, 0, 178, 0, 64)
	_enemy(root, 2, 186, 0)
	_enemy(root, 0, 194, 0, 48)
	_enemy(root, 1, 198, 12, 64, false)
	_enemy(root, 0, 200, 0, 24)


# ------------------------------------------------------------------ hazards
func _spikes(root: Node2D, col: int) -> void:
	var h := (load("res://scenes/hazard.tscn") as PackedScene).instantiate()
	h.position = Vector2(col * T, _ground_row(col) * T)
	h.add_to_group("hazards", true)
	_add(_ents, h, root)


func _place_hazards(root: Node2D) -> void:
	for c in range(90, 94):
		_spikes(root, c)
	for c in range(97, 99):
		_spikes(root, c)
	for c in range(148, 170):
		_spikes(root, c)


# ------------------------------------------------------------------ checkpoints
func _place_checkpoints(root: Node2D) -> void:
	for col in [58, 109, 141, 172, 208]:
		var cp := (load("res://scenes/checkpoint.tscn") as PackedScene).instantiate()
		cp.position = Vector2(col * T + 8, _ground_row(col) * T)
		cp.add_to_group("checkpoints", true)
		_add(_ents, cp, root)


# ------------------------------------------------------------------ lever and gate
func _place_gate(root: Node2D) -> void:
	var sg := (load("res://scenes/switch_gate.tscn") as PackedScene).instantiate()
	sg.position = Vector2(133 * T + 8, 19 * T)
	sg.gate_offset = Vector2(7 * T, 0)
	sg.gate_pieces = 2
	sg.prompt_text = "[E] Pull lever"
	_add(_ents, sg, root)


# ------------------------------------------------------------------ boss arena
func _place_arena(root: Node2D) -> void:
	# trigger just inside the arena entrance
	var trig := Area2D.new()
	trig.set_script(load("res://scripts/trigger_zone.gd"))
	trig.position = Vector2(219 * T, 19 * T - 96)
	_add(root, trig, root, "BossTrigger")
	_add(trig, _rect(16, 400), root, "Shape")

	# crystal gate that seals the arena
	var gate := StaticBody2D.new()
	gate.collision_layer = 1
	gate.collision_mask = 0
	gate.position = Vector2(215 * T + 8, 19 * T)
	_add(root, gate, root, "ArenaGate")
	_add(gate, _rect(14, 200, Vector2(0, -100)), root, "Shape")
	var vis := Node2D.new()
	_add(gate, vis, root, "Visual")
	for i in 3:
		_add(vis, _anim("gate", "glow", Vector2(0, -32 - 64 * i)), root)
	_add(vis, _light(Color(0.88, 0.29, 0.82), 1.0, 3.5, Vector2(0, -80)), root)

	# portal (locked until the boss is defeated)
	var ex := (load("res://scenes/level_exit.tscn") as PackedScene).instantiate()
	ex.position = Vector2(251 * T, 19 * T)
	_add(root, ex, root, "Exit")
