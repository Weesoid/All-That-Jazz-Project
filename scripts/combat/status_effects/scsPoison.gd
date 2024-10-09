static func applyEffects(target: ResCombatant, _status_effect: ResStatusEffect):
	var damage = (target.STAT_VALUES['health'] * 0.05) + 1
	CombatGlobals.calculateRawDamage(target, CombatGlobals.useDamageFormula(target, damage))

static func endEffects(_target: ResCombatant, _status_effect: ResStatusEffect):
	pass
