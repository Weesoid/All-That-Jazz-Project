static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.apply_once:
		applyFadedEffects(target, status_effect)

static func endEffects(target: ResCombatant, _status_effect: ResStatusEffect):
	CombatGlobals.resetStat(target, 'Faded')

static func applyFadedEffects(target: ResCombatant, status_effect: ResStatusEffect):
	match status_effect.name:
		'Faded I':
			CombatGlobals.modifyStat(target, {'heal_mult': -0.25}, 'Faded')
		'Faded II':
			CombatGlobals.modifyStat(target, {'heal_mult': -0.5, 'resist': -0.1}, 'Faded')
		'Faded III':
			CombatGlobals.modifyStat(target, {'heal_mult': -0.75, 'resist': -0.2, 'accuracy': -0.1}, 'Faded')
		'Faded IV':
			CombatGlobals.modifyStat(target, {'heal_mult': -0.75, 'resist': -0.2, 'accuracy': -0.2, 'crit': -0.2}, 'Faded')
