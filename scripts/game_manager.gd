extends Node
## Global game state (autoload "GameManager"): run statistics, settings,
## persistence and scene transitions with a fade.

signal score_changed(score: int)
signal coins_changed(coins: int, total: int)
signal shards_changed(shards: int, total: int)
signal lives_changed(lives: int)
signal settings_changed

const SETTINGS_PATH := "user://shadow_runner_settings.cfg"
const SAVE_PATH := "user://shadow_runner_save.cfg"

const SCENE_MENU := "res://scenes/main_menu.tscn"
const SCENE_GAME := "res://scenes/game.tscn"
const SCENE_CREDITS := "res://scenes/credits.tscn"

const CREDIT_LINE_1 := "Developed by Shubh Gupta"
const CREDIT_LINE_2 := "Contact: shubhgupta210112@gmail.com"

# ---- settings
var music_volume: float = 0.8
var sfx_volume: float = 0.9
var ambient_volume: float = 0.7
var fullscreen: bool = false
var screen_shake: bool = true

# ---- run stats
var score: int = 0
var coins: int = 0
var total_coins: int = 0
var shards: int = 0
var total_shards: int = 0
var enemies_defeated: int = 0
var deaths: int = 0
var lives: int = 3
const START_LIVES := 3
var elapsed: float = 0.0
var timer_running: bool = false
var boss_defeated: bool = false
var final_score: int = 0
var time_bonus: int = 0
var death_penalty: int = 0

# ---- persistent records
var best_score: int = 0
var best_time: float = 0.0
var runs_completed: int = 0

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _changing: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_settings()
	_load_save()
	_build_fade()
	apply_display_settings()


func _process(delta: float) -> void:
	if timer_running and not get_tree().paused:
		elapsed += delta


func _build_fade() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.04, 0.035, 0.1, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_layer.add_child(_fade_rect)


# ------------------------------------------------------------------ run state
func start_new_run(coin_total: int, shard_total: int) -> void:
	score = 0
	coins = 0
	shards = 0
	total_coins = coin_total
	total_shards = shard_total
	enemies_defeated = 0
	deaths = 0
	lives = START_LIVES
	elapsed = 0.0
	boss_defeated = false
	final_score = 0
	time_bonus = 0
	death_penalty = 0
	timer_running = true
	score_changed.emit(score)
	coins_changed.emit(coins, total_coins)
	shards_changed.emit(shards, total_shards)
	lives_changed.emit(lives)


func set_totals(coin_total: int, shard_total: int) -> void:
	total_coins = coin_total
	total_shards = shard_total
	coins_changed.emit(coins, total_coins)
	shards_changed.emit(shards, total_shards)


func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)


func add_coin(value: int = 10) -> void:
	coins += 1
	add_score(value)
	coins_changed.emit(coins, total_coins)


func add_shard(value: int = 500) -> void:
	shards += 1
	add_score(value)
	shards_changed.emit(shards, total_shards)


func register_enemy_defeated(points: int) -> void:
	enemies_defeated += 1
	add_score(points)


func register_death() -> void:
	deaths += 1
	lives = maxi(0, lives - 1)
	lives_changed.emit(lives)


func finish_level() -> void:
	timer_running = false
	boss_defeated = true
	time_bonus = int(max(0.0, 300.0 - elapsed) * 5.0)
	death_penalty = deaths * 150
	final_score = max(0, score + time_bonus - death_penalty)
	if final_score > best_score:
		best_score = final_score
	if best_time <= 0.0 or elapsed < best_time:
		best_time = elapsed
	runs_completed += 1
	_save_save()


func get_rank() -> String:
	if final_score >= 5000:
		return "S"
	if final_score >= 4000:
		return "A"
	if final_score >= 3000:
		return "B"
	return "C"


func format_time(t: float) -> String:
	var total := int(t)
	return "%02d:%02d" % [total / 60, total % 60]


# ------------------------------------------------------------------ scenes
func change_scene(path: String, fade_time: float = 0.35) -> void:
	if _changing:
		return
	_changing = true
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 1.0, fade_time)
	await tw.finished
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(_fade_rect, "color:a", 0.0, fade_time)
	await tw2.finished
	_changing = false


func go_to_menu() -> void:
	timer_running = false
	change_scene(SCENE_MENU)


func start_game() -> void:
	change_scene(SCENE_GAME)


func restart_level() -> void:
	change_scene(SCENE_GAME)


func quit_game() -> void:
	get_tree().quit()


# ------------------------------------------------------------------ settings
func apply_display_settings() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	settings_changed.emit()


func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	settings_changed.emit()


func set_ambient_volume(v: float) -> void:
	ambient_volume = clampf(v, 0.0, 1.0)
	settings_changed.emit()


func set_fullscreen(on: bool) -> void:
	fullscreen = on
	apply_display_settings()
	settings_changed.emit()


func set_screen_shake(on: bool) -> void:
	screen_shake = on
	settings_changed.emit()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("audio", "ambient", ambient_volume)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("gameplay", "screen_shake", screen_shake)
	cfg.save(SETTINGS_PATH)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	music_volume = float(cfg.get_value("audio", "music", music_volume))
	sfx_volume = float(cfg.get_value("audio", "sfx", sfx_volume))
	ambient_volume = float(cfg.get_value("audio", "ambient", ambient_volume))
	fullscreen = bool(cfg.get_value("display", "fullscreen", fullscreen))
	screen_shake = bool(cfg.get_value("gameplay", "screen_shake", screen_shake))


func _save_save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("records", "best_score", best_score)
	cfg.set_value("records", "best_time", best_time)
	cfg.set_value("records", "runs_completed", runs_completed)
	cfg.save(SAVE_PATH)


func _load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	best_score = int(cfg.get_value("records", "best_score", 0))
	best_time = float(cfg.get_value("records", "best_time", 0.0))
	runs_completed = int(cfg.get_value("records", "runs_completed", 0))
