static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.modifyStat(target, {'hustle': -999}, status_effect.NAME)
	if CombatGlobals.getCombatScene().active_combatant == target and CombatGlobals.getCombatScene().turn_count > 1:
		CombatGlobals.manual_call_indicator.emit(target, 'Dazed!', 'Show')
		status_effect.removeStatusEffect()

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.resetStat(target, status_effect.NAME)
