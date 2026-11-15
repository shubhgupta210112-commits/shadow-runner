extends Node2D
## A lever (press E) that opens a crystal gate. Both are in this one scene:
## place it, then set gate_offset to where the gate should stand.

const Fx := preload("res://scripts/fx.gd")

signal toggled(open: bool)

@export var gate_offset: Vector2 = Vector2(64, -32)
@export var gate_pieces: int = 2
@export var prompt_text: String = "[E] Pull lever"

var is_open: bool = false

@onready var lever_area: Area2D = $Lever
@onready var lever_sprite: AnimatedSprite2D = $Lever/Sprite
@onready var gate_body: StaticBody2D = $Gate
@onready var gate_sprite: AnimatedSprite2D = $Gate/Sprite
@onready var gate_shape: CollisionShape2D = $Gate/Shape
@onready var gate_light: PointLight2D = $Gate/Light


func _ready() -> void:
	gate_body.position = gate_offset
	lever_sprite.sprite_frames = load("res://assets/sprites/lever_frames.tres") as SpriteFrames
	lever_sprite.play("off")
	gate_sprite.sprite_frames = load("res://assets/sprites/gate_frames.tres") as SpriteFrames
	gate_sprite.play("glow")
	gate_sprite.position = Vector2(0, -32)
	for i in range(1, gate_pieces):
		var extra := AnimatedSprite2D.new()
		extra.sprite_frames = gate_sprite.sprite_frames
		extra.position = Vector2(0, -32 - 64 * i)
		gate_body.add_child(extra)
		extra.play("glow")
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 64 * gate_pieces)
	gate_shape.shape = rect
	gate_shape.position = Vector2(0, -32 * gate_pieces)
	gate_light.position = Vector2(0, -32 * gate_pieces)
	lever_area.prompt_text = prompt_text
	lever_area.interacted.connect(_on_interacted)


func _on_interacted(_player: Node) -> void:
	if is_open:
		return
	is_open = true
	lever_sprite.play("on")
	AudioManager.play_sfx(&"lever")
	await get_tree().create_timer(0.25).timeout
	AudioManager.play_sfx(&"gate")
	gate_shape.set_deferred("disabled", true)
	Fx.burst(get_parent(), gate_body.global_position, Color(0.9, 0.4, 0.85), 24, 90.0, 0.8, 40.0, 180.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(gate_body, "modulate:a", 0.0, 0.8)
	tw.tween_property(gate_light, "energy", 0.0, 0.8)
	tw.chain().tween_callback(gate_body.queue_free)
	toggled.emit(true)
