static func applyEffects(_target: ResCombatant, caster:ResCombatant, value, _status_effect: ResStatusEffect):
	var damage = value
	CombatGlobals.manual_call_indicator.emit(caster, "%s SPIKED!!" % [str(damage)], 'Show')
	CombatGlobals.calculateRawDamage(caster, damage)

static func endEffects(_target: ResCombatant):
	pass
