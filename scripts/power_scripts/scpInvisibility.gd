static func executePower(player: PlayerScene):
	if !player.has_node('Invisibility'):
		player.toggleVoidAnimation(true)
		player.add_child(preload("res://scenes/power_attachments/Invisibility.tscn").instantiate())
	else:
		print('Founded!')
		player.get_node('Invisibility').setVisible()
