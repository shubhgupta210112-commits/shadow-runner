extends Node2D
## Chapter 1 - THE FALLEN CITY
const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const BossScript = preload("res://scripts/boss.gd")
const HazardScript = preload("res://scripts/hazard.gd")
const MovingPlatformScript = preload("res://scripts/moving_platform.gd")
const PickupScript = preload("res://scripts/pickup.gd")
const CheckpointScript = preload("res://scripts/checkpoint.gd")
const HudScript = preload("res://scripts/hud.gd")
const TouchScript = preload("res://scripts/touch_controls.gd")
const Fx = preload("res://scripts/fx.gd")

const GROUND_Y: float = 560.0
const WORLD_W: float = 7680.0
const ARENA_L: float = 6400.0
const ARENA_R: float = 7680.0
const ENV: String = "res://assets/environments/"
const BG: String = "res://assets/backgrounds/"

const GROUND: Array = [
	[0.0, 1500.0], [1700.0, 2900.0],
	[3200.0, 4300.0], [4700.0, 5700.0],
	[5900.0, 7680.0]
]

const PLATFORMS: Array = [
	[1100.0, 440.0], [1290.0, 335.0],
	[2300.0, 430.0], [2500.0, 335.0],
	[3650.0, 440.0], [3850.0, 350.0],
	[4050.0, 440.0], [5200.0, 430.0],
	[5450.0, 340.0], [6050.0, 440.0],
	[6220.0, 335.0]
]

const MOVERS: Array = [
	[3060.0, 560.0, 0.0, -125.0, 1.3],
	[4380.0, 560.0, 240.0, 0.0, 1.1]
]

const SPIKES: Array = [
	[1240.0, 128.0], [2650.0, 128.0],
	[3400.0, 128.0], [4880.0, 128.0]
]

const SAWS: Array = [
	[2250.0, 2450.0, 520.0],
	[5150.0, 5450.0, 520.0]
]

const ENEMIES: Array = [
	["crawler", 950.0, 560.0, 760.0, 1150.0],
	["crawler", 2000.0, 560.0, 1800.0, 2250.0],
	["drone", 2250.0, 400.0, 2100.0, 2500.0],
	["crawler", 2830.0, 560.0, 2790.0, 2890.0],
	["brute", 3850.0, 560.0, 3600.0, 4150.0],
	["crawler", 3300.0, 560.0, 3250.0, 3390.0],
	["crawler", 5100.0, 560.0, 4900.0, 5350.0],
	["drone", 5300.0, 380.0, 5100.0, 5500.0],
	["brute", 6180.0, 560.0, 6000.0, 6330.0],
	["drone", 6000.0, 400.0, 5900.0, 6200.0]
]

const CRYSTAL_LINES: Array = [
	[380.0, 620.0, 500.0, 5],
	[1750.0, 1900.0, 500.0, 4],
	[2300.0, 2500.0, 280.0, 3],
	[3320.0, 3480.0, 500.0, 3],
	[3650.0, 4050.0, 300.0, 5],
	[4420.0, 4620.0, 470.0, 3],
	[4800.0, 5000.0, 500.0, 3],
	[5760.0, 5840.0, 430.0, 3],
	[6600.0, 6900.0, 500.0, 4]
]

const GOLD: Array = [
	[1290.0, 292.0],
	[5450.0, 296.0],
	[6220.0, 292.0]
]

const HEARTS: Array = [
	[2800.0, 505.0], [4200.0, 505.0],
	[5600.0, 505.0], [6360.0, 505.0]
]

const CHECKPOINTS: Array = [
	1420.0, 3260.0, 4740.0, 5960.0, 6340.0
]

const LAMPS: Array = [
	350.0, 1000.0, 1750.0, 2400.0,
	3300.0, 4000.0, 4800.0, 5350.0, 6000.0
]

const PILLARS: Array = [
	[700.0, -1], [1600.0, -1],
	[2900.0, -1], [4500.0, -1],
	[5800.0, -1], [6460.0, 1], [7600.0, 1]
]

const CRATES: Array = [
	820.0, 1850.0, 2200.0, 3400.0, 5600.0
]

var world: Node2D
var player: Node
var hud: Node
var boss: Node

var _bg: Array = []
var _fog_back: Sprite2D
var _fog_front: Sprite2D
var _lamp_lights: Array = []

