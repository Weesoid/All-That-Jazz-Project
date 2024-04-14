static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Cast')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(caster: ResCombatant, targets, animation_scene):
	if targets is Array:
		for target in targets:
			CombatGlobals.playAbilityAnimation(target, animation_scene)
			CombatGlobals.calculateDamage(caster, target, 999)
	else:
		CombatGlobals.playAbilityAnimation(targets, animation_scene)
		CombatGlobals.calculateDamage(caster, targets, 999)
