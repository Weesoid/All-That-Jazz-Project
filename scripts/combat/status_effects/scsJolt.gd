static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.APPLY_ONCE:
		CombatGlobals.manual_call_indicator.emit(target, 'JOLTED!', 'Show')
		CombatGlobals.addStatusEffect(target, 'Dazed')

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.resetStat(target, status_effect.NAME)
	CombatGlobals.manual_call_indicator.emit(target, 'DISCHARGED!', 'Show')
	CombatGlobals.calculateRawDamage(target, target.BASE_STAT_VALUES['health'] * 0.05)
