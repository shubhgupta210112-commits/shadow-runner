extends CanvasLayer
## In-game HUD: health, crystals, score, boss bar, toasts, cinematic bars, pause / defeat / victory screens.

signal retry_requested

const SettingsPanel = preload("res://scripts/settings_panel.gd")
const HEART_TEX := "res://assets/environments/heart.png"
const CRYSTAL_TEX := "res://assets/environments/crystal.png"
const PAUSE_TEX := "res://assets/mobile/btn_pause.png"
const VIGNETTE_TEX := "res://assets/ui/vignette.png"

var crystal_total: int = 0
var hidden_total: int = 3
var ended: bool = false

var _root: Control
var _hp_bar: ProgressBar
var _hp_label: Label
var _crystal_label: Label
var _score_label: Label
var _boss_box: VBoxContainer
var _boss_bar: ProgressBar
var _boss_name: Label
var _toast: Label
var _toast_tween: Tween
var _bar_top: ColorRect
var _bar_bottom: ColorRect
var _title_box: VBoxContainer
var _banner: Label
var _pause_layer: Control
var _defeat_layer: Control
var _victory_layer: Control
var _settings_open: bool = false
var _shown_score: float = 0.0
var _hp_style: StyleBoxFlat
var _boss_hp: int = 1


func _ready() -> void:
    layer = 10
    process_mode = Node.PROCESS_MODE_ALWAYS
    _root = Control.new()
    _root.set_anchors_preset(Control.PRESET_FULL_RECT)
    _root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _root.theme = Game.ui_theme
    add_child(_root)

    var vig := TextureRect.new()
    vig.texture = load(VIGNETTE_TEX)
    vig.set_anchors_preset(Control.PRESET_FULL_RECT)
    vig.stretch_mode = TextureRect.STRETCH_SCALE
    vig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
    vig.modulate = Color(1, 1, 1, 0.8)
    _root.add_child(vig)

    _build_top_bar()
    _build_boss_bar()
    _build_overlays_misc()
    _pause_layer = _build_pause()
    _defeat_layer = Control.new()
    _victory_layer = Control.new()
    Game.toast.connect(show_toast)


# ------------------------------------------------------------------ top bar
func _build_top_bar() -> void:
    var bar := HBoxContainer.new()
    bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 22)
    bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    bar.add_theme_constant_override("separation", 18)
    _root.add_child(bar)

    var heart := TextureRect.new()
    heart.texture = load(HEART_TEX)
    heart.custom_minimum_size = Vector2(54, 54)
    heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
    bar.add_child(heart)

    _hp_bar = ProgressBar.new()
    _hp_bar.custom_minimum_size = Vector2(340, 34)
    _hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    _hp_bar.max_value = 100
    _hp_bar.value = 100
    _hp_bar.show_percentage = false
    var bg := StyleBoxFlat.new()
    bg.bg_color = Color(0.03, 0.03, 0.12, 0.8)
    bg.border_color = Color(0.4, 0.9, 1.0, 0.9)
    bg.set_border_width_all(3)
    bg.set_corner_radius_all(10)
    _hp_bar.add_theme_stylebox_override("background", bg)
    _hp_style = StyleBoxFlat.new()
    _hp_style.bg_color = Color(0.25, 0.95, 0.6)
    _hp_style.set_corner_radius_all(8)
    _hp_bar.add_theme_stylebox_override("fill", _hp_style)
    bar.add_child(_hp_bar)

    _hp_label = Game.make_label("100", 30)
    _hp_label.custom_minimum_size = Vector2(70, 0)
    bar.add_child(_hp_label)

    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    bar.add_child(spacer)

    var stats := VBoxContainer.new()
    stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stats.add_theme_constant_override("separation", 0)
    bar.add_child(stats)

    var crow := HBoxContainer.new()
    crow.alignment = BoxContainer.ALIGNMENT_END
    crow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var cicon := TextureRect.new()
    cicon.texture = load(CRYSTAL_TEX)
    cicon.custom_minimum_size = Vector2(34, 44)
    cicon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    cicon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    cicon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    crow.add_child(cicon)
    _crystal_label = Game.make_label("0", 36, Color(0.55, 0.95, 1.0))
    crow.add_child(_crystal_label)
    stats.add_child(crow)

    _score_label = Game.make_label("SCORE 000000", 34, Color(1.0, 0.9, 0.55))
    _score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    stats.add_child(_score_label)

    var pause := TextureButton.new()
    pause.texture_normal = load(PAUSE_TEX)
    pause.texture_pressed = load("res://assets/mobile/btn_pause_down.png")
    pause.custom_minimum_size = Vector2(84, 84)
    pause.ignore_texture_size = true
    pause.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
    pause.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    pause.focus_mode = Control.FOCUS_NONE
    pause.pressed.connect(toggle_pause)
    bar.add_child(pause)


