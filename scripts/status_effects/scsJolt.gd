static func applyEffects(target: ResCombatant, _status_effect: ResStatusEffect):
	target.STAT_VALUES['hustle'] = -1
	CombatGlobals.manual_call_indicator.emit(target, 'JOLTED!', 'Show')

static func endEffects(target: ResCombatant):
	var damage = target.BASE_STAT_VALUES['health'] * 0.05
	CombatGlobals.calculateRawDamage(target, damage, 
									true, null, 0.25, 
									false, -1.0, null, 
									"DISCHARGE!")
	CombatGlobals.resetStat(target, 'hustle')
