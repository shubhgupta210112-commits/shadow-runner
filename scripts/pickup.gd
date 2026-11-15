extends Area2D
## Collectible: coin, shard (hidden collectible) or heart (health pickup).

const Fx := preload("res://scripts/fx.gd")

enum Kind { COIN, SHARD, HEART }

@export var kind: Kind = Kind.COIN

var _taken: bool = false
var _t: float = 0.0
var _base_y: float = 0.0

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	collision_layer = 32
	collision_mask = 4
	_base_y = sprite.position.y
	_t = randf() * 6.0
	var frames := {
		Kind.COIN: "res://assets/sprites/coin_frames.tres",
		Kind.SHARD: "res://assets/sprites/shard_frames.tres",
		Kind.HEART: "res://assets/sprites/heart_pickup_frames.tres",
	}
	sprite.sprite_frames = load(frames[kind]) as SpriteFrames
	sprite.play(sprite.sprite_frames.get_animation_names()[0])
	sprite.frame = randi() % sprite.sprite_frames.get_frame_count(sprite.animation)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	sprite.position.y = _base_y + sin(_t * 3.0) * (2.0 if kind != Kind.COIN else 1.0)


func _on_body_entered(body: Node) -> void:
	if _taken or not body.is_in_group("player"):
		return
	if kind == Kind.HEART and body.health >= body.max_health:
		return
	_taken = true
	match kind:
		Kind.COIN:
			GameManager.add_coin(10)
			AudioManager.play_sfx(&"coin", -4.0, 1.0, 0.05)
			Fx.sparkle(get_parent(), global_position, Color(1.0, 0.82, 0.4))
		Kind.SHARD:
			GameManager.add_shard(500)
			AudioManager.play_sfx(&"shard")
			Fx.sparkle(get_parent(), global_position, Color(0.5, 0.97, 1.0))
			Fx.popup_text(get_parent(), global_position + Vector2(0, -10), "SHADOW SHARD +500", Color(0.5, 0.97, 1.0))
		Kind.HEART:
			body.heal(1)
			AudioManager.play_sfx(&"heal")
			Fx.popup_text(get_parent(), global_position + Vector2(0, -10), "+1 HEART", Color(1.0, 0.5, 0.45))
	set_deferred("monitoring", false)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(sprite, "position:y", sprite.position.y - 14.0, 0.2)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(queue_free)
