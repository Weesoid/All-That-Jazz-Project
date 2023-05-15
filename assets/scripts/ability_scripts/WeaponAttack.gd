extends Node

static func applyEffects(caster: Combatant, target: Combatant):
	target.STAT_HEALTH = target.STAT_HEALTH - caster.STAT_BRAWN

