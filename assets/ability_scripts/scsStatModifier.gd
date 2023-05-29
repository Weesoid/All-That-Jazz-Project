static func animateEffect(caster):
	pass
	
static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	var modifier = 0.50
	if status_effect.APPLY_ONCE:
		modifier = modifier * status_effect.current_rank
		CombatGlobals.modifyStat(target, 'brawn', modifier)
	
static func endEffects(target: ResCombatant):
	CombatGlobals.resetStat(target, 'brawn')
	
