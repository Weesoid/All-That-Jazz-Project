static func applyEffect(body: CharacterBody2D):
	if body.has_node('CombatInteractComponent'):
		OverworldGlobals.getCurrentMap().REWARD_BANK['experience'] += body.get_node("NPCPatrolComponent").COMBAT_SQUAD.getExperience()
		body.get_node("NPCPatrolComponent").COMBAT_SQUAD.addDrops()
		body.get_node("NPCPatrolComponent").destroy()
	else:
		var combat_interact = preload("res://scenes/components/CombatInteract.tscn").instantiate()
		combat_interact.patroller_name = body.get_node("NPCPatrolComponent").NAME
		body.call_deferred('add_child', combat_interact)
		body.get_node("NPCPatrolComponent").updateMode(3, true)