func _build_boss_bar() -> void:
    _boss_box = VBoxContainer.new()
    _boss_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
    _boss_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
    _boss_box.offset_top = 100.0
    _boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _boss_box.visible = false
    _boss_name = Game.make_label("VOID GUARDIAN", 38, Color(1.0, 0.6, 0.95))
    _boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _boss_box.add_child(_boss_name)
    _boss_bar = ProgressBar.new()
    _boss_bar.custom_minimum_size = Vector2(640, 28)
    _boss_bar.show_percentage = false
    _boss_bar.max_value = 30
    _boss_bar.value = 30
    var bg := StyleBoxFlat.new()
    bg.bg_color = Color(0.08, 0.0, 0.12, 0.85)
    bg.border_color = Color(1.0, 0.5, 0.95, 0.95)
    bg.set_border_width_all(3)
    bg.set_corner_radius_all(8)
    _boss_bar.add_theme_stylebox_override("background", bg)
    var fill := StyleBoxFlat.new()
    fill.bg_color = Color(0.9, 0.25, 0.85)
    fill.set_corner_radius_all(6)
    _boss_bar.add_theme_stylebox_override("fill", fill)
    _boss_box.add_child(_boss_bar)
    _root.add_child(_boss_box)


func _build_overlays_misc() -> void:
    _toast = Game.make_label("", 44, Color(1.0, 1.0, 1.0))
    _toast.custom_minimum_size = Vector2(900, 60)
    _toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
    _toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
    _toast.offset_top = 150.0
    _toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _toast.modulate.a = 0.0
    _root.add_child(_toast)

    _bar_top = ColorRect.new()
    _bar_top.color = Color(0, 0, 0, 1)
    _bar_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
    _bar_top.custom_minimum_size = Vector2(0, 0)
    _bar_top.size = Vector2(0, 0)
    _bar_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _root.add_child(_bar_top)
    _bar_bottom = ColorRect.new()
    _bar_bottom.color = Color(0, 0, 0, 1)
    _bar_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    _bar_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _root.add_child(_bar_bottom)
    _set_bars(0.0)

    _title_box = VBoxContainer.new()
    _title_box.custom_minimum_size = Vector2(1000, 0)
    _title_box.set_anchors_preset(Control.PRESET_CENTER)
    _title_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
    _title_box.grow_vertical = Control.GROW_DIRECTION_BOTH
    _title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _title_box.modulate.a = 0.0
    _root.add_child(_title_box)

    _banner = Game.make_label("", 120, Color(1.0, 0.5, 0.95))
    _banner.custom_minimum_size = Vector2(1100, 150)
    _banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _banner.set_anchors_preset(Control.PRESET_CENTER)
    _banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
    _banner.grow_vertical = Control.GROW_DIRECTION_BOTH
    _banner.modulate.a = 0.0
    _root.add_child(_banner)


func _set_bars(h: float) -> void:
    # letterbox bars (anchored top / bottom, grow inward)
    _bar_top.anchor_left = 0.0
    _bar_top.anchor_right = 1.0
    _bar_top.anchor_top = 0.0
    _bar_top.anchor_bottom = 0.0
    _bar_top.offset_left = 0.0
    _bar_top.offset_right = 0.0
    _bar_top.offset_top = 0.0
    _bar_top.offset_bottom = h
    _bar_bottom.anchor_left = 0.0
    _bar_bottom.anchor_right = 1.0
    _bar_bottom.anchor_top = 1.0
    _bar_bottom.anchor_bottom = 1.0
    _bar_bottom.offset_left = 0.0
    _bar_bottom.offset_right = 0.0
    _bar_bottom.offset_top = -h
    _bar_bottom.offset_bottom = 0.0


# ------------------------------------------------------------------ pause menu
func _overlay(title_text: String, title_color: Color) -> Array:
    var layer_ctl := Control.new()
    layer_ctl.set_anchors_preset(Control.PRESET_FULL_RECT)
    layer_ctl.mouse_filter = Control.MOUSE_FILTER_STOP
    layer_ctl.visible = false
    _root.add_child(layer_ctl)
    var dim := ColorRect.new()
    dim.color = Color(0.0, 0.0, 0.06, 0.62)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    layer_ctl.add_child(dim)
    var center := CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    layer_ctl.add_child(center)
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(560, 0)
    center.add_child(panel)
    var m := MarginContainer.new()
    m.add_theme_constant_override("margin_left", 36)
    m.add_theme_constant_override("margin_right", 36)
    m.add_theme_constant_override("margin_top", 28)
    m.add_theme_constant_override("margin_bottom", 30)
    panel.add_child(m)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 14)
    m.add_child(box)
    var t := Game.make_label(title_text, 62, title_color)
    t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(t)
    return [layer_ctl, box, t]


