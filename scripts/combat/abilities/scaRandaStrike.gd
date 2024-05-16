static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Cast')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(_caster: ResCombatant, targets, animation_scene):
	for i in targets:
		CombatGlobals.playAbilityAnimation(i, animation_scene)
		CombatGlobals.calculateRawDamage(i, 999.0)
