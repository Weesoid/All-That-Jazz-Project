static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.APPLY_ONCE:
		CombatGlobals.manual_call_indicator.emit(target, 'DEATH MARK', 'Lingering')
		target.getStatusEffect('Fading').duration += 3
#	if CombatGlobals.getCombatScene().active_combatant == target and CombatGlobals.getCombatScene().turn_count > 1:
#		CombatGlobals.manual_call_indicator.emit(target, 'Mark!', 'Heal')
#		status_effect.removeStatusEffect()

static func endEffects(_target: ResCombatant, _status_effect: ResStatusEffect):
	pass
