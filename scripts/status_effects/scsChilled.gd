static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.APPLY_ONCE:
		var damage = target.BASE_STAT_VALUES['health'] * 0.025
		CombatGlobals.manual_call_indicator.emit(target, str(int(damage), ' CHILLED!'), 'Show')
		target.STAT_VALUES['health'] -= int(damage)
		CombatGlobals.modifyStatFlat(target, 'grit', -1)

static func endEffects(target: ResCombatant):
	CombatGlobals.resetStat(target, 'grit')
