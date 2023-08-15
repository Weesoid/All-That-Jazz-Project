static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.APPLY_ONCE:
		CombatGlobals.modifyStatFlat(target, 'accuracy', -0.75)
		CombatGlobals.manual_call_indicator.emit(target, 'Disrupted!', 'Reaction')

static func endEffects(target: ResCombatant):
	CombatGlobals.resetStat(target, 'accuracy')
