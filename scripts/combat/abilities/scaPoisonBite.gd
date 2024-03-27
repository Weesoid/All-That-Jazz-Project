static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Attack')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')

static func applyEffects(_caster: ResCombatant, target: ResCombatant, animation_scene):
	CombatGlobals.playAbilityAnimation(target, animation_scene)
	CombatGlobals.addStatusEffect(target, 'Poison', true, 0.95)
