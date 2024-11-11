static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.calculateRawDamage(target, 2 * status_effect.current_rank)

static func endEffects(_target: ResCombatant, _status_effect: ResStatusEffect):
	pass
