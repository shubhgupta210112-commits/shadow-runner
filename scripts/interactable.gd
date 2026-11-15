extends Area2D
## Attach to an Area2D to make it respond to the E (interact) key when the
## player's InteractSensor overlaps it.

signal interacted(player: Node)

var prompt_text: String = "[E] Interact"
var used: bool = false


func _ready() -> void:
	collision_layer = 256
	collision_mask = 0


func can_interact() -> bool:
	return not used


func interact(player: Node) -> void:
	if used:
		return
	used = true
	interacted.emit(player)
