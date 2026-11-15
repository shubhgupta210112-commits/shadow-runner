extends CanvasLayer
## Pause overlay: Resume / Restart / Settings / Main Menu. Escape toggles.

const UI := preload("res://scripts/ui_kit.gd")

signal resumed

var _panel: PanelContainer
var _settings: PanelContainer
var _first: Button
var _open: bool = false


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.06, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	_panel = UI.make_panel()
	_panel.custom_minimum_size = Vector2(180, 0)
	add_child(_panel)
	UI.center(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	_panel.add_child(v)
	v.add_child(UI.title_label("PAUSED", 12, UI.C_CYAN))
	_first = UI.button("RESUME", resume, 156.0)
	v.add_child(_first)
	v.add_child(UI.button("RESTART LEVEL", _on_restart, 156.0))
	v.add_child(UI.button("SETTINGS", _on_settings, 156.0))
	v.add_child(UI.button("MAIN MENU", _on_menu, 156.0))
	v.add_child(HSeparator.new())
	v.add_child(UI.credit_block(7))

	_settings = preload("res://scripts/settings_panel.gd").new()
	_settings.custom_minimum_size = Vector2(260, 0)
	_settings.visible = false
	_settings.closed.connect(func() -> void:
		_settings.visible = false
		_panel.visible = true
		_first.grab_focus())
	add_child(_settings)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if not _open:
			if get_tree().paused:
				return
			pause()
			get_viewport().set_input_as_handled()
		elif not _settings.visible:
			resume()
			get_viewport().set_input_as_handled()


func pause() -> void:
	_open = true
	visible = true
	_panel.visible = true
	_settings.visible = false
	get_tree().paused = true
	AudioManager.play_sfx(&"ui_pause")
	AudioManager.set_music_ducked(true)
	_first.grab_focus()


func resume() -> void:
	if not _open:
		return
	_open = false
	visible = false
	get_tree().paused = false
	AudioManager.play_sfx(&"ui_back")
	AudioManager.set_music_ducked(false)
	resumed.emit()


func _on_restart() -> void:
	_open = false
	AudioManager.set_music_ducked(false)
	GameManager.restart_level()


func _on_settings() -> void:
	_panel.visible = false
	_settings.visible = true


func _on_menu() -> void:
	_open = false
	AudioManager.set_music_ducked(false)
	GameManager.go_to_menu()
