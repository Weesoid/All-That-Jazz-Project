static func applyEffects(_target, _status_effect):
	pass

static func applyHitEffects(target, _caster, _value, status_effect):
	if CombatGlobals.randomRoll(0.7 - target.STAT_VALUES['resist']):
		CombatGlobals.rankUpStatusEffect(target, status_effect)

static func endEffects(_target, _status_effect: ResStatusEffect):
	pass
