extends Node
## Global game state, audio, settings, scene transitions and UI theme (autoload "Game").

signal toast(text: String)

const SETTINGS_PATH := "user://shadow_runner_settings.cfg"
const FONT_PATH := "res://assets/fonts/BigShoulders-Bold.ttf"
const DEV_NAME := "Shubh Gupta"
const DEV_EMAIL := "shubhgupta210112@gmail.com"
const MENU_SCENE := "res://scenes/main_menu.tscn"
const LEVEL_SCENE := "res://scenes/level.tscn"

var score: int = 0
var crystals: int = 0
var hidden_found: int = 0
var best_score: int = 0
var checkpoint_pos: Vector2 = Vector2(150, 470)
var music_volume: float = 0.7
var sfx_volume: float = 0.9
var touch_controls: bool = false
var screen_shake: bool = true
var ui_theme: Theme
var ui_font: Font

var _sfx_players: Array = []
var _sfx_idx: int = 0
var _music: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _music_name: String = ""
var _cache: Dictionary = {}
var _fade: ColorRect
var _transitioning: bool = false
var _hitstopping: bool = false


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _setup_input()
    touch_controls = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
    load_settings()
    for i in range(10):
        var p := AudioStreamPlayer.new()
        add_child(p)
        _sfx_players.append(p)
    _music = AudioStreamPlayer.new()
    add_child(_music)
    _ambience = AudioStreamPlayer.new()
    add_child(_ambience)
    var layer := CanvasLayer.new()
    layer.layer = 100
    add_child(layer)
    _fade = ColorRect.new()
    _fade.color = Color(0.02, 0.0, 0.08, 0.0)
    _fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _fade.set_anchors_preset(Control.PRESET_FULL_RECT)
    layer.add_child(_fade)
    _build_theme()
    apply_volumes()


# ------------------------------------------------------------------ input
func _setup_input() -> void:
    _add_keys("move_left", [KEY_A, KEY_LEFT])
    _add_keys("move_right", [KEY_D, KEY_RIGHT])
    _add_keys("jump", [KEY_SPACE, KEY_W, KEY_UP])
    _add_keys("action", [KEY_E, KEY_J, KEY_X])
    _add_keys("pause", [KEY_ESCAPE, KEY_P])
    _add_pad("move_left", JOY_BUTTON_DPAD_LEFT)
    _add_pad("move_right", JOY_BUTTON_DPAD_RIGHT)
    _add_pad("jump", JOY_BUTTON_A)
    _add_pad("action", JOY_BUTTON_X)
    _add_pad("pause", JOY_BUTTON_START)
    var axis := InputEventJoypadMotion.new()
    axis.axis = JOY_AXIS_LEFT_X
    axis.axis_value = -1.0
    InputMap.action_add_event("move_left", axis)
    var axis2 := InputEventJoypadMotion.new()
    axis2.axis = JOY_AXIS_LEFT_X
    axis2.axis_value = 1.0
    InputMap.action_add_event("move_right", axis2)


func _add_keys(action: String, keys: Array) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action, 0.5)
    for k in keys:
        var ev := InputEventKey.new()
        ev.physical_keycode = k
        InputMap.action_add_event(action, ev)


func _add_pad(action: String, button: int) -> void:
    var ev := InputEventJoypadButton.new()
    ev.button_index = button
    InputMap.action_add_event(action, ev)


# ------------------------------------------------------------------ state
func new_game() -> void:
    set_meta("intro_seen", false)
    score = 0
    crystals = 0
    hidden_found = 0
    checkpoint_pos = Vector2(150, 470)


func add_score(n: int) -> void:
    score += n
    if score > best_score:
        best_score = score


func add_crystal(n: int, hidden: bool = false) -> void:
    crystals += n
    if hidden:
        hidden_found += 1


func is_mobile() -> bool:
    return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")


# ------------------------------------------------------------------ settings
func load_settings() -> void:
    var cf := ConfigFile.new()
    if cf.load(SETTINGS_PATH) != OK:
        return
    music_volume = float(cf.get_value("audio", "music", music_volume))
    sfx_volume = float(cf.get_value("audio", "sfx", sfx_volume))
    touch_controls = bool(cf.get_value("controls", "touch", touch_controls))
    screen_shake = bool(cf.get_value("video", "shake", screen_shake))
    best_score = int(cf.get_value("progress", "best", best_score))


func save_settings() -> void:
    var cf := ConfigFile.new()
    cf.set_value("audio", "music", music_volume)
    cf.set_value("audio", "sfx", sfx_volume)
    cf.set_value("controls", "touch", touch_controls)
    cf.set_value("video", "shake", screen_shake)
    cf.set_value("progress", "best", best_score)
    cf.save(SETTINGS_PATH)


func apply_volumes() -> void:
    if _music:
        _music.volume_db = linear_to_db(maxf(music_volume, 0.0001)) - 5.0
    if _ambience:
        _ambience.volume_db = linear_to_db(maxf(music_volume, 0.0001)) - 12.0


# ------------------------------------------------------------------ audio
func _get_stream(sname: String) -> AudioStream:
    if _cache.has(sname):
        return _cache[sname]
    var path := "res://assets/audio/%s.wav" % sname
    if not ResourceLoader.exists(path):
        return null
    var s: AudioStream = load(path)
    _cache[sname] = s
    return s


