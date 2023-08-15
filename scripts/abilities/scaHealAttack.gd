static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Attack')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')

static func applyEffects(caster: ResCombatant, target: ResCombatant, animation_scene):
	# Visual Feedback
	CombatGlobals.playAbilityAnimation(target, animation_scene)
	CombatGlobals.calculateHealing(caster, target, 'wit', 10, 0.6)
	

static func applyOverworldEffects(caster: ResCombatant, target: ResCombatant, _animation_scene):
	CombatGlobals.calculateHealing(caster, target, 'wit', 10, 0.6)
