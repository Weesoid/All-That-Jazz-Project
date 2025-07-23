static func executePower(player: PlayerScene):
	if !OverworldGlobals.getCurrentMap().has_node("Anchor") and !player.channeling_power and PlayerGlobals.overworld_stats['stamina']>= 15.0:
		PlayerGlobals.overworld_stats['stamina']-= 15
		player.channeling_power = true
		var anchor: Node2D = load("res://scenes/power_attachments/Anchor.tscn").instantiate()
		anchor.global_position = player.global_position
		OverworldGlobals.getCurrentMap().add_child(anchor)
		player.channeling_power = false
	elif OverworldGlobals.getCurrentMap().has_node("Anchor") and !player.channeling_power:
		var anchor = OverworldGlobals.getCurrentMap().get_node("Anchor")
		if PlayerGlobals.overworld_stats['stamina']>= 25.0 and !OverworldGlobals.inMenu() and !player.hiding:
			player.playCastAnimation()
			PlayerGlobals.overworld_stats['stamina']-= 25
			player.global_position = anchor.global_position
			OverworldGlobals.addPatrollerPulse(player, 80.0, 3)
			anchor.queue_free()
		else:
			player.prompt.('Not enough [color=yellow]stamina[/color].')
	else:
		player.prompt.('Not enough [color=yellow]stamina[/color].')
