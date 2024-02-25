static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	# Fix bug, it goes to negative
	var modifier = 0.25
	if status_effect.APPLY_ONCE:
		modifier += status_effect.current_rank
		CombatGlobals.modifyStatFlat(target, 'brawn', modifier)
		CombatGlobals.manual_call_indicator.emit(target, 'BUFF UP!', 'Show')

static func endEffects(target: ResCombatant):
	CombatGlobals.resetStat(target, 'brawn')
