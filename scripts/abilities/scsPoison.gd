static func applyEffects(target: ResCombatant, _status_effect: ResStatusEffect):
	var damage = (target.STAT_VALUES['health'] * 0.05) + 1
	target.STAT_VALUES['health'] -= int(damage)
	
	CombatGlobals.call_indicator.emit(target, 'Poisoned!', int(damage))
	target.updateHealth()

static func endEffects(_target: ResCombatant):
	pass
