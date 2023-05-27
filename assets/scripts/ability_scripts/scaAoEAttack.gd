static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Attack')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(caster: ResCombatant, targets, animation_scene):
	for target in targets:
		CombatGlobals.playSingleTargetAnimation(target, animation_scene)
		CombatGlobals.calculateDamage(caster, target, 'brawn', 'grit', 4, 0.75)
		await animation_scene.get_node('AnimationPlayer').animation_finished
		
	CombatGlobals.emit_ability_executed()
	