func _btn(box: Control, text: String, cb: Callable) -> Button:
    var b := Game.make_button(text, Vector2(440, 66))
    b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    b.process_mode = Node.PROCESS_MODE_ALWAYS
    b.pressed.connect(cb)
    box.add_child(b)
    return b


func _build_pause() -> Control:
    var o: Array = _overlay("PAUSED", Color(0.6, 0.95, 1.0))
    var layer_ctl: Control = o[0]
    var box: VBoxContainer = o[1]
    _btn(box, "RESUME", toggle_pause)
    _btn(box, "RESTART", _on_restart)
    _btn(box, "SETTINGS", _on_settings)
    _btn(box, "MAIN MENU", _on_menu)
    return layer_ctl


func toggle_pause() -> void:
    if ended or _settings_open:
        return
    var p := not get_tree().paused
    get_tree().paused = p
    _pause_layer.visible = p
    Game.sfx("ui_click")
    if p:
        for c in _pause_layer.find_children("*", "Button", true, false):
            (c as Button).grab_focus()
            break


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        toggle_pause()
        get_viewport().set_input_as_handled()


func _on_settings() -> void:
    _settings_open = true
    var sp := Control.new()
    sp.set_script(SettingsPanel)
    sp.tree_exited.connect(_on_settings_closed)
    _root.add_child(sp)


func _on_restart() -> void:
    ended = true
    Game.new_game()
    Game.goto_scene(Game.LEVEL_SCENE)


func _on_menu() -> void:
    ended = true
    Game.goto_scene(Game.MENU_SCENE)


# ------------------------------------------------------------------ live values
func bind_player(p: Node) -> void:
    p.health_changed.connect(_on_health)


func _on_health(cur: int, mx: int) -> void:
    _hp_bar.max_value = mx
    var tw := create_tween()
    tw.tween_property(_hp_bar, "value", float(cur), 0.25)
    _hp_label.text = str(cur)
    var f := float(cur) / float(mx)
    if f > 0.5:
        _hp_style.bg_color = Color(0.25, 0.95, 0.6)
    elif f > 0.25:
        _hp_style.bg_color = Color(1.0, 0.8, 0.25)
    else:
        _hp_style.bg_color = Color(1.0, 0.3, 0.3)


func bind_boss(b: Node) -> void:
    b.health_changed.connect(_on_boss_health)


func _on_boss_health(cur: int, mx: int) -> void:
    _boss_bar.max_value = mx
    var tw := create_tween()
    tw.tween_property(_boss_bar, "value", float(cur), 0.2)
    _boss_hp = cur


func show_boss_bar(on: bool) -> void:
    _boss_box.visible = on
    if on:
        _boss_box.modulate.a = 0.0
        create_tween().tween_property(_boss_box, "modulate:a", 1.0, 0.8)


func _process(delta: float) -> void:
    _shown_score = lerpf(_shown_score, float(Game.score), clampf(delta * 8.0, 0.0, 1.0))
    if absf(_shown_score - float(Game.score)) < 1.0:
        _shown_score = float(Game.score)
    _score_label.text = "SCORE %06d" % int(round(_shown_score))
    _crystal_label.text = " %d / %d" % [Game.crystals, crystal_total]


func show_toast(text: String) -> void:
    _toast.text = text
    if _toast_tween and _toast_tween.is_valid():
        _toast_tween.kill()
    _toast.modulate.a = 1.0
    _toast_tween = create_tween()
    _toast_tween.tween_interval(0.9)
    _toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.5)


# ------------------------------------------------------------------ cinematics
func cinematic_bars(on: bool, t: float = 0.7) -> void:
    var tw := create_tween()
    tw.tween_method(_set_bars, 0.0 if on else 90.0, 90.0 if on else 0.0, t)


func show_title_card(line1: String, line2: String, hold: float = 2.4) -> void:
    for c in _title_box.get_children():
        c.queue_free()
    var a := Game.make_label(line1, 40, Color(0.6, 0.95, 1.0))
    a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _title_box.add_child(a)
    var b := Game.make_label(line2, 110, Color(1.0, 1.0, 1.0))
    b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    b.add_theme_color_override("font_shadow_color", Color(0.1, 0.8, 1.0, 0.8))
    _title_box.add_child(b)
    _title_box.modulate.a = 0.0
    var tw := create_tween()
    tw.tween_property(_title_box, "modulate:a", 1.0, 0.8)
    tw.tween_interval(hold)
    tw.tween_property(_title_box, "modulate:a", 0.0, 0.8)


