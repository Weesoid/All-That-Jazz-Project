static func executePower(player: PlayerScene):
	if !player.has_node('Invisibility'):
		player.add_child(preload("res://scenes/power_attachments/Invisibility.tscn").instantiate())
