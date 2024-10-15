static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.APPLY_ONCE:
		CombatGlobals.modifyStat(target, {'hustle': -100}, status_effect.NAME)
		CombatGlobals.playAnimation(target, 'KO')
		CombatGlobals.playKnockOutTween(target)
		target.SCENE.collision.disabled = true
		if target is ResPlayerCombatant:
			if target.SCENE.weapon != null: target.SCENE.weapon.hide()

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.resetStat(target, status_effect.NAME)
