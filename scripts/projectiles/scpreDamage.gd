static func applyEffect(body: CharacterBody2D):
	OverworldGlobals.damageParty(8, ['Shot dead!', "Why didn't you dodge?!"], false)
	if body.climbing:
		body.climb_cooldown.start()
		body.climbing = false
		OverworldGlobals.getPlayer().jump()
		OverworldGlobals.getPlayer().toggleClimbAnimation(false)
		if !OverworldGlobals.getPlayer().get_collision_mask_value(1):
			OverworldGlobals.getPlayer().set_collision_mask_value(1, true)