var _time: float = 0.0
var _boss_started: bool = false
var _boss_done: bool = false
var _finished: bool = false

var _crystal_total: int = 0
var _snap_score: int = 0
var _snap_crystals: int = 0
var _snap_hidden: int = 0

var _last_cp: Vector2 = Vector2.ZERO
var _portal: Area2D
var _phase2_hearts: bool = false


func _ready() -> void:
	Game.play_music("music_level")
	Game.play_ambience("ambience")

	_snap_score = Game.score
	_snap_crystals = Game.crystals
	_snap_hidden = Game.hidden_found
	_last_cp = Game.checkpoint_pos

	var modulate_node: CanvasModulate = CanvasModulate.new()
	modulate_node.color = Color(0.74, 0.76, 0.94)
	add_child(modulate_node)

	_build_backgrounds()

	world = Node2D.new()
	world.name = "World"
	add_child(world)

	_build_ground()
	_build_platforms()
	_build_decor()
	_build_hazards()
	_build_collectibles()
	_build_checkpoints()
	_build_enemies()
	_spawn_player()
	_build_boss()
	_build_hud()

	if Game.touch_controls:
		add_child(TouchScript.new())

	_build_front_fog()

	if Game.checkpoint_pos.x < 300.0 and not bool(Game.get_meta("intro_seen", false)):
		Game.set_meta("intro_seen", true)
		_intro_cinematic()


# BACKGROUNDS

func _make_bg(
	tex_path: String,
	factor: float,
	alpha: float,
	layer_index: int,
	y_off: float = 0.0
) -> void:
	var canvas_layer: CanvasLayer = CanvasLayer.new()
	canvas_layer.layer = layer_index
	add_child(canvas_layer)

	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = load(tex_path) as Texture2D
	sprite.centered = false
	sprite.region_enabled = true
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.modulate = Color(1, 1, 1, alpha)
	sprite.position = Vector2(0, y_off)

	canvas_layer.add_child(sprite)
	_bg.append([sprite, factor, y_off])


func _build_backgrounds() -> void:
	_make_bg(BG + "bg_sky.png", 0.02, 1.0, -20)
	_make_bg(BG + "bg_far.png", 0.08, 1.0, -19)
	_make_bg(BG + "bg_mid.png", 0.2, 1.0, -18)
	_make_bg(BG + "bg_near.png", 0.42, 1.0, -17)

	var fog_layer: CanvasLayer = CanvasLayer.new()
	fog_layer.layer = -16
	add_child(fog_layer)

	_fog_back = Sprite2D.new()
	_fog_back.texture = load(BG + "fog.png") as Texture2D
	_fog_back.centered = false
	_fog_back.region_enabled = true
	_fog_back.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_fog_back.modulate = Color(1, 1, 1, 0.8)

	fog_layer.add_child(_fog_back)


func _build_front_fog() -> void:
	var fog_layer: CanvasLayer = CanvasLayer.new()
	fog_layer.layer = 3
	add_child(fog_layer)

	_fog_front = Sprite2D.new()
	_fog_front.texture = load(BG + "fog.png") as Texture2D
	_fog_front.centered = false
	_fog_front.region_enabled = true
	_fog_front.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_fog_front.modulate = Color(0.9, 0.8, 1.0, 0.45)

	fog_layer.add_child(_fog_front)


func _update_backgrounds() -> void:
	if not is_instance_valid(player):
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var scale_factor: float = viewport_size.y / 720.0

	var cam_x: float = float(player.global_position.x)

	var camera_value: Variant = player.get("camera")
	if camera_value is Camera2D:
		var camera: Camera2D = camera_value as Camera2D
		cam_x = camera.get_screen_center_position().x

	for entry in _bg:
		var sprite: Sprite2D = entry[0] as Sprite2D
		var factor: float = float(entry[1])

		sprite.scale = Vector2(scale_factor, scale_factor)
		sprite.region_rect = Rect2(
			cam_x * factor,
			0.0,
			viewport_size.x / scale_factor + 2.0,
			720.0
		)

	var fog_height: float = 360.0

	if is_instance_valid(_fog_back):
		_fog_back.scale = Vector2(scale_factor, scale_factor)
		_fog_back.position = Vector2(
			0,
			viewport_size.y - fog_height * scale_factor
		)
		_fog_back.region_rect = Rect2(
			cam_x * 0.55 + _time * 22.0,
			0.0,
			viewport_size.x / scale_factor + 2.0,
			fog_height
		)

	if is_instance_valid(_fog_front):
		_fog_front.scale = Vector2(scale_factor * 1.1, scale_factor * 1.1)
		_fog_front.position = Vector2(
			0,
			viewport_size.y - fog_height * scale_factor * 1.1
		)
		_fog_front.region_rect = Rect2(
			cam_x * 1.3 - _time * 40.0,
			0.0,
			viewport_size.x / (scale_factor * 1.1) + 2.0,
			fog_height
		)


