static func applyEffects(target: ResCombatant, _status_effect: ResStatusEffect):
		CombatGlobals.manual_call_indicator.emit(target, 'JOLTED!', 'Show')
		target.STAT_VALUES['hustle'] = -1

static func endEffects(target: ResCombatant):
	CombatGlobals.resetStat(target, 'hustle')
