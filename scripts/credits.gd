extends Control
## Scrolling game credits.

const UI := preload("res://scripts/ui_kit.gd")

var _scroll: VBoxContainer
var _speed: float = 26.0
var _done: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size = Vector2(640, 360)
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -1
	add_child(bg_layer)
	bg_layer.add_child(preload("res://scripts/menu_background.gd").new())
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.06, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	_scroll = VBoxContainer.new()
	_scroll.add_theme_constant_override("separation", 10)
	_scroll.custom_minimum_size = Vector2(640, 0)
	_scroll.position = Vector2(0, 370)
	add_child(_scroll)
	var logo := TextureRect.new()
	logo.texture = load("res://assets/menus/logo.png") as Texture2D
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.custom_minimum_size = Vector2(500, 110)
	_scroll.add_child(logo)
	_add("CREDITS", UI.C_CYAN, 10, true)
	_add("GAME DESIGN, PROGRAMMING, ART DIRECTION", UI.C_DIM, 7)
	_scroll.add_child(UI.credit_block(8))
	_spacer()
	_add("ENGINE", UI.C_DIM, 7)
	_add("Godot Engine 4  -  GDScript", UI.C_TEXT, 8)
	_spacer()
	_add("ART", UI.C_DIM, 7)
	_add("All sprites, tiles and backgrounds are original\nand generated procedurally for this project", UI.C_TEXT, 8)
	_spacer()
	_add("AUDIO", UI.C_DIM, 7)
	_add("All music and sound effects are original\nsynthesised chiptune audio", UI.C_TEXT, 8)
	_spacer()
	_add("FONTS", UI.C_DIM, 7)
	_add("Press Start 2P  -  CodeMan38\nSilkscreen  -  Jason Kottke\nSIL Open Font License 1.1", UI.C_TEXT, 8)
	_spacer()
	_add("THANK YOU FOR PLAYING", UI.C_EMBER, 10, true)
	_spacer()
	_add("Press Esc / Enter to return", UI.C_DIM, 7)
	AudioManager.play_music(&"menu")
	UI.fade_in(self, 0.5)


func _add(text: String, color: Color, size: int, bold: bool = false) -> void:
	var l := UI.label(text, size, color, bold, HORIZONTAL_ALIGNMENT_CENTER)
	_scroll.add_child(l)


func _spacer() -> void:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, 16)
	_scroll.add_child(c)


func _process(delta: float) -> void:
	var speed := _speed * (3.0 if Input.is_action_pressed("jump") else 1.0)
	_scroll.position.y -= speed * delta
	if _scroll.position.y + _scroll.size.y < -10.0 and not _done:
		_done = true
		GameManager.go_to_menu()


func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		_done = true
		AudioManager.play_sfx(&"ui_back")
		GameManager.go_to_menu()
