static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.APPLY_ONCE:
		var damage = target.BASE_STAT_VALUES['health'] * 0.05
		CombatGlobals.manual_call_indicator.emit(target, str(int(damage), ' SINGED!'), 'Show')
		CombatGlobals.calculateRawDamage(target, damage)
		CombatGlobals.modifyStatFlat(target, 'heal mult', -0.75)

static func endEffects(target: ResCombatant):
	CombatGlobals.resetStat(target, 'heal mult')
