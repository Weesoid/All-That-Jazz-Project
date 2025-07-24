static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	# Fix bug, it goes to negative
	if status_effect.apply_once:
		CombatGlobals.modifyStat(target, {'grit': -0.05 * status_effect.current_rank}, status_effect.NAME)
		CombatGlobals.manual_call_indicator.emit(target, 'VULNERATED!', 'Show')
	
static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.resetStat(target, status_effect.NAME)
