extends CanvasLayer
## Android / touchscreen controls: a left-thumb D-pad (left/right) and right-thumb Jump + Attack.
## Uses TouchScreenButton so several fingers work at once (run + jump + attack together).

const DIR := "res://assets/mobile/"

var _left: TouchScreenButton
var _right: TouchScreenButton
var _jump: TouchScreenButton
var _action: TouchScreenButton
var _tex_cache: Dictionary = {}


func _ready() -> void:
    layer = 20
    process_mode = Node.PROCESS_MODE_PAUSABLE
    _left = _make("left", "move_left", true)
    _right = _make("right", "move_right", true)
    _jump = _make("jump", "jump", false)
    _action = _make("action", "action", false)
    get_viewport().size_changed.connect(_layout)
    _layout()


func _tex(n: String) -> Texture2D:
    if not _tex_cache.has(n):
        _tex_cache[n] = load(DIR + n + ".png")
    return _tex_cache[n]


func _make(icon: String, act: String, passby: bool) -> TouchScreenButton:
    var b := TouchScreenButton.new()
    b.texture_normal = _tex("btn_" + icon)
    b.texture_pressed = _tex("btn_" + icon + "_down")
    b.action = act
    b.passby_press = passby
    add_child(b)
    return b


func _layout() -> void:
    var vs: Vector2 = get_viewport().get_visible_rect().size
    var s := clampf(vs.y / 720.0, 0.8, 1.4)
    var bs := 176.0 * s
    var margin := 34.0 * s
    var y := vs.y - bs - margin
    # movement cluster: bottom-left, big and well spaced
    _left.scale = Vector2(s, s)
    _right.scale = Vector2(s, s)
    _left.position = Vector2(margin, y)
    _right.position = Vector2(margin + bs + 26.0 * s, y)
    # action cluster: bottom-right; jump is the thumb-natural lower button
    _jump.scale = Vector2(s, s)
    _action.scale = Vector2(s, s)
    _jump.position = Vector2(vs.x - margin - bs, y)
    _action.position = Vector2(vs.x - margin - bs * 2.0 - 30.0 * s, y - 40.0 * s)
