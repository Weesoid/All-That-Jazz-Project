static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.apply_once:
		var damage = (target.stat_values['health'] * 0.025) + 1
		CombatGlobals.calculateRawDamage(target, CombatGlobals.useDamageFormula(target, damage))
		CombatGlobals.modifyStat(target, {'grit': -0.01}, status_effect.name)

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.resetStat(target, status_effect.name)
