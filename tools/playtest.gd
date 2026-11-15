extends Node
## Automated play-through used for QA. Run under a display:
##   xvfb-run -a godot --path . res://tools/playtest.tscn
## Writes screenshots to /tmp/shots and prints PASS/FAIL checks.

var game: Node
var level: Node2D
var player: CharacterBody2D
var fails: int = 0
var shots_dir := "/tmp/shots"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(shots_dir)
	_run.call_deferred()


func check(cond: bool, msg: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + msg)
	if not cond:
		fails += 1


func shot(n: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [shots_dir, n])


func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func hold(action: String, on: bool) -> void:
	if on:
		Input.action_press(action)
	else:
		Input.action_release(action)


func tap(action: String, t: float = 0.1) -> void:
	Input.action_press(action)
	await wait(t)
	Input.action_release(action)


func _run() -> void:
	# ---- menu
	var menu := (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
	add_child(menu)
	await wait(1.2)
	await shot("01_menu")
	menu.queue_free()
	await wait(0.2)

	# ---- game
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await wait(1.0)
	level = game.level
	player = level.player
	check(player != null, "player spawned")
	check(GameManager.total_coins > 40, "coins counted: %d" % GameManager.total_coins)
	check(GameManager.total_shards == 3, "3 shadow shards")
	await shot("02_start")

	# movement: run right + jump
	hold("move_right", true)
	await wait(1.5)
	check(player.global_position.x > 150.0, "runs right (x=%d)" % player.global_position.x)
	await tap("jump", 0.25)
	await wait(0.15)
	check(not player.is_on_floor(), "jump leaves floor")
	await wait(0.8)
	await shot("03_running")
	hold("move_right", false)

	# shoot
	await tap("shoot", 0.05)
	await wait(0.1)
	var bolts := 0
	for c in level.get_children():
		if c is Area2D and c.get("style") == &"bolt":
			bolts += 1
	check(bolts >= 1, "shadow bolt fires")

	# coin pickup by teleporting onto one
	var coin_before: int = GameManager.coins
	for p in get_tree().get_nodes_in_group("pickups"):
		if int(p.get("kind")) == 0:
			player.teleport(p.global_position + Vector2(0, 8))
			break
	await wait(0.3)
	check(GameManager.coins > coin_before, "coin collected")

	# enemy: stomp the first mossling
	var enemy: Node2D
	for e in get_tree().get_nodes_in_group("enemies"):
		if int(e.get("kind")) == 0:
			enemy = e
			break
	player.teleport(Vector2(enemy.global_position.x, enemy.global_position.y - 70))
	var kills_before: int = GameManager.enemies_defeated
	await wait(1.4)
	check(GameManager.enemies_defeated > kills_before or not is_instance_valid(enemy) or enemy.hp < 2, "stomp damages mossling")
	await shot("04_enemy")

	# bolt knockback: spawn bolt at an enemy
	var e2: Node2D
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and int(e.get("kind")) == 0 and e != enemy and not e._dead:
			e2 = e
			break
	if e2:
		var x0 := e2.global_position.x
		var hp0: int = e2.hp
		e2.take_hit(1, player)
		check(e2.hp == hp0 - 1 or e2._dead, "bolt hit reduces hp")
		await wait(0.2)
		check(e2._stun > 0.0 or e2._dead, "enemy is knocked back (stunned)")
		check(absf(e2.global_position.x - x0) > 1.0 or e2._dead, "enemy displaced by knockback")

	# hazards + damage + invulnerability
	player.teleport(Vector2(90 * 16 + 8, 17 * 16 - 20))
	await wait(1.0)
	check(player.health < player.max_health, "spikes damage player (hp=%d)" % player.health)
	await shot("05_spikes")

	# checkpoint
	var cp_node: Node = get_tree().get_nodes_in_group("checkpoints")[0]
	player.teleport(cp_node.global_position + Vector2(0, -4))
	await wait(0.4)
	check(cp_node.active, "checkpoint activates")

	# pit fall -> respawn at checkpoint
	player.invulnerable_override = true
	var hp_before: int = player.health
	player.teleport(Vector2(70 * 16, 480))
	await wait(1.2)
	check(player.global_position.y < 400.0, "pit fall respawns at checkpoint")
	check(player.health == hp_before - 1, "pit costs one heart")
	player.invulnerable_override = false

	# lever + gate
	var sg: Node = null
	for n in level.get_node("Entities").get_children():
		if n.has_method("_on_interacted"):
			sg = n
	player.teleport(sg.global_position + Vector2(0, -2))
	await wait(0.3)
	await shot("06_lever")
	await tap("interact", 0.1)
	await wait(1.5)
	check(sg.is_open, "lever opens gate")

	# death + game over flow
	var lives_before: int = GameManager.lives
	player._invuln = 0.0
	player.invulnerable_override = false
	player.take_damage(99, 0.0)
	await wait(2.0)
	check(GameManager.lives == lives_before - 1, "death costs a life (lives=%d)" % GameManager.lives)
	check(player.health == player.max_health, "respawn restores health")

	# ---- boss fight
	player.teleport(Vector2(219 * 16 + 8, 19 * 16 - 4))
	await wait(2.4)
	var boss: Node = level.boss
	check(level.boss_active, "boss arena sealed")
	check(boss.state != boss.State.DORMANT, "boss awakened")
	await shot("07_boss_start")
	player.invulnerable_override = true
	var seen_phases := {}
	var t := 0.0
	var snapped := false
	while is_instance_valid(boss) and boss.state != boss.State.DEAD and t < 90.0:
		seen_phases[boss.phase] = true
		boss.take_hit(1, player)
		if boss.phase == 2 and not snapped:
			snapped = true
			await shot("08_boss_phase2")
		await wait(0.45)
		t += 0.45
		# keep the player alive and out of the way
		player.global_position = Vector2(boss.arena_left + 60, 19 * 16 - 2) if is_instance_valid(boss) else player.global_position
	check(seen_phases.has(1) and seen_phases.has(2) and seen_phases.has(3), "boss went through 3 phases: %s" % str(seen_phases.keys()))
	await wait(3.5)
	check(level.boss_dead, "boss defeated")
	check(level.exit_portal.unlocked, "portal unlocked")
	await shot("09_boss_dead")

	# ---- finish
	player.teleport(level.exit_portal.global_position + Vector2(0, -4))
	await wait(4.5)
	check(game.results.visible, "results screen shown")
	await wait(3.5)
	await shot("10_results")
	print("final score: ", GameManager.final_score, " rank ", GameManager.get_rank())
	print("TOTAL FAILS: ", fails)
	get_tree().quit(fails)