# TERRAIN

func _build_ground() -> void:
	var top_texture: Texture2D = load(ENV + "ground_top.png") as Texture2D
	var body_texture: Texture2D = load(ENV + "ground_body.png") as Texture2D
	for segment in GROUND:
		var x0: float = float(segment[0])
		var x1: float = float(segment[1])
		var width: float = x1 - x0

		var static_body: StaticBody2D = StaticBody2D.new()
		static_body.collision_layer = 1
		static_body.collision_mask = 0
		static_body.position = Vector2(x0, GROUND_Y)

		var collision: CollisionShape2D = CollisionShape2D.new()
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = Vector2(width, 400.0)
		collision.shape = shape
		collision.position = Vector2(width * 0.5, 200.0)

		static_body.add_child(collision)
		world.add_child(static_body)

		var body_sprite: Sprite2D = Sprite2D.new()
		body_sprite.texture = body_texture
		body_sprite.centered = false
		body_sprite.region_enabled = true
		body_sprite.region_rect = Rect2(0, 0, width, 300)
		body_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		body_sprite.position = Vector2(x0, GROUND_Y + 46.0)
		body_sprite.z_index = 0
		world.add_child(body_sprite)

		var top_sprite: Sprite2D = Sprite2D.new()
		top_sprite.texture = top_texture
		top_sprite.centered = false
		top_sprite.region_enabled = true
		top_sprite.region_rect = Rect2(0, 0, width, 48)
		top_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		top_sprite.position = Vector2(x0, GROUND_Y)
		top_sprite.z_index = 1
		world.add_child(top_sprite)


func _build_platforms() -> void:
	var texture: Texture2D = load(ENV + "plat_float.png") as Texture2D

	for platform in PLATFORMS:
		var center_x: float = float(platform[0])
		var top_y: float = float(platform[1])

		var static_body: StaticBody2D = StaticBody2D.new()
		static_body.collision_layer = 1
		static_body.collision_mask = 0
		static_body.position = Vector2(center_x, top_y)

		var collision: CollisionShape2D = CollisionShape2D.new()
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = Vector2(118, 22)
		collision.shape = shape
		collision.position = Vector2(0, 11)
		collision.one_way_collision = true

		static_body.add_child(collision)

		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = texture
		sprite.position = Vector2(0, 22)
		static_body.add_child(sprite)

		static_body.z_index = 2
		world.add_child(static_body)

	for mover in MOVERS:
		var moving_platform: Node2D = MovingPlatformScript.new()
		moving_platform.position = Vector2(
			float(mover[0]),
			float(mover[1])
		)
		moving_platform.set("travel", Vector2(
			float(mover[2]),
			float(mover[3])
		))
		moving_platform.set("rate", float(mover[4]))
		world.add_child(moving_platform)


func _add_sprite(
	path: String,
	pos: Vector2,
	z: int,
	scale_value: float = 1.0,
	tint: Color = Color(1, 1, 1, 1)
) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = load(path) as Texture2D
	sprite.position = pos
	sprite.z_index = z
	sprite.scale = Vector2(scale_value, scale_value)
	sprite.modulate = tint
	world.add_child(sprite)
	return sprite


func _is_ground_x(x: float) -> bool:
	for segment in GROUND:
		if x > float(segment[0]) + 40.0 and x < float(segment[1]) - 40.0:
			return true
	return false


