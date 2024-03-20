static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.APPLY_ONCE:
		var damage = target.BASE_STAT_VALUES['health'] * 0.05
		CombatGlobals.calculateRawDamage(target, damage, 
										true, null, 1.0, 
										false, -1.0, null, 
										"SINGED")
		CombatGlobals.modifyStat(target, {'heal mult': -0.75}, status_effect.NAME)

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.resetStat(target, status_effect.NAME)
