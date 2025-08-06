static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.apply_once:
		target.combatant_scene.moveTo(target.combatant_scene.get_parent(), 0.25, Vector2(0,0), true)
		CombatGlobals.modifyStat(target, {'speed': -999}, status_effect.name)
		CombatGlobals.playKnockOutTween(target)
		target.combatant_scene.collision.set_deferred('disabled',true)
		if target is ResPlayerCombatant:
			if target.combatant_scene.weapon != null: target.combatant_scene.weapon.hide()
		target.combatant_scene.playIdle('KO')

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if CombatGlobals.getCombatScene().combat_result >= 1 and (target is ResPlayerCombatant and target.mandatory): 
		CombatGlobals.calculateHealing(target, int(target.base_stat_values['health']*0.25))
		CombatGlobals.playSecondWindTween(target)
		target.combatant_scene.playIdle('Idle')
		CombatGlobals.applyFaded(target)
	elif CombatGlobals.getCombatScene().combat_result == 0:
		CombatGlobals.applyFaded(target)
	CombatGlobals.resetStat(target, status_effect.name)
