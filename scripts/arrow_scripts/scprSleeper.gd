static func applyEffect(body: CharacterBody2D):
	OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]Morale[/color] increased!')
	body.get_node("NPCPatrolComponent").COMBAT_SQUAD.getExperience()
	body.get_node("NPCPatrolComponent").destroy()
