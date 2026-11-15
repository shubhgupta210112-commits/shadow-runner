extends Area2D
## Spirit portal at the end of the level. Becomes active when `unlocked`.

signal entered(player: Node)

var unlocked: bool = false

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var light: PointLight2D = $Light


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	sprite.sprite_frames = load("res://assets/sprites/portal_frames.tres") as SpriteFrames
	sprite.play("swirl")
	set_unlocked(false)
	body_entered.connect(_on_body_entered)


func set_unlocked(v: bool) -> void:
	unlocked = v
	sprite.modulate = Color(1, 1, 1, 1) if v else Color(0.35, 0.35, 0.5, 0.7)
	light.enabled = v


func _on_body_entered(body: Node) -> void:
	if unlocked and body.is_in_group("player"):
		entered.emit(body)
