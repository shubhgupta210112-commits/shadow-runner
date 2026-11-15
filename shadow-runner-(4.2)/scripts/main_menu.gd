extends Control
## Main menu: animated parallax city, floating logo, hero + Void Guardian showcase, credits.

const SpriteUtil = preload("res://scripts/sprite_util.gd")
const SettingsPanel = preload("res://scripts/settings_panel.gd")
const Fx = preload("res://scripts/fx.gd")
const BG := "res://assets/backgrounds/"

var _layers: Array = []
var _t: float = 0.0
var _logo: TextureRect
var _buttons: VBoxContainer
var _credits: Label
var _hero: AnimatedSprite2D
var _boss: AnimatedSprite2D
var _stage: Node2D
var _about: Control
var _busy: bool = false
var _attack_timer: float = 4.0


func _ready() -> void:
	theme = Game.ui_theme
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Game.play_music("music_menu")
	Game.stop_ambience()
	Game.new_game()

	# animated background: slowly drifting parallax layers
	var specs := [["bg_sky.png", 4.0, 1.0], ["bg_far.png", 9.0, 1.0], ["bg_mid.png", 18.0, 1.0], ["bg_near.png", 34.0, 1.0], ["fog.png", 55.0, 0.9]]
	for sp in specs:
		var s := Sprite2D.new()
		s.texture = load(BG + String(sp[0]))
		s.centered = false
		s.region_enabled = true
		s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		s.modulate = Color(1, 1, 1, float(sp[2]))
		add_child(s)
		_layers.append([s, float(sp[1]), String(sp[0]) == "fog.png"])

	_stage = Node2D.new()
	add_child(_stage)

	_boss = AnimatedSprite2D.new()
	_boss.sprite_frames = SpriteUtil.make_frames("res://assets/enemies/guardian_sheet.png", 320, 320,
		[["idle", 6, 8.0, true]])
	_boss.modulate = Color(0.75, 0.55, 1.0, 0.55)
	_boss.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_boss.play("idle")
	_stage.add_child(_boss)

	_hero = AnimatedSprite2D.new()
	_hero.sprite_frames = SpriteUtil.make_frames("res://assets/characters/hero_sheet.png", 192, 192,
		[["idle", 8, 10.0, true], ["attack", 6, 14.0, false]])
	_hero.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_hero.play("idle")
	_stage.add_child(_hero)

	var embers := Fx.embers(_stage, Vector2(700, 120), 40)
	embers.name = "Embers"

	var vig := TextureRect.new()
	vig.texture = load("res://assets/ui/vignette.png")
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vig.stretch_mode = TextureRect.STRETCH_SCALE
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vig)

	_logo = TextureRect.new()
	_logo.texture = load("res://assets/ui/logo.png")
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.custom_minimum_size = Vector2(620, 236)
	_logo.size = Vector2(620, 236)
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_logo)

	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 14)
	add_child(_buttons)
	var play := Game.make_button("PLAY", Vector2(380, 70))
	play.pressed.connect(_on_play)
	_buttons.add_child(play)
	var settings := Game.make_button("SETTINGS", Vector2(380, 62))
	settings.pressed.connect(_on_settings)
	_buttons.add_child(settings)
	var about := Game.make_button("ABOUT", Vector2(380, 62))
	about.pressed.connect(_on_about)
	_buttons.add_child(about)
	if not OS.has_feature("web"):
		var quit := Game.make_button("EXIT", Vector2(380, 62))
		quit.pressed.connect(_on_exit)
		_buttons.add_child(quit)
	play.grab_focus()

	_credits = Game.make_label("SHADOW RUNNER   |   Developed by %s   |   %s" % [Game.DEV_NAME, Game.DEV_EMAIL], 24, Color(0.8, 0.88, 1.0, 0.9))
	add_child(_credits)

	get_viewport().size_changed.connect(_layout)
	_layout()

	# fade-in
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.8)


