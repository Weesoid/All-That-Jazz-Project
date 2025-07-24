static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.apply_once:
		CombatGlobals.modifyStat(target, {'accuracy': -0.75}, status_effect.NAME)
		CombatGlobals.manual_call_indicator.emit(target, 'Disrupted!', 'Reaction')

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.resetStat(target, status_effect.NAME)
