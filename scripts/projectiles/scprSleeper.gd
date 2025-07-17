static func applyEffect(body: CharacterBody2D):
	OverworldGlobals.getCurrentMap().REWARD_BANK['experience'] += body.get_node("CombatantSquadComponent").getExperience()
	body.get_node("CombatantSquadComponent").addDrops()
	body.destroy()