func _build_decor() -> void:
	for pillar in PILLARS:
		var pillar_x: float = float(pillar[0])

		if _is_ground_x(pillar_x):
			_add_sprite(
				ENV + "pillar.png",
				Vector2(pillar_x, GROUND_Y - 150.0 + 6.0),
				-1,
				1.0,
				Color(0.8, 0.8, 0.95)
			)

	for crate_x in CRATES:
		if _is_ground_x(float(crate_x)):
			_add_sprite(
				ENV + "crate.png",
				Vector2(float(crate_x), GROUND_Y - 50.0),
				1
			)

	for lamp_x in LAMPS:
		var x: float = float(lamp_x)

		if not _is_ground_x(x):
			continue

		_add_sprite(
			ENV + "lamp.png",
			Vector2(x, GROUND_Y - 115.0),
			1
		)

		var light: PointLight2D = PointLight2D.new()
		light.texture = load("res://assets/effects/light.png") as Texture2D
		light.color = Color(1.0, 0.8, 0.45)
		light.energy = 1.0
		light.texture_scale = 2.6
		light.position = Vector2(x + 18.0, GROUND_Y - 195.0)

		world.add_child(light)
		_lamp_lights.append(light)

	for arena_x in [ARENA_L + 200.0, ARENA_R - 200.0]:
		var arena_light: PointLight2D = PointLight2D.new()
		arena_light.texture = load("res://assets/effects/light.png") as Texture2D
		arena_light.color = Color(0.85, 0.35, 1.0)
		arena_light.energy = 0.9
		arena_light.texture_scale = 4.0
		arena_light.position = Vector2(
			float(arena_x),
			GROUND_Y - 120.0
		)
		world.add_child(arena_light)


# HAZARDS

func _build_hazards() -> void:
	for spike in SPIKES:
		if float(spike[1]) <= 0.0:
			continue

		var hazard: Node = HazardScript.new()
		hazard.set("kind", "spikes")
		hazard.set("width", float(spike[1]))
		hazard.position = Vector2(float(spike[0]), GROUND_Y)
		world.add_child(hazard)

	for saw in SAWS:
		var saw_hazard: Node = HazardScript.new()
		saw_hazard.set("kind", "saw")
		saw_hazard.set("x_a", float(saw[0]))
		saw_hazard.set("x_b", float(saw[1]))
		saw_hazard.position = Vector2(
			float(saw[0]),
			float(saw[2])
		)
		world.add_child(saw_hazard)


# COLLECTIBLES

func _after_cp(x: float) -> bool:
	return x >= Game.checkpoint_pos.x - 40.0


func _add_pickup(kind: String, pos: Vector2) -> void:
	var pickup: Node = PickupScript.new()
	pickup.set("kind", kind)
	pickup.position = pos
	world.add_child(pickup)


func _build_collectibles() -> void:
	_crystal_total = 0

	for line in CRYSTAL_LINES:
		var x0: float = float(line[0])
		var x1: float = float(line[1])
		var y: float = float(line[2])
		var count: int = int(line[3])

		for i in range(count):
			var t: float = 0.0

			if count > 1:
				t = float(i) / float(count - 1)

			var x: float = lerpf(x0, x1, t)
			_crystal_total += 1

			if _after_cp(x):
				_add_pickup("crystal", Vector2(x, y))

	for gold in GOLD:
		_crystal_total += 5

		if _after_cp(float(gold[0])):
			_add_pickup(
				"gold",
				Vector2(float(gold[0]), float(gold[1]))
			)

	for heart in HEARTS:
		if _after_cp(float(heart[0])):
			_add_pickup(
				"heart",
				Vector2(float(heart[0]), float(heart[1]))
			)

	for enemy in ENEMIES:
		match String(enemy[0]):
			"crawler":
				_crystal_total += 2
			"drone":
				_crystal_total += 3
			"brute":
				_crystal_total += 5


# CHECKPOINTS

func _build_checkpoints() -> void:
	for checkpoint_x in CHECKPOINTS:
		if float(checkpoint_x) < Game.checkpoint_pos.x - 5.0:
			continue

		var checkpoint: Node = CheckpointScript.new()
		checkpoint.position = Vector2(float(checkpoint_x), GROUND_Y)
		world.add_child(checkpoint)


# ENEMIES

