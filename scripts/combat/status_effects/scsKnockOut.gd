static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.APPLY_ONCE and !target.hasStatusEffect('Deathmark'):
		OverworldGlobals.showQuickAnimation("res://scenes/animations/SkullKill.tscn", target.SCENE.global_position)
		target.SCENE.moveTo(target.SCENE.get_parent(), 0.25, Vector2(0,0), true)
		CombatGlobals.modifyStat(target, {'hustle': -999}, status_effect.NAME)
		target.SCENE.playIdle('KO')
		CombatGlobals.playKnockOutTween(target)
		target.SCENE.collision.disabled = true
		if target is ResPlayerCombatant:
			if target.SCENE.weapon != null: target.SCENE.weapon.hide()

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if CombatGlobals.getCombatScene().combat_result >= 1 and (target is ResPlayerCombatant and target.MANDATORY): 
		CombatGlobals.calculateHealing(target, int(target.BASE_STAT_VALUES['health']*0.25))
		CombatGlobals.playSecondWindTween(target)
		target.SCENE.playIdle('Idle')
	CombatGlobals.resetStat(target, status_effect.NAME)
