static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.APPLY_ONCE:
		CombatGlobals.modifyStat(target, 'heal mult', -0.75)

static func endEffects(target: ResCombatant):
	CombatGlobals.resetStat(target, 'heal mult')
