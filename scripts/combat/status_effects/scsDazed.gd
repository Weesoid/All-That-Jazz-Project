static func applyEffects(target: ResCombatant, _status_effect: ResStatusEffect):
	CombatGlobals.manual_call_indicator.emit(target, 'DAZED!', 'Show')
	CombatGlobals.modifyStat(target, 'grit', -0.5)
	CombatGlobals.modifyStatFlat(target, 'exposure', 0.5)
	target.STAT_VALUES['hustle'] = -1

static func endEffects(target: ResCombatant):
	CombatGlobals.resetStat(target, 'grit')
	CombatGlobals.resetStat(target, 'exposure')
	CombatGlobals.resetStat(target, 'hustle')
