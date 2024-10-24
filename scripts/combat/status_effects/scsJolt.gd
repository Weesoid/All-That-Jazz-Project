static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.APPLY_ONCE:
		CombatGlobals.manual_call_indicator.emit(target, 'JOLTED!', 'Show')
		CombatGlobals.addStatusEffect(target, 'Dazed', true)
	if status_effect.duration == 5:
		CombatGlobals.manual_call_indicator.emit(target, 'OVERCHARGED!', 'Show')

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.resetStat(target, status_effect.NAME)
	var damage = (target.STAT_VALUES['health'] * 0.05) * status_effect.duration
	CombatGlobals.calculateRawDamage(target, CombatGlobals.useDamageFormula(target, damage))
