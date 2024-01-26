static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.APPLY_ONCE:
		var damage = target.BASE_STAT_VALUES['health'] * 0.05
		CombatGlobals.calculateRawDamage(target, damage, 
										true, null, 1.0, 
										false, -1.0, null, 
										"SINGED")
		CombatGlobals.modifyStatFlat(target, 'heal mult', -0.75)

static func endEffects(target: ResCombatant):
	CombatGlobals.resetStat(target, 'heal mult')