func _build_enemies() -> void:
	for enemy_data in ENEMIES:
		var enemy_x: float = float(enemy_data[1])

		if not _after_cp(enemy_x):
			continue

		var enemy: Node = EnemyScript.new()
		enemy.set("kind", String(enemy_data[0]))
		enemy.position = Vector2(
			enemy_x,
			float(enemy_data[2])
		)
		enemy.set("patrol_a", float(enemy_data[3]))
		enemy.set("patrol_b", float(enemy_data[4]))

		world.add_child(enemy)


# PLAYER

func _spawn_player() -> void:
	player = PlayerScript.new()
	player.position = Game.checkpoint_pos
	world.add_child(player)

	player.died.connect(_on_player_died)

	var emb: Node2D = Fx.embers(player, Vector2(900, 320), 34)
	emb.position = Vector2(0, -230)


# BOSS

func _build_boss() -> void:
	boss = BossScript.new()
	boss.set("arena_l", ARENA_L)
	boss.set("arena_r", ARENA_R)
	boss.set("ground_y", GROUND_Y)

	world.add_child(boss)

	boss.intro_started.connect(_on_boss_intro_started)
	boss.intro_finished.connect(_on_boss_intro_finished)
	boss.defeated.connect(_on_boss_defeated)
	boss.health_changed.connect(_on_boss_health)


# HUD

func _build_hud() -> void:
	hud = HudScript.new()
	hud.set("crystal_total", _crystal_total)

	add_child(hud)

	hud.bind_player(player)
	hud.bind_boss(boss)
	hud.retry_requested.connect(_on_retry)


# FRAME UPDATE

func _process(delta: float) -> void:
	_time += delta
	_update_backgrounds()

	for i in range(_lamp_lights.size()):
		var lamp: PointLight2D = _lamp_lights[i]

		if is_instance_valid(lamp):
			lamp.energy = (
				0.95
				+ 0.1 * sin(_time * 7.0 + float(i) * 1.7)
				+ 0.04 * sin(_time * 19.0 + float(i))
			)

	if Game.checkpoint_pos != _last_cp:
		_last_cp = Game.checkpoint_pos
		_snap_score = Game.score
		_snap_crystals = Game.crystals
		_snap_hidden = Game.hidden_found

	if (
		not _boss_started
		and not _finished
		and is_instance_valid(player)
		and not bool(player.get("dead"))
	):
		if (
			player.global_position.x > ARENA_L + 150.0
			and player.global_position.y < 700.0
		):
			_start_boss()


# INTRO CINEMATIC

