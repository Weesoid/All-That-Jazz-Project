static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Cast')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(caster: ResCombatant, target: ResCombatant, animation_scene):
	CombatGlobals.playAbilityAnimation(target, animation_scene)
	if CombatGlobals.calculateDamage(caster, target, 20):
		CombatGlobals.addStatusEffect(target, 'Singed')
