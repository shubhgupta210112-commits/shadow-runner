extends RefCounted
## Shared helpers for building polished pixel-style UI in code.

const FONT_BODY := preload("res://assets/fonts/Silkscreen-Regular.ttf")
const FONT_BOLD := preload("res://assets/fonts/Silkscreen-Bold.ttf")
const FONT_TITLE := preload("res://assets/fonts/PressStart2P-Regular.ttf")

const C_BG := Color(0.043, 0.039, 0.102)
const C_PANEL := Color(0.085, 0.07, 0.17, 0.92)
const C_BORDER := Color(0.35, 0.3, 0.6)
const C_CYAN := Color(0.5, 0.97, 1.0)
const C_GOLD := Color(1.0, 0.82, 0.4)
const C_EMBER := Color(1.0, 0.42, 0.29)
const C_TEXT := Color(0.88, 0.92, 1.0)
const C_DIM := Color(0.55, 0.56, 0.78)


static func label(text: String, size: int = 8, color: Color = C_TEXT, bold: bool = false,
		align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_override("font", FONT_BOLD if bold else FONT_BODY)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.03, 0.02, 0.08))
	l.add_theme_constant_override("outline_size", 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func title_label(text: String, size: int = 16, color: Color = C_CYAN) -> Label:
	var l := label(text, size, color, false, HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_font_override("font", FONT_TITLE)
	return l


static func panel_style(fill: Color = C_PANEL, border: Color = C_BORDER, bw: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(0)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 0
	s.shadow_offset = Vector2(3, 3)
	return s


static func make_panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_style())
	return p


static func button(text: String, on_press: Callable, width: float = 140.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, 24)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", FONT_BOLD)
	b.add_theme_font_size_override("font_size", 8)
	b.add_theme_color_override("font_color", C_TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", C_GOLD)
	var normal := panel_style(Color(0.12, 0.1, 0.24), C_BORDER, 2)
	var hover := panel_style(Color(0.2, 0.15, 0.38), C_CYAN, 2)
	var pressed := panel_style(Color(0.3, 0.2, 0.15), C_GOLD, 2)
	for s in [normal, hover, pressed]:
		s.content_margin_top = 5
		s.content_margin_bottom = 5
		s.shadow_size = 0
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.pressed.connect(func() -> void:
		AudioManager.play_sfx(&"ui_select", -2.0)
		on_press.call())
	b.mouse_entered.connect(func() -> void:
		if not b.has_focus():
			b.grab_focus())
	b.focus_entered.connect(func() -> void: AudioManager.play_sfx(&"ui_move", -6.0))
	return b


static func slider(value: float, on_change: Callable, width: float = 110.0) -> HSlider:
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(width, 14)
	s.focus_mode = Control.FOCUS_ALL
	var track := panel_style(Color(0.12, 0.1, 0.24), C_BORDER, 1)
	track.content_margin_top = 2
	track.content_margin_bottom = 2
	var fill := panel_style(C_CYAN.darkened(0.3), C_CYAN, 1)
	fill.content_margin_top = 2
	fill.content_margin_bottom = 2
	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	s.value_changed.connect(func(v: float) -> void:
		on_change.call(v)
		AudioManager.play_sfx(&"ui_move", -8.0, 1.0 + v * 0.5))
	return s


static func checkbox(text: String, value: bool, on_toggle: Callable) -> CheckButton:
	var c := CheckButton.new()
	c.text = text
	c.button_pressed = value
	c.add_theme_font_override("font", FONT_BODY)
	c.add_theme_font_size_override("font_size", 8)
	c.add_theme_color_override("font_color", C_TEXT)
	c.toggled.connect(func(on: bool) -> void:
		AudioManager.play_sfx(&"ui_select", -4.0)
		on_toggle.call(on))
	return c


static func credit_block(size_title: int = 8) -> VBoxContainer:
	## Exact credit lines required by the brief. Press Start 2P has lower-case
	## glyphs (Silkscreen is capitals-only), so the text shows exactly as written.
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var a := label(GameManager.CREDIT_LINE_1, size_title, C_GOLD, false, HORIZONTAL_ALIGNMENT_CENTER)
	a.add_theme_font_override("font", FONT_TITLE)
	var b := label(GameManager.CREDIT_LINE_2, size_title, C_DIM, false, HORIZONTAL_ALIGNMENT_CENTER)
	b.add_theme_font_override("font", FONT_TITLE)
	v.add_child(a)
	v.add_child(b)
	return v


static func center(c: Control) -> void:
	## Keep a container centred on screen as its content (and min size) changes.
	c.grow_horizontal = Control.GROW_DIRECTION_BOTH
	c.grow_vertical = Control.GROW_DIRECTION_BOTH
	var fix := func() -> void:
		c.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	c.minimum_size_changed.connect(fix)
	c.visibility_changed.connect(func() -> void: fix.call_deferred())
	fix.call()


static func fade_in(node: CanvasItem, time: float = 0.3) -> void:
	node.modulate.a = 0.0
	node.create_tween().tween_property(node, "modulate:a", 1.0, time)
