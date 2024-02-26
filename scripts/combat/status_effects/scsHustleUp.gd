static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.APPLY_ONCE:
		CombatGlobals.modifyStat(target, {'hustle': 1 * status_effect.current_rank}, status_effect.NAME)
		CombatGlobals.manual_call_indicator.emit(target, 'HUSTLE UP!', 'Show')

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.resetStat(target, status_effect.NAME)
