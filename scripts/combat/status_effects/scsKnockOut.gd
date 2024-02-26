static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.modifyStat(target, {'hustle': -100}, status_effect.NAME)
	

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	print('KO removed!')
	CombatGlobals.resetStat(target, status_effect.NAME)