func sfx(sname: String, vol_db: float = 0.0, pitch: float = 1.0) -> void:
    var s := _get_stream(sname)
    if s == null or sfx_volume <= 0.001:
        return
    var p: AudioStreamPlayer = _sfx_players[_sfx_idx]
    _sfx_idx = (_sfx_idx + 1) % _sfx_players.size()
    p.stream = s
    p.volume_db = linear_to_db(sfx_volume) + vol_db
    p.pitch_scale = pitch
    p.play()


func _looped(sname: String) -> AudioStream:
    var s := _get_stream(sname)
    if s is AudioStreamWAV:
        var w: AudioStreamWAV = s.duplicate() as AudioStreamWAV
        w.loop_mode = AudioStreamWAV.LOOP_FORWARD
        w.loop_begin = 0
        w.loop_end = int(w.get_length() * float(w.mix_rate))
        return w
    return s


func play_music(sname: String) -> void:
    if _music_name == sname and _music.playing:
        return
    _music_name = sname
    _music.stream = _looped(sname)
    apply_volumes()
    _music.play()


func stop_music() -> void:
    _music_name = ""
    _music.stop()


func play_ambience(sname: String) -> void:
    _ambience.stream = _looped(sname)
    apply_volumes()
    _ambience.play()


func stop_ambience() -> void:
    _ambience.stop()


# ------------------------------------------------------------------ transitions & feel
func goto_scene(path: String) -> void:
    if _transitioning:
        return
    _transitioning = true
    Engine.time_scale = 1.0
    var tw := create_tween()
    tw.tween_property(_fade, "color:a", 1.0, 0.35)
    await tw.finished
    get_tree().paused = false
    get_tree().change_scene_to_file(path)
    await get_tree().process_frame
    await get_tree().process_frame
    var tw2 := create_tween()
    tw2.tween_property(_fade, "color:a", 0.0, 0.45)
    await tw2.finished
    _transitioning = false


func fade_flash(color: Color, duration: float = 0.4) -> void:
    var c := _fade
    c.color = Color(color.r, color.g, color.b, 0.9)
    var tw := create_tween()
    tw.tween_property(c, "color:a", 0.0, duration)


func hitstop(duration: float = 0.05, time_scale: float = 0.05) -> void:
    if _hitstopping:
        return
    _hitstopping = true
    Engine.time_scale = time_scale
    await get_tree().create_timer(duration, true, false, true).timeout
    Engine.time_scale = 1.0
    _hitstopping = false


# ------------------------------------------------------------------ UI helpers
func _box(bg: Color, border: Color, radius: int = 14, bw: int = 3) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = bg
    sb.border_color = border
    sb.set_border_width_all(bw)
    sb.set_corner_radius_all(radius)
    sb.content_margin_left = 30
    sb.content_margin_right = 30
    sb.content_margin_top = 10
    sb.content_margin_bottom = 10
    sb.shadow_color = Color(0, 0, 0, 0.45)
    sb.shadow_size = 8
    return sb


func _build_theme() -> void:
    ui_theme = Theme.new()
    if ResourceLoader.exists(FONT_PATH):
        ui_font = load(FONT_PATH)
        ui_theme.default_font = ui_font
    ui_theme.default_font_size = 30
    ui_theme.set_stylebox("normal", "Button", _box(Color(0.07, 0.09, 0.24, 0.88), Color(0.3, 0.85, 1.0, 0.75)))
    ui_theme.set_stylebox("hover", "Button", _box(Color(0.14, 0.2, 0.48, 0.95), Color(0.75, 1.0, 1.0, 1.0)))
    ui_theme.set_stylebox("focus", "Button", _box(Color(0.14, 0.2, 0.48, 0.95), Color(1.0, 0.75, 0.3, 1.0)))
    ui_theme.set_stylebox("pressed", "Button", _box(Color(0.5, 0.22, 0.1, 0.95), Color(1.0, 0.8, 0.35, 1.0)))
    ui_theme.set_stylebox("disabled", "Button", _box(Color(0.1, 0.1, 0.16, 0.6), Color(0.3, 0.3, 0.4, 0.6)))
    ui_theme.set_font_size("font_size", "Button", 36)
    ui_theme.set_color("font_color", "Button", Color(0.92, 0.97, 1.0))
    ui_theme.set_color("font_hover_color", "Button", Color(1, 1, 1))
    ui_theme.set_color("font_focus_color", "Button", Color(1, 1, 1))
    ui_theme.set_color("font_pressed_color", "Button", Color(1, 0.95, 0.8))
    ui_theme.set_stylebox("panel", "Panel", _box(Color(0.04, 0.03, 0.13, 0.94), Color(0.3, 0.85, 1.0, 0.8), 20, 3))
    ui_theme.set_color("font_color", "Label", Color(0.95, 0.97, 1.0))
    ui_theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.75))
    ui_theme.set_constant("shadow_offset_x", "Label", 2)
    ui_theme.set_constant("shadow_offset_y", "Label", 3)
    ui_theme.set_font_size("font_size", "CheckButton", 32)


func make_button(text: String, min_size: Vector2 = Vector2(360, 66)) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = min_size
    b.focus_mode = Control.FOCUS_ALL
    b.mouse_entered.connect(func() -> void: sfx("ui_hover"))
    b.pressed.connect(func() -> void: sfx("ui_click"))
    return b


func make_label(text: String, size: int = 30, color: Color = Color(0.95, 0.97, 1.0)) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return l
