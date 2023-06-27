extends Node

static func executePower(player: PlayerScene):
	player.set_collision_layer_value(5, !player.get_collision_mask_value(5))
	player.set_collision_mask_value(5, !player.get_collision_mask_value(5))
	if !player.get_collision_mask_value(5):
		player.SPEED = 150
		player.sprite.modulate.a = 0.5
	else:
		player.SPEED = 100
		player.sprite.modulate.a = 1
