static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.modifyStat(target, {'speed': -999}, status_effect.name)
	if !target.hasStatusEffect('Poised') and status_effect.apply_once:
		OverworldGlobals.playSound("res://audio/sounds/39_Block_03.ogg")
	if target.hasStatusEffect('Poised'):
		status_effect.removeStatusEffect()
#	elif CombatGlobals.getCombatScene().active_combatant == target and CombatGlobals.getCombatScene().turn_count > 1:
#		status_effect.removeStatusEffect()


static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.resetStat(target, status_effect.name)
	if !target.hasStatusEffect('Poised'):
		CombatGlobals.addStatusEffect(target, 'Poised')
	else:
		target.getStatusEffect('Poised').duration -= 1
		if target.getStatusEffect('Poised').duration <= 0:
			target.getStatusEffect('Poised').removeStatusEffect()
