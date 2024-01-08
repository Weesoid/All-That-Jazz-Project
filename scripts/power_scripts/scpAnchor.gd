static func executePower(player: PlayerScene):
	Input.action_release("ui_gambit")
	if !OverworldGlobals.getCurrentMap().has_node("patAnchor") and !player.channeling_power:
		player.channeling_power = true
		player.playCastAnimation()
		await player.cast_animator.animation_finished
		var anchor: Node2D = load("res://scenes/power_attachments/Anchor.tscn").instantiate()
		anchor.global_position = player.global_position
		OverworldGlobals.getCurrentMap().add_child(anchor)
		player.channeling_power = false
