static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Cast')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(_caster: ResCombatant, target, animation_scene):
	CombatGlobals.playAbilityAnimation(target, animation_scene)
	CombatGlobals.addStatusEffect(target, 'Vulnerate')
	CombatGlobals.manual_call_indicator.emit(target, 'VULNERATED!', 'Reaction')
	
	
