static func applyEffects(target: ResCombatant, caster:ResCombatant, value, status_effect: ResStatusEffect):
	CombatGlobals.calculateRawDamage(target, target.STAT_VALUE['health']*0.15)
	status_effect.removeStatusEffect()

static func endEffects(_target: ResCombatant):
	pass

