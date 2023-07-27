static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	# Fix bug, it goes to negative
	var modifier = 0.25
	if status_effect.APPLY_ONCE:
		modifier = modifier * status_effect.current_rank
		CombatGlobals.modifyStat(target, 'brawn', modifier)

static func endEffects(target: ResCombatant):
	CombatGlobals.resetStat(target, 'brawn')