func _layout() -> void:
	var vs: Vector2 = get_viewport().get_visible_rect().size
	var sc := vs.y / 720.0
	for e in _layers:
		var sp: Sprite2D = e[0]
		sp.scale = Vector2(sc, sc)
	var logo_w := minf(620.0, vs.x * 0.5)
	_logo.size = Vector2(logo_w, logo_w * 0.38)
	_logo.position = Vector2(vs.x * 0.04, vs.y * 0.05)
	_buttons.position = Vector2(vs.x * 0.07, vs.y * 0.37)
	_credits.position = Vector2(vs.x * 0.04, vs.y - 48.0)
	_stage.position = Vector2.ZERO
	_boss.position = Vector2(vs.x * 0.80, vs.y * 0.40)
	_boss.scale = Vector2(sc * 1.5, sc * 1.5)
	_hero.position = Vector2(vs.x * 0.62, vs.y * 0.70)
	_hero.scale = Vector2(sc * 1.7, sc * 1.7)
	var emb := _stage.get_node_or_null("Embers")
	if emb:
		emb.position = Vector2(vs.x * 0.5, vs.y * 0.75)


func _process(delta: float) -> void:
	_t += delta
	var vs: Vector2 = get_viewport().get_visible_rect().size
	var sc := vs.y / 720.0
	for e in _layers:
		var sp: Sprite2D = e[0]
		var speed: float = e[1]
		sp.region_rect = Rect2(_t * speed, 0.0, vs.x / sc + 2.0, 720.0 if not bool(e[2]) else 360.0)
		if bool(e[2]):
			sp.position = Vector2(0, vs.y - 360.0 * sc)
	_logo.position.y = vs.y * 0.05 + sin(_t * 1.4) * 8.0
	_boss.position.y = vs.y * 0.40 + sin(_t * 0.9) * 14.0
	_boss.modulate.a = 0.5 + 0.1 * sin(_t * 1.1)
	if _hero.animation == "attack" and not _hero.is_playing():
		_hero.play("idle")
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = 7.0
		if _hero.animation == "idle":
			_hero.play("attack")
			Game.sfx("sword", -8.0)


func _on_play() -> void:
	if _busy:
		return
	_busy = true
	Game.new_game()
	Game.sfx("victory", -8.0, 1.4)
	Game.goto_scene(Game.LEVEL_SCENE)


func _on_settings() -> void:
	var sp := Control.new()
	sp.set_script(SettingsPanel)
	add_child(sp)


func _on_exit() -> void:
	Game.save_settings()
	get_tree().quit()


func _on_about() -> void:
	if _about and is_instance_valid(_about):
		return
	_about = Control.new()
	_about.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_about)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.06, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_about.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_about.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 0)
	center.add_child(panel)
	var m := MarginContainer.new()
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 40)
	for side in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 26)
	panel.add_child(m)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	m.add_child(box)

	var t := Game.make_label("ABOUT", 56, Color(0.5, 0.95, 1.0))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var lines := [
		["SHADOW RUNNER", 40, Color(1, 0.9, 0.6)],
		["Chapter 1: THE FALLEN CITY", 30, Color(0.85, 0.9, 1)],
		["KAI runs the ruins of a city swallowed by the void. Collect crystals, slash through", 26, Color(0.9, 0.93, 1)],
		["the creatures of the dark and face the VOID GUARDIAN.", 26, Color(0.9, 0.93, 1)],
		["", 14, Color.WHITE],
		["PC:  A / D or arrows = move    SPACE = jump    E = attack    ESC = pause", 26, Color(0.7, 0.95, 1)],
		["Touch:  left thumb arrows, right thumb jump + attack", 26, Color(0.7, 0.95, 1)],
		["", 14, Color.WHITE],
		["Developed by %s" % Game.DEV_NAME, 34, Color(1, 0.8, 0.5)],
		["Contact: %s" % Game.DEV_EMAIL, 28, Color(1, 0.8, 0.5)],
		["All art and audio original, generated for this project. Font: Big Shoulders (OFL).", 22, Color(0.7, 0.75, 0.9)],
	]
	for ln in lines:
		var l := Game.make_label(String(ln[0]), int(ln[1]), ln[2])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(820, 0)
		box.add_child(l)
	var back := Game.make_button("BACK", Vector2(300, 64))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_on_about_back)
	box.add_child(back)
	back.grab_focus()


func _on_about_back() -> void:
	if _about and is_instance_valid(_about):
		_about.queue_free()
