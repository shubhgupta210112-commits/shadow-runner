extends Node
## Screenshots the menu panels, pause screen, game over and credits.

func shot(n: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/shots/%s.png" % n)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/shots")
	_run.call_deferred()


func _run() -> void:
	var menu := (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
	add_child(menu)
	await get_tree().create_timer(1.0).timeout
	await shot("u1_menu")
	menu._on_settings()
	await get_tree().create_timer(0.3).timeout
	await shot("u2_settings")
	menu._close_panels()
	menu._on_about()
	await get_tree().create_timer(0.3).timeout
	await shot("u3_about")
	menu.queue_free()
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await get_tree().create_timer(1.0).timeout
	game.pause_menu.pause()
	await get_tree().create_timer(0.3).timeout
	await shot("u4_pause")
	game.pause_menu.resume()
	game.game_over.show_screen()
	await get_tree().create_timer(0.8).timeout
	await shot("u5_gameover")
	game.queue_free()
	var cr := (load("res://scenes/credits.tscn") as PackedScene).instantiate()
	add_child(cr)
	await get_tree().create_timer(6.0).timeout
	await shot("u6_credits")
	get_tree().quit()