func show_banner(text: String, hold: float = 1.6) -> void:
    _banner.text = text
    _banner.modulate.a = 0.0
    var tw := create_tween()
    tw.tween_property(_banner, "modulate:a", 1.0, 0.35)
    tw.tween_interval(hold)
    tw.tween_property(_banner, "modulate:a", 0.0, 0.6)


# ------------------------------------------------------------------ end screens
func show_defeat() -> void:
    if ended:
        return
    ended = true
    get_tree().paused = false
    _pause_layer.visible = false
    var o: Array = _overlay("YOU FELL", Color(1.0, 0.4, 0.45))
    _defeat_layer = o[0]
    var box: VBoxContainer = o[1]
    var sub := Game.make_label("Score  %d    Crystals  %d" % [Game.score, Game.crystals], 32, Color(0.9, 0.9, 1.0))
    sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(sub)
    var retry := _btn(box, "RETRY FROM CHECKPOINT", _on_retry)
    _btn(box, "RESTART CHAPTER", _on_restart)
    _btn(box, "MAIN MENU", _on_menu)
    _defeat_layer.visible = true
    _defeat_layer.modulate.a = 0.0
    create_tween().tween_property(_defeat_layer, "modulate:a", 1.0, 0.5)
    retry.grab_focus()


func show_victory(stats: Dictionary) -> void:
    ended = true
    var o: Array = _overlay("CHAPTER COMPLETE", Color(1.0, 0.9, 0.5))
    _victory_layer = o[0]
    var box: VBoxContainer = o[1]
    var title: Label = o[2]
    title.modulate.a = 0.0
    create_tween().tween_property(title, "modulate:a", 1.0, 0.6).set_delay(0.2)
    var sub := Game.make_label("THE FALLEN CITY IS FREE", 34, Color(0.6, 0.95, 1.0))
    sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(sub)

    var score_l := Game.make_label("FINAL SCORE   0", 46, Color(1.0, 0.9, 0.55))
    score_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(score_l)
    var cry_l := Game.make_label("CRYSTALS   0 / %d" % int(stats.get("crystal_total", 0)), 36, Color(0.55, 0.95, 1.0))
    cry_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(cry_l)
    var hid_l := Game.make_label("HIDDEN CRYSTALS   %d / %d" % [int(stats.get("hidden", 0)), hidden_total], 30, Color(1.0, 0.8, 0.4))
    hid_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(hid_l)
    var time_l := Game.make_label("TIME   %s" % String(stats.get("time", "0:00")), 30, Color(0.85, 0.9, 1.0))
    time_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(time_l)
    var rank_l := Game.make_label("RANK   %s" % String(stats.get("rank", "B")), 56, Color(1.0, 0.95, 0.6))
    rank_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    rank_l.modulate.a = 0.0
    box.add_child(rank_l)

    var replay := _btn(box, "REPLAY", _on_restart)
    _btn(box, "MAIN MENU", _on_menu)

    _victory_layer.visible = true
    _victory_layer.modulate.a = 0.0
    var tw := create_tween()
    tw.tween_property(_victory_layer, "modulate:a", 1.0, 0.6)
    # completion animation: title drops in, numbers count up, rank stamps
    var final_score: int = int(stats.get("score", Game.score))
    var final_cry: int = int(stats.get("crystals", Game.crystals))
    var ctotal: int = int(stats.get("crystal_total", 0))
    var tw2 := create_tween()
    tw2.set_parallel(true)
    tw2.tween_method(_count_score.bind(score_l), 0.0, float(final_score), 1.6).set_delay(0.5)
    tw2.tween_method(_count_crystals.bind(cry_l, ctotal), 0.0, float(final_cry), 1.2).set_delay(0.7)
    tw2.tween_property(rank_l, "modulate:a", 1.0, 0.4).set_delay(2.2)
    replay.grab_focus()
    Game.sfx("victory")


func _count_score(v: float, lbl: Label) -> void:
    lbl.text = "FINAL SCORE   %d" % int(v)


func _count_crystals(v: float, lbl: Label, total: int) -> void:
    lbl.text = "CRYSTALS   %d / %d" % [int(v), total]


func _on_retry() -> void:
    retry_requested.emit()


func _on_settings_closed() -> void:
    _settings_open = false
