extends Area2D
## One-shot trigger: emits `triggered` the first time the player enters.

signal triggered(player: Node)

var _fired: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _fired or not body.is_in_group("player"):
		return
	_fired = true
	triggered.emit(body)


func reset() -> void:
	_fired = false
	for b in get_overlapping_bodies():
		_on_body_entered(b)
