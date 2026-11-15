extends Area2D
## Environmental hazard (spikes). Damages the player on contact; the player's
## hurtbox polls overlapping areas and calls on_player_contact().

@export var damage: int = 1


func _ready() -> void:
	collision_layer = 16
	collision_mask = 0
	monitoring = false


func on_player_contact(player: Node) -> void:
	player.take_damage(damage, global_position.x)
