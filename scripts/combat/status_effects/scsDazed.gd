static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.modifyStat(target, {'hustle': -100}, status_effect.NAME)
	#endEffects(target, status_effect)

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.manual_call_indicator.emit(target, 'DAZED!', 'Show')
	CombatGlobals.resetStat(target, status_effect.NAME)
