static func executePower(player: PlayerScene):
	Input.action_release("ui_gambit")
	if !OverworldGlobals.getCurrentMap().has_node("patAnchor"):
		var anchor: Node2D = load("res://scenes/power_attachments/Anchor.tscn").instantiate()
		anchor.global_position = player.global_position
		OverworldGlobals.getCurrentMap().add_child(anchor)
		
	
