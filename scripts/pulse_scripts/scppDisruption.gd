static func applyEffect(body):
	if body.has_node('CombatantSquadComponent'):
		var component: CombatantSquad = body.get_node('CombatantSquadComponent')
		component.addLingeringEffect('Disrupted')
		OverworldGlobals.showAbilityAnimation('res://scenes/animations/Disruption.tscn', body)
