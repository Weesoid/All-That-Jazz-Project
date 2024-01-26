static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Attack')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(caster: ResCombatant, targets, animation_scene):
	for target in targets:
		CombatGlobals.playAbilityAnimation(target, animation_scene, 0.25)
		CombatGlobals.calculateDamage(caster, target, 'brawn', 'grit', 4, 0.75, 'Neutral')
		await CombatGlobals.animation_done
