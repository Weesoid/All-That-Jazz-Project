static func applyEffect(body: CharacterBody2D):
	print('x')
	OverworldGlobals.getCurrentMap().REWARD_BANK['experience'] += body.get_node("NPCPatrolComponent").COMBAT_SQUAD.getExperience()
	body.get_node("NPCPatrolComponent").COMBAT_SQUAD.addDrops()
	body.get_node("NPCPatrolComponent").destroy()
