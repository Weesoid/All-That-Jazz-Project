static func applyEffects(target: ResCombatant, _status_effect: ResStatusEffect):
	CombatGlobals.manual_call_indicator.emit(target, 'DAZED!', 'Show')
	target.STAT_VALUES['hustle'] = -1

static func endEffects(target: ResCombatant):
	print('Removed! Hehe!')
