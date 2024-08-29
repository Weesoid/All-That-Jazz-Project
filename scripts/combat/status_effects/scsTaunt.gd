static func applyEffects(_target: ResCombatant, _status_effect: ResStatusEffect):
	pass

static func applyHitEffects(_target: ResCombatant, _caster:ResCombatant, _value, status_effect: ResStatusEffect):
	status_effect.duration = 0
	status_effect.tick()

static func endEffects(_target: ResCombatant, _status_effect: ResStatusEffect):
	pass
