extends Control
## Main menu: Play / Settings / About / Exit, with credit line.

const UI := preload("res://scripts/ui_kit.gd")

var _buttons: VBoxContainer
var _settings: PanelContainer
var _about_panel: PanelContainer
var _first: Button
var _main_ui: Array[Control] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size = Vector2(640, 360)
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -1
	add_child(bg_layer)
	bg_layer.add_child(preload("res://scripts/menu_background.gd").new())
	_build_menu()
	_build_settings()
	_build_about()
	AudioManager.play_music(&"menu")
	var amb: Array[StringName] = [&"night"]
	AudioManager.play_ambient(amb)
	UI.fade_in(self, 0.6)


func _build_menu() -> void:
	var logo := TextureRect.new()
	logo.texture = load("res://assets/menus/logo.png") as Texture2D
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo.custom_minimum_size = Vector2(500, 120)
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	logo.position = Vector2(320 - 250, 10)
	logo.size = Vector2(500, 120)
	logo.scale = Vector2(1.0, 1.0)
	add_child(logo)
	_main_ui.append(logo)
	var tw := logo.create_tween().set_loops()
	tw.tween_property(logo, "position:y", 14.0, 1.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(logo, "position:y", 8.0, 1.6).set_trans(Tween.TRANS_SINE)

	var sub := UI.label("CHAPTER 1  -  THE WHISPERING GROVE", 8, UI.C_GOLD, false, HORIZONTAL_ALIGNMENT_CENTER)
	sub.position = Vector2(0, 128)
	sub.size = Vector2(640, 12)
	add_child(sub)
	_main_ui.append(sub)

	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 4)
	_buttons.position = Vector2(320 - 70, 148)
	add_child(_buttons)
	_first = UI.button("PLAY", _on_play)
	_buttons.add_child(_first)
	_buttons.add_child(UI.button("SETTINGS", _on_settings))
	_buttons.add_child(UI.button("ABOUT", _on_about))
	_buttons.add_child(UI.button("EXIT", _on_exit))
	_first.grab_focus.call_deferred()

	var credit := UI.credit_block(8)
	credit.position = Vector2(0, 326)
	credit.size = Vector2(640, 26)
	add_child(credit)
	_main_ui.append(credit)

	if GameManager.best_score > 0:
		var best := UI.label("BEST  %d   TIME  %s" % [GameManager.best_score, GameManager.format_time(GameManager.best_time)], 7, UI.C_DIM, false, HORIZONTAL_ALIGNMENT_CENTER)
		best.position = Vector2(0, 8)
		best.size = Vector2(630, 10)
		best.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		add_child(best)
		_main_ui.append(best)

	var hint := UI.label("A/D or Arrows: Move   Space: Jump   F: Shadow Bolt   E: Interact   Esc: Pause", 7, UI.C_DIM, false, HORIZONTAL_ALIGNMENT_CENTER)
	hint.position = Vector2(0, 304)
	hint.size = Vector2(640, 10)
	add_child(hint)
	_main_ui.append(hint)


func _build_settings() -> void:
	_settings = preload("res://scripts/settings_panel.gd").new()
	_settings.custom_minimum_size = Vector2(260, 0)
	_settings.visible = false
	_settings.closed.connect(_close_panels)
	add_child(_settings)


func _build_about() -> void:
	_about_panel = UI.make_panel()
	_about_panel.custom_minimum_size = Vector2(380, 0)
	_about_panel.visible = false
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	_about_panel.add_child(v)
	v.add_child(UI.title_label("ABOUT", 10, UI.C_CYAN))
	var txt := UI.label("You are the SHADOW RUNNER, last of the lantern-bearers.\nThe Whispering Grove has gone dark. Run, leap and cast\nShadow Bolts through its ruins, collect Shadow Shards,\nand face the spectral stag GLOOMHORN to bring the light back.", 7, UI.C_TEXT, false, HORIZONTAL_ALIGNMENT_CENTER)
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.custom_minimum_size = Vector2(356, 0)
	v.add_child(txt)
	v.add_child(HSeparator.new())
	v.add_child(UI.label("CONTROLS", 8, UI.C_GOLD, true, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.label("A / D or Arrow keys ... Move\nSpace / W / Up ... Jump (hold to jump higher)\nF or J ... Shadow Bolt     E ... Interact\nDown + Jump ... Drop through platforms\nEscape ... Pause", 7, UI.C_TEXT, false, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(HSeparator.new())
	v.add_child(UI.credit_block(8))
	v.add_child(UI.label("Fonts: Press Start 2P and Silkscreen (SIL Open Font License)", 6, UI.C_DIM, false, HORIZONTAL_ALIGNMENT_CENTER))
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	var back := UI.button("BACK", _close_panels, 100.0)
	hb.add_child(back)
	v.add_child(hb)
	_about_panel.visibility_changed.connect(func() -> void:
		if _about_panel.visible:
			back.grab_focus())
	add_child(_about_panel)
	UI.center(_about_panel)


func _show_only(panel: Control) -> void:
	_buttons.visible = false
	for c in _main_ui:
		c.visible = false
	_settings.visible = panel == _settings
	_about_panel.visible = panel == _about_panel


func _close_panels() -> void:
	_settings.visible = false
	_about_panel.visible = false
	_buttons.visible = true
	for c in _main_ui:
		c.visible = true
	_first.grab_focus()


func _on_play() -> void:
	GameManager.start_game()


func _on_settings() -> void:
	_show_only(_settings)


func _on_about() -> void:
	_show_only(_about_panel)


func _on_exit() -> void:
	GameManager.quit_game()


func _unhandled_input(event: InputEvent) -> void:
	if _about_panel != null and _about_panel.visible and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		AudioManager.play_sfx(&"ui_back")
		_close_panels()
