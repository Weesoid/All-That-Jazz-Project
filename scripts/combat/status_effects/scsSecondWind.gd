static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.APPLY_ONCE:
		CombatGlobals.modifyStat(target, {'grit': 1.0}, status_effect.NAME)
		CombatGlobals.manual_call_indicator.emit(target, 'Second Wind!', 'Show')

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.resetStat(target, status_effect.NAME)
