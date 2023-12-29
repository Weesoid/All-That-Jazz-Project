static func applyEffects(target: ResCombatant, _status_effect: ResStatusEffect):
	target.STAT_VALUES['hustle'] = -1
	

static func endEffects(target: ResCombatant):
	CombatGlobals.resetStat(target, 'hustle')
	
