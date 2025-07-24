static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.apply_once:
		CombatGlobals.modifyStat(target, {'hustle': 1 * status_effect.current_rank}, status_effect.name)
		CombatGlobals.manual_call_indicator.emit(target, 'HUSTLE UP!', 'Show')

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.resetStat(target, status_effect.name)
