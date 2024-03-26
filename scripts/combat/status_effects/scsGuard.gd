static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.APPLY_ONCE:
		status_effect.attached_data = CombatGlobals.getCombatScene().active_combatant
		status_effect.DESCRIPTION = 'Target is being guarded by %s' % status_effect.attached_data

static func applyHitEffects(target: ResCombatant, caster:ResCombatant, value, status_effect: ResStatusEffect):
	CombatGlobals.calculateHealing(target, value)
	CombatGlobals.calculateRawDamage(status_effect.attached_data, value)

static func endEffects(_target: ResCombatant, _status_effect: ResStatusEffect):
	pass
