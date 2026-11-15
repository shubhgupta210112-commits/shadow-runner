extends PanelContainer
## Reusable settings + about panel (used by main menu and pause menu).

const UI := preload("res://scripts/ui_kit.gd")

signal closed

var show_about: bool = false


func _ready() -> void:
	add_theme_stylebox_override("panel", UI.panel_style())
	UI.center(self)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 7)
	add_child(root)
	root.add_child(UI.title_label("SETTINGS", 10, UI.C_CYAN))
	root.add_child(_row("Music", UI.slider(GameManager.music_volume, GameManager.set_music_volume)))
	root.add_child(_row("Effects", UI.slider(GameManager.sfx_volume, GameManager.set_sfx_volume)))
	root.add_child(_row("Ambience", UI.slider(GameManager.ambient_volume, GameManager.set_ambient_volume)))
	var fs := UI.checkbox("Fullscreen", GameManager.fullscreen, GameManager.set_fullscreen)
	root.add_child(fs)
	root.add_child(UI.checkbox("Screen shake", GameManager.screen_shake, GameManager.set_screen_shake))
	root.add_child(HSeparator.new())
	root.add_child(UI.label("ABOUT", 8, UI.C_GOLD, true, HORIZONTAL_ALIGNMENT_CENTER))
	var about := UI.label("SHADOW RUNNER - Chapter 1: The Whispering Grove\nA pixel-art arcade platformer made in Godot 4.\nAll art and audio generated for this project.", 7, UI.C_DIM, false, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(about)
	root.add_child(UI.credit_block(8))
	var back := UI.button("BACK", _on_back, 100.0)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_child(back)
	root.add_child(hb)
	visibility_changed.connect(func() -> void:
		if visible:
			back.grab_focus())
	back.grab_focus.call_deferred()


func _row(text: String, control: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var l := UI.label(text, 8, UI.C_TEXT)
	l.custom_minimum_size = Vector2(70, 0)
	h.add_child(l)
	h.add_child(control)
	return h


func _on_back() -> void:
	GameManager.save_settings()
	AudioManager.play_sfx(&"ui_back")
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		_on_back()
