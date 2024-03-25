static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.modifyStat(target, {'hustle': -100}, status_effect.NAME)
	CombatGlobals.playAnimation(target, 'KO')

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.resetStat(target, status_effect.NAME)