func _intro_cinematic() -> void:
	player.set("frozen", true)

	var camera: Camera2D = player.get("camera") as Camera2D

	if is_instance_valid(camera):
		camera.position_smoothing_enabled = false

	player.set("cinematic_offset", Vector2(1300.0, -160.0))

	hud.cinematic_bars(true, 0.6)
	hud.show_title_card("CHAPTER 1", "THE FALLEN CITY", 2.0)

	Game.sfx("boss_warn", -10.0, 0.6)

	var tween: Tween = create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(
		player,
		"cinematic_offset",
		Vector2.ZERO,
		2.6
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	if is_instance_valid(camera):
		camera.position_smoothing_enabled = true

	hud.cinematic_bars(false, 0.6)
	player.set("frozen", false)

	if Game.touch_controls:
		hud.show_toast("USE THE ARROWS, JUMP AND ATTACK BUTTONS")
	else:
		hud.show_toast("A / D MOVE     SPACE JUMP     E ATTACK")


# BOSS ENCOUNTER

func _start_boss() -> void:
	_boss_started = true
	player.set("frozen", true)

	var camera: Camera2D = player.get("camera") as Camera2D

	if is_instance_valid(camera):
		camera.limit_left = int(ARENA_L)
		camera.limit_right = int(ARENA_R)

	_add_wall(ARENA_L - 24.0)
	_add_wall(ARENA_R + 24.0)

	Game.stop_music()
	Game.stop_ambience()

	boss.start_fight()


func _add_wall(x: float) -> void:
	var static_body: StaticBody2D = StaticBody2D.new()
	static_body.collision_layer = 1
	static_body.collision_mask = 0

	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()

	shape.size = Vector2(48, 1600)
	collision.shape = shape

	static_body.add_child(collision)
	static_body.position = Vector2(x, 0)

	world.add_child(static_body)


func _on_boss_intro_started() -> void:
	hud.cinematic_bars(true, 0.6)
	hud.show_banner("VOID GUARDIAN", 1.6)


func _on_boss_intro_finished() -> void:
	hud.cinematic_bars(false, 0.6)
	hud.show_boss_bar(true)

	player.set("frozen", false)

	Game.play_music("music_boss")
	hud.show_toast("STRIKE WHEN IT GLOWS!")


func _on_boss_health(cur: int, mx: int) -> void:
	if cur <= mx / 2 and not _phase2_hearts:
		_phase2_hearts = true

		_add_pickup(
			"heart",
			Vector2(ARENA_L + 180.0, 505.0)
		)

		_add_pickup(
			"heart",
			Vector2(ARENA_R - 180.0, 505.0)
		)


func _on_boss_defeated() -> void:
	_boss_done = true

	hud.show_boss_bar(false)
	Game.sfx("checkpoint")
	Game.play_music("music_menu")

	_open_portal()
	hud.show_toast("THE VOID RECEDES - ENTER THE PORTAL")


# PORTAL

func _open_portal() -> void:
	_portal = Area2D.new()
	_portal.collision_layer = 0
	_portal.collision_mask = 2
	_portal.position = Vector2(ARENA_R - 260.0, GROUND_Y)

	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()

	shape.size = Vector2(110, 230)
	collision.shape = shape
	collision.position = Vector2(0, -115)

	_portal.add_child(collision)

	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = load(ENV + "portal.png") as Texture2D
	sprite.position = Vector2(0, -135)
	sprite.scale = Vector2(0.1, 0.1)

	var material: CanvasItemMaterial = CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sprite.material = material

	_portal.add_child(sprite)

	var light: PointLight2D = PointLight2D.new()
	light.texture = load("res://assets/effects/light.png") as Texture2D
	light.color = Color(0.8, 0.5, 1.0)
	light.energy = 1.6
	light.texture_scale = 4.0
	light.position = Vector2(0, -135)

	_portal.add_child(light)

	_portal.z_index = 3
	world.add_child(_portal)

	var tween: Tween = create_tween()
	tween.tween_property(
		sprite,
		"scale",
		Vector2(0.9, 0.9),
		1.4
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var spin: Tween = create_tween()
	spin.set_loops()
	spin.tween_property(sprite, "rotation", TAU, 6.0).from(0.0)

	_portal.body_entered.connect(_on_portal_body)


func _on_portal_body(body: Node2D) -> void:
	if _finished or not body.is_in_group("player"):
		return

	_complete()


# ENDING

func _complete() -> void:
	_finished = true

	player.celebrate()

	Game.stop_music()
	Game.sfx("victory")

	hud.cinematic_bars(true, 0.8)
	hud.show_banner("CHAPTER COMPLETE", 2.0)

	Game.fade_flash(Color(0.9, 0.7, 1.0), 0.8)

	Fx.burst(
		world,
		player.global_position + Vector2(0, -80),
		Color(1.0, 0.8, 1.0),
		40,
		420.0,
		1.2,
		12.0,
		120.0
	)

	await get_tree().create_timer(3.2).timeout

	var hp: int = int(player.get("health"))
	Game.add_score(hp * 20)

	var seconds: int = int(_time)
	var ratio: float = float(Game.crystals) / float(maxi(_crystal_total, 1))

	var rank: String = "C"

	if ratio >= 0.9 and Game.hidden_found >= 3:
		rank = "S"
	elif ratio >= 0.7:
		rank = "A"
	elif ratio >= 0.4:
		rank = "B"

	var stats: Dictionary = {
		"score": Game.score,
		"crystals": Game.crystals,
		"crystal_total": _crystal_total,
		"hidden": Game.hidden_found,
		"time": "%d:%02d" % [seconds / 60, seconds % 60],
		"rank": rank
	}

	hud.show_victory(stats)


# DEFEAT / RETRY

func _on_player_died() -> void:
	if _finished:
		return

	Game.stop_music()
	Game.sfx("defeat")

	await get_tree().create_timer(0.5).timeout

	hud.show_defeat()


func _on_retry() -> void:
	Game.score = _snap_score
	Game.crystals = _snap_crystals
	Game.hidden_found = _snap_hidden

	Game.goto_scene(Game.LEVEL_SCENE)
