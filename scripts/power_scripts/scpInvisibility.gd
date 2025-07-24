static func executePower(player: PlayerScene):
	if !player.has_node('Invisibility') and PlayerGlobals.overworld_stats['stamina'] >= 50:
		player.playCastAnimation()
		player.add_child(preload("res://scenes/power_attachments/Invisibility.tscn").instantiate())
	elif PlayerGlobals.overworld_stats['stamina'] < 50:
		OverworldGlobals.showPrompt('Not enough [color=yellow]stamina[/color].')
