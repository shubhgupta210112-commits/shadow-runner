extends CanvasLayer
## End-of-level results with animated tallies, rank, Restart / Main Menu.

const UI := preload("res://scripts/ui_kit.gd")

var _rows: VBoxContainer
var _rank: Label
var _first: Button
var _buttons: HBoxContainer


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.09, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var box := UI.make_panel()
	box.custom_minimum_size = Vector2(300, 0)
	add_child(box)
	UI.center(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	box.add_child(v)
	v.add_child(UI.title_label("LEVEL COMPLETE", 12, UI.C_GOLD))
	v.add_child(UI.label("The Whispering Grove is bright once more.", 7, UI.C_DIM, false, HORIZONTAL_ALIGNMENT_CENTER))
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 4)
	v.add_child(_rows)
	_rank = UI.title_label("", 28, UI.C_CYAN)
	_rank.modulate.a = 0.0
	v.add_child(_rank)
	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 8)
	_first = UI.button("PLAY AGAIN", func() -> void: GameManager.restart_level(), 120.0)
	_buttons.add_child(_first)
	_buttons.add_child(UI.button("CREDITS", func() -> void: GameManager.change_scene(GameManager.SCENE_CREDITS), 90.0))
	_buttons.add_child(UI.button("MAIN MENU", func() -> void: GameManager.go_to_menu(), 100.0))
	_buttons.modulate.a = 0.0
	v.add_child(_buttons)


func show_screen() -> void:
	visible = true
	AudioManager.play_music(&"menu", 1.0)
	var gm := GameManager
	var lines: Array = [
		["Coins", "%d / %d" % [gm.coins, gm.total_coins]],
		["Shadow Shards", "%d / %d" % [gm.shards, gm.total_shards]],
		["Enemies defeated", str(gm.enemies_defeated)],
		["Time", gm.format_time(gm.elapsed)],
		["Time bonus", "+%d" % gm.time_bonus],
		["Deaths", "%d  (-%d)" % [gm.deaths, gm.death_penalty]],
		["FINAL SCORE", str(gm.final_score)],
	]
	if gm.final_score >= gm.best_score:
		lines.append(["NEW BEST!", ""])
	var tw := create_tween()
	for line in lines:
		tw.tween_callback(_add_row.bind(line[0], line[1]))
		tw.tween_interval(0.35)
	tw.tween_callback(func() -> void:
		_rank.text = "RANK  " + gm.get_rank()
		AudioManager.play_sfx(&"victory", -4.0)
		var t2 := create_tween().set_parallel(true)
		t2.tween_property(_rank, "modulate:a", 1.0, 0.4)
		t2.tween_property(_buttons, "modulate:a", 1.0, 0.4)
		_first.grab_focus())


func _add_row(name_text: String, value_text: String) -> void:
	var h := HBoxContainer.new()
	var big := name_text == "FINAL SCORE" or name_text == "NEW BEST!"
	var l := UI.label(name_text, 8, UI.C_GOLD if big else UI.C_TEXT, big)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	h.add_child(UI.label(value_text, 8, UI.C_CYAN if big else UI.C_TEXT, big, HORIZONTAL_ALIGNMENT_RIGHT))
	_rows.add_child(h)
	AudioManager.play_sfx(&"coin", -8.0, 0.8 + 0.06 * _rows.get_child_count())
