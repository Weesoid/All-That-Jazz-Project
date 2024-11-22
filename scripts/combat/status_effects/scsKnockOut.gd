static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.APPLY_ONCE and !target.hasStatusEffect('Deathmark'):
		target.SCENE.moveTo(target.SCENE.get_parent(), 0.25, Vector2(0,0), true)
		CombatGlobals.modifyStat(target, {'hustle': -100}, status_effect.NAME)
		target.SCENE.playIdle('KO')
		CombatGlobals.playKnockOutTween(target)
		target.SCENE.collision.disabled = true
		if target is ResPlayerCombatant:
			if target.SCENE.weapon != null: target.SCENE.weapon.hide()

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.resetStat(target, status_effect.NAME)
