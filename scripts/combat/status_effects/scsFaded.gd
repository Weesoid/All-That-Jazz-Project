static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.APPLY_ONCE:
		applyFaded(target, status_effect)
		#CombatGlobals.manual_call_indicator.emit(target, 'Disrupted!', 'Reaction')

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.resetStat(target, 'Faded')

static func applyFaded(target: ResCombatant, status_effect: ResStatusEffect):
	match status_effect.NAME:
		'Faded I':
			CombatGlobals.modifyStat(target, {'heal mult': -0.25}, 'Faded')
		'Faded II':
			CombatGlobals.modifyStat(target, {'heal mult': -0.5, 'resist': -0.1}, 'Faded')
		'Faded III':
			CombatGlobals.modifyStat(target, {'heal mult': -0.75, 'resist': -0.2, 'accuracy': -0.1}, 'Faded')
		'Faded IV':
			CombatGlobals.modifyStat(target, {'heal mult': -100.0, 'resist': -0.5, 'accuracy': -0.2, 'crit': -0.5}, 'Faded')
