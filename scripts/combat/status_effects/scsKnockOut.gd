static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.APPLY_ONCE and !target.hasStatusEffect('Deathmark'):
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
		applyFaded(target)
		target.SCENE.playIdle('Idle')
	CombatGlobals.resetStat(target, status_effect.NAME)

static func applyFaded(target: ResCombatant):
	if target.hasStatusEffect('Faded I'):
		target.LINGERING_STATUS_EFFECTS.erase('Faded I')
		CombatGlobals.removeStatusEffect(target, 'Faded I')
		CombatGlobals.addStatusEffect(target, 'FadedII')
	elif target.hasStatusEffect('Faded II'):
		target.LINGERING_STATUS_EFFECTS.erase('Faded II')
		CombatGlobals.removeStatusEffect(target, 'Faded II')
		CombatGlobals.addStatusEffect(target, 'FadedIII')
	elif target.hasStatusEffect('Faded III'):
		target.LINGERING_STATUS_EFFECTS.erase('Faded III')
		CombatGlobals.removeStatusEffect(target, 'Faded III')
		CombatGlobals.addStatusEffect(target, 'FadedIV')
	elif !target.hasStatusEffect('Faded IV'):
		CombatGlobals.addStatusEffect(target, 'FadedI')
	else:
		CombatGlobals.addStatusEffect(target, 'Faded I')
