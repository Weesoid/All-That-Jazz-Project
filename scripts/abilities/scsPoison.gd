static func applyEffects(target: ResCombatant, _status_effect: ResStatusEffect):
	var damage = (target.STAT_VALUES['health'] * 0.05) + 1
	target.STAT_VALUES['health'] -= int(damage)

static func endEffects(_target: ResCombatant):
	pass
