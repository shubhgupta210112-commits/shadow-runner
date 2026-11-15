extends Node
## Game scene root: loads the level, wires player and level signals into the
## HUD, pause menu, game-over and results screens.

const LEVEL_SCENE := preload("res://scenes/level_01.tscn")
const HUD_SCENE := preload("res://scenes/hud.tscn")
const PAUSE_SCENE := preload("res://scenes/pause_menu.tscn")
const GAME_OVER_SCENE := preload("res://scenes/game_over.tscn")
const RESULTS_SCENE := preload("res://scenes/results_screen.tscn")

var level: Node2D
var hud: CanvasLayer
var pause_menu: CanvasLayer
var game_over: CanvasLayer
var results: CanvasLayer


func _ready() -> void:
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	pause_menu = PAUSE_SCENE.instantiate()
	add_child(pause_menu)
	game_over = GAME_OVER_SCENE.instantiate()
	add_child(game_over)
	results = RESULTS_SCENE.instantiate()
	add_child(results)

	level = LEVEL_SCENE.instantiate()
	level.player_ready.connect(_on_player_ready)
	level.boss_fight_started.connect(hud.show_boss)
	level.boss_fight_ended.connect(hud.hide_boss)
	level.toast.connect(hud.show_toast)
	level.game_over.connect(game_over.show_screen)
	level.level_completed.connect(_on_level_completed)
	add_child(level)


func _on_player_ready(player: Node) -> void:
	hud._max_health = player.max_health
	hud.set_health(player.health, player.max_health)
	player.health_changed.connect(hud.set_health)
	player.prompt_changed.connect(hud.set_prompt)


func _on_level_completed() -> void:
	AudioManager.play_sfx(&"victory")
	await get_tree().create_timer(0.8).timeout
	results.show_screen()
