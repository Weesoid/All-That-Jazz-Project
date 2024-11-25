static func applyEffect(body: CharacterBody2D):
	if body.has_node("NPCPatrolComponent"):
		if CombatGlobals.randomRoll(0.75):
			body.get_node("NPCPatrolComponent").updateMode(3, true)
		elif body.get_node("NPCPatrolComponent").STATE == 0:
			body.get_node("NPCPatrolComponent").updateMode(1, true)
