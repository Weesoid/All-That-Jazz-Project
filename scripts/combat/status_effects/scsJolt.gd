static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.apply_once:
		CombatGlobals.manual_call_indicator.emit(target, 'JOLTED!', 'Show')
		CombatGlobals.addStatusEffect(target, 'Stunned')
	if status_effect.duration >= 5:
		CombatGlobals.manual_call_indicator.emit(target, 'OVERCHARGED!', 'Show')
		status_effect.removeStatusEffect()

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.resetStat(target, status_effect.name)
	var damage = 2 * status_effect.duration
	CombatGlobals.calculateRawDamage(target, CombatGlobals.useDamageFormula(target, damage))
