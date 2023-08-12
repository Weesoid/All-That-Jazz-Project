static func applyEffects(target: ResCombatant, _status_effect: ResStatusEffect):
	var damage = (target.STAT_VALUES['health'] * 0.05) + 1
	CombatGlobals.manual_call_indicator.emit(target, str(int(damage), ' POISONED!'), 'Show')
	target.STAT_VALUES['health'] -= int(damage)


static func endEffects(_target: ResCombatant):
	pass
