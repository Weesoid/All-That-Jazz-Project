static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Attack')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')

static func applyEffects(caster: ResCombatant, target, animation_scene):
	# Visual Feedback
	for combatant in target:
		CombatGlobals.playAbilityAnimation(combatant, animation_scene)
		CombatGlobals.calculateHealing(caster, combatant, 'wit', 100, 0.6)
	

static func applyOverworldEffects(caster: ResCombatant, target, _animation_scene):
	for combatant in target:
		CombatGlobals.calculateHealing(caster, combatant, 'wit', 100, 0.6)

