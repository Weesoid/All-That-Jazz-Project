static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.APPLY_ONCE:
		CombatGlobals.manual_call_indicator.emit(target, 'JOLTED!', 'Show')
		target.STAT_VALUES['hustle'] = -1

static func endEffects(target: ResCombatant):
	CombatGlobals.resetStat(target, 'hustle')
