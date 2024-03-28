static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Attack')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(_caster: ResCombatant, targets, animation_scene):
	for i in range(3):
		targets.shuffle()
		var target = targets.pick_random()
		CombatGlobals.playAbilityAnimation(target, animation_scene)
		CombatGlobals.calculateRawDamage(target, 25.0)
	
