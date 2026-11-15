extends CanvasLayer
## In-game HUD: hearts, lives, coins, shards, score, timer, interact prompt,
## toast messages and the boss health bar. Built entirely in code.

const UI := preload("res://scripts/ui_kit.gd")
const HEART_FULL := preload("res://assets/hud/heart_full.png")
const HEART_EMPTY := preload("res://assets/hud/heart_empty.png")
const COIN_ICON := preload("res://assets/hud/coin_icon.png")
const SHARD_ICON := preload("res://assets/hud/shard_icon.png")

var _hearts: HBoxContainer
var _heart_rects: Array[TextureRect] = []
var _lives: Label
var _coins: Label
var _shards: Label
var _score: Label
var _time: Label
var _prompt: Label
var _toast: Label
var _toast_tween: Tween
var _boss_box: VBoxContainer
var _boss_bar: ProgressBar
var _boss_fill: StyleBoxFlat
var _boss_name: Label
var _shown_score: float = 0.0
var _target_score: int = 0
var _max_health: int = 5


func _ready() -> void:
	layer = 20
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", UI.panel_style(Color(0.04, 0.03, 0.1, 0.65), Color(0.3, 0.26, 0.55, 0.7), 1))
	top.position = Vector2(6, 6)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	top.add_child(v)
	_hearts = HBoxContainer.new()
	_hearts.add_theme_constant_override("separation", 1)
	v.add_child(_hearts)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 8)
	v.add_child(stats)
	stats.add_child(_icon(COIN_ICON))
	_coins = UI.label("0/0", 8, UI.C_GOLD, true)
	stats.add_child(_coins)
	stats.add_child(_icon(SHARD_ICON))
	_shards = UI.label("0/0", 8, UI.C_CYAN, true)
	stats.add_child(_shards)
	_lives = UI.label("x3", 8, UI.C_EMBER, true)
	stats.add_child(_lives)

	var right := VBoxContainer.new()
	right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right.position = Vector2(640 - 130, 8)
	right.custom_minimum_size = Vector2(122, 0)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(right)
	_score = UI.label("SCORE 000000", 8, UI.C_TEXT, true, HORIZONTAL_ALIGNMENT_RIGHT)
	right.add_child(_score)
	_time = UI.label("00:00", 8, UI.C_DIM, false, HORIZONTAL_ALIGNMENT_RIGHT)
	right.add_child(_time)

	_prompt = UI.label("", 8, UI.C_TEXT, true, HORIZONTAL_ALIGNMENT_CENTER)
	_prompt.position = Vector2(0, 250)
	_prompt.size = Vector2(640, 12)
	root.add_child(_prompt)

	_toast = UI.label("", 8, UI.C_GOLD, true, HORIZONTAL_ALIGNMENT_CENTER)
	_toast.position = Vector2(0, 60)
	_toast.size = Vector2(640, 12)
	_toast.modulate.a = 0.0
	root.add_child(_toast)

	_boss_box = VBoxContainer.new()
	_boss_box.position = Vector2(320 - 140, 322)
	_boss_box.custom_minimum_size = Vector2(280, 0)
	_boss_box.visible = false
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_boss_box)
	_boss_name = UI.label("GLOOMHORN", 8, UI.C_EMBER, true, HORIZONTAL_ALIGNMENT_CENTER)
	_boss_box.add_child(_boss_name)
	_boss_bar = ProgressBar.new()
	_boss_bar.custom_minimum_size = Vector2(280, 9)
	_boss_bar.show_percentage = false
	_boss_bar.max_value = 1.0
	_boss_bar.value = 1.0
	var bg := UI.panel_style(Color(0.08, 0.04, 0.12), Color(0.6, 0.25, 0.65), 2)
	bg.content_margin_top = 0
	bg.content_margin_bottom = 0
	_boss_fill = UI.panel_style(Color(0.88, 0.29, 0.82), Color(0.88, 0.29, 0.82), 0)
	_boss_fill.content_margin_top = 0
	_boss_fill.content_margin_bottom = 0
	_boss_bar.add_theme_stylebox_override("background", bg)
	_boss_bar.add_theme_stylebox_override("fill", _boss_fill)
	_boss_box.add_child(_boss_bar)

	GameManager.score_changed.connect(func(s: int) -> void: _target_score = s)
	GameManager.coins_changed.connect(func(c: int, t: int) -> void: _coins.text = "%d/%d" % [c, t])
	GameManager.shards_changed.connect(func(c: int, t: int) -> void: _shards.text = "%d/%d" % [c, t])
	GameManager.lives_changed.connect(func(l: int) -> void: _lives.text = "x%d" % l)
	_target_score = GameManager.score
	_coins.text = "%d/%d" % [GameManager.coins, GameManager.total_coins]
	_shards.text = "%d/%d" % [GameManager.shards, GameManager.total_shards]
	_lives.text = "x%d" % GameManager.lives
	set_health(_max_health, _max_health)


func _icon(tex: Texture2D) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.custom_minimum_size = Vector2(12, 12)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return t


func _process(delta: float) -> void:
	_shown_score = move_toward(_shown_score, float(_target_score), maxf(120.0, absf(_target_score - _shown_score) * 6.0) * delta)
	_score.text = "SCORE %06d" % int(_shown_score)
	_time.text = GameManager.format_time(GameManager.elapsed)


func set_health(current: int, maximum: int) -> void:
	_max_health = maximum
	while _heart_rects.size() < maximum:
		var r := TextureRect.new()
		r.custom_minimum_size = Vector2(16, 16)
		r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_hearts.add_child(r)
		_heart_rects.append(r)
	for i in _heart_rects.size():
		var full := i < current
		var r := _heart_rects[i]
		var was_full := r.texture == HEART_FULL
		r.texture = HEART_FULL if full else HEART_EMPTY
		if was_full and not full:
			r.pivot_offset = Vector2(8, 8)
			var tw := r.create_tween()
			tw.tween_property(r, "scale", Vector2(1.5, 1.5), 0.06)
			tw.tween_property(r, "scale", Vector2.ONE, 0.12)


func set_prompt(text: String) -> void:
	_prompt.text = text


func show_toast(text: String) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 0.0
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.15)
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.5)


func show_boss(boss: Node) -> void:
	_boss_box.visible = true
	_boss_bar.value = 1.0
	_boss_box.modulate.a = 0.0
	_boss_box.create_tween().tween_property(_boss_box, "modulate:a", 1.0, 0.5)
	if not boss.health_changed.is_connected(_on_boss_health):
		boss.health_changed.connect(_on_boss_health)
	if not boss.phase_changed.is_connected(_on_boss_phase):
		boss.phase_changed.connect(_on_boss_phase)


func hide_boss() -> void:
	_boss_box.visible = false


func _on_boss_health(current: int, maximum: int) -> void:
	var tw := create_tween()
	tw.tween_property(_boss_bar, "value", float(current) / float(maximum), 0.2)


func _on_boss_phase(phase: int) -> void:
	_boss_name.text = "GLOOMHORN  -  PHASE %d" % phase
	_boss_fill.bg_color = [Color(0.88, 0.29, 0.82), Color(1.0, 0.55, 0.35), Color(1.0, 0.3, 0.25)][clampi(phase - 1, 0, 2)]
