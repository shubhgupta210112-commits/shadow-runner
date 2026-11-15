extends Control
## Reusable settings dialog (menu + pause). Emits `closed` when the player presses Back.

signal closed


func _ready() -> void:
    theme = Game.ui_theme
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP

    var dim := ColorRect.new()
    dim.color = Color(0.0, 0.0, 0.05, 0.6)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(dim)

    var center := CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(center)

    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(640, 0)
    center.add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 36)
    margin.add_theme_constant_override("margin_right", 36)
    margin.add_theme_constant_override("margin_top", 28)
    margin.add_theme_constant_override("margin_bottom", 28)
    panel.add_child(margin)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 16)
    margin.add_child(box)

    var title := Game.make_label("SETTINGS", 54, Color(0.5, 0.95, 1.0))
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(title)

    box.add_child(_slider_row("MUSIC", Game.music_volume, _on_music))
    box.add_child(_slider_row("SOUND FX", Game.sfx_volume, _on_sfx))

    var shake := CheckButton.new()
    shake.text = "SCREEN SHAKE"
    shake.button_pressed = Game.screen_shake
    shake.toggled.connect(_on_shake)
    box.add_child(shake)

    var touch := CheckButton.new()
    touch.text = "TOUCH CONTROLS (next restart)"
    touch.button_pressed = Game.touch_controls
    touch.toggled.connect(_on_touch)
    box.add_child(touch)

    var back := Game.make_button("BACK", Vector2(300, 64))
    back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    back.pressed.connect(_on_back)
    box.add_child(back)
    back.grab_focus()


func _slider_row(text: String, value: float, on_change: Callable) -> Control:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 20)
    var lab := Game.make_label(text, 32)
    lab.custom_minimum_size = Vector2(190, 0)
    row.add_child(lab)
    var s := HSlider.new()
    s.min_value = 0.0
    s.max_value = 1.0
    s.step = 0.05
    s.value = value
    s.custom_minimum_size = Vector2(330, 48)
    s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    s.value_changed.connect(on_change)
    row.add_child(s)
    return row


func _on_back() -> void:
    Game.save_settings()
    closed.emit()
    queue_free()


func _on_music(v: float) -> void:
    Game.music_volume = v
    Game.apply_volumes()


func _on_sfx(v: float) -> void:
    Game.sfx_volume = v
    Game.sfx("ui_click")


func _on_shake(on: bool) -> void:
    Game.screen_shake = on


func _on_touch(on: bool) -> void:
    Game.touch_controls = on
