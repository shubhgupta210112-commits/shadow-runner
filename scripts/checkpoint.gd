extends Area2D
## Rune obelisk. Touch to activate; the player respawns here after death.

const Fx := preload("res://scripts/fx.gd")

signal activated(checkpoint: Node)

var active: bool = false

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var light: PointLight2D = $Light


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	sprite.sprite_frames = load("res://assets/sprites/checkpoint_frames.tres") as SpriteFrames
	sprite.play("off")
	light.enabled = false
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if active or not body.is_in_group("player"):
		return
	activate()


func activate() -> void:
	active = true
	sprite.play("on")
	light.enabled = true
	AudioManager.play_sfx(&"checkpoint")
	Fx.sparkle(get_parent(), global_position + Vector2(0, -24), Color(0.5, 0.97, 1.0))
	Fx.popup_text(get_parent(), global_position + Vector2(0, -50), "CHECKPOINT", Color(0.5, 0.97, 1.0))
	activated.emit(self)


func get_respawn_position() -> Vector2:
	return global_position + Vector2(0, -2)
