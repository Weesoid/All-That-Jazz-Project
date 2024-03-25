static func applyEffects(target: ResCombatant, _status_effect: ResStatusEffect):
	CombatGlobals.manual_call_indicator.emit(target, 'JOLTED!', 'Show')
	CombatGlobals.addStatusEffect(target, 'Dazed')

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.resetStat(target, status_effect.NAME)
	CombatGlobals.calculateRawDamage(target, target.BASE_STAT_VALUES['health'] * 0.05)
