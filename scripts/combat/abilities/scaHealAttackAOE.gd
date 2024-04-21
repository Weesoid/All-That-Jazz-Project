static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Cast')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')

static func applyEffects(caster: ResCombatant, target, animation_scene):
	# Visual Feedback
	for combatant in target:
		CombatGlobals.playAbilityAnimation(combatant, animation_scene, 0.25)
		CombatGlobals.calculateHealing(caster, 10.0)
		await CombatGlobals.animation_done

static func applyOverworldEffects():
	for combatant in PlayerGlobals.TEAM:
		if combatant.active:
			CombatGlobals.calculateHealing(combatant, 50)
