static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	print(status_effect.APPLY_ONCE)
	if status_effect.APPLY_ONCE:
		var damage = target.STAT_VALUES['health'] * 0.1
		CombatGlobals.calculateRawDamage(target, CombatGlobals.useDamageFormula(target, damage))
		CombatGlobals.modifyStat(target, {'heal mult': -0.75}, status_effect.NAME)

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.resetStat(target, status_effect.NAME)
