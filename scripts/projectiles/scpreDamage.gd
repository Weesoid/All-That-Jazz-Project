static func applyEffect(body: CharacterBody2D):
	OverworldGlobals.damageParty(5, ['Shot dead!', "Why didn't you dodge?!"], false)
	if body.climbing:
		# Turn to func later
		body.climb_cooldown.start()
		body.climbing = false
		OverworldGlobals.player.jump()
		OverworldGlobals.player.toggleClimbAnimation(false)
		if !OverworldGlobals.player.get_collision_mask_value(1):
			OverworldGlobals.player.set_collision_mask_value(1, true)
