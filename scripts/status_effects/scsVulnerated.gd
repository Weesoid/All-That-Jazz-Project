static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	# Fix bug, it goes to negative
	var modifier = -0.2
	if status_effect.APPLY_ONCE:
		modifier *= status_effect.current_rank
		CombatGlobals.modifyStat(target, 'grit', modifier)
		CombatGlobals.manual_call_indicator.emit(target, 'VULNERATED!', 'Show')
	print('Armor is ', target.STAT_VALUES['grit'])
	
static func endEffects(target: ResCombatant):
	CombatGlobals.resetStat(target, 'grit')
