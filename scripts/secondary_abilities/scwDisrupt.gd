static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Cast')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(_caster: ResCombatant, targets, animation_scene):
	for target in targets:
		CombatGlobals.playAbilityAnimation(target, animation_scene)
		CombatGlobals.addStatusEffect(target, preload("res://resources/status_effects/Disrupted.tres").duplicate())
		CombatGlobals.manual_call_indicator.emit(target, 'DISRUPTED!', 'Reaction')
	
	
