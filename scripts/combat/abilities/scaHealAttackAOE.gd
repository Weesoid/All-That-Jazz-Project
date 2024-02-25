static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Attack')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')

static func applyEffects(caster: ResCombatant, target, animation_scene):
	# Visual Feedback
	for combatant in target:
		CombatGlobals.playAbilityAnimation(combatant, animation_scene, 0.25)
		CombatGlobals.calculateHealing(caster, combatant, 'grit', 10.0)
		await CombatGlobals.animation_done

static func applyOverworldEffects(caster: ResCombatant, target, _animation_scene):
	for combatant in target:
		CombatGlobals.calculateHealing(caster, target, 'grit', 10.0)
