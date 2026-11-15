extends CanvasLayer
## Game-over overlay: Retry / Main Menu.

const UI := preload("res://scripts/ui_kit.gd")

var _first: Button


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.02, 0.05, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var box := UI.make_panel()
	box.custom_minimum_size = Vector2(240, 0)
	add_child(box)
	UI.center(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	box.add_child(v)
	v.add_child(UI.title_label("GAME OVER", 14, UI.C_EMBER))
	v.add_child(UI.label("The Grove keeps its shadows...", 7, UI.C_DIM, false, HORIZONTAL_ALIGNMENT_CENTER))
	var stats := UI.label("", 8, UI.C_TEXT, false, HORIZONTAL_ALIGNMENT_CENTER)
	stats.name = "Stats"
	v.add_child(stats)
	_first = UI.button("TRY AGAIN", func() -> void: GameManager.restart_level(), 200.0)
	v.add_child(_first)
	v.add_child(UI.button("MAIN MENU", func() -> void: GameManager.go_to_menu(), 200.0))


func show_screen() -> void:
	var stats: Label = find_child("Stats", true, false)
	stats.text = "Score %d   Coins %d   Time %s" % [GameManager.score, GameManager.coins, GameManager.format_time(GameManager.elapsed)]
	visible = true
	UI.fade_in(get_child(0), 0.6)
	_first.grab_focus()
