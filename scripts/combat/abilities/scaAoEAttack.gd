static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Cast')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(caster: ResCombatant, targets, animation_scene):
	for target in targets:
		CombatGlobals.playAbilityAnimation(target, animation_scene, 0.25)
		CombatGlobals.calculateDamage(caster, target, 5)
		await CombatGlobals.animation_done
