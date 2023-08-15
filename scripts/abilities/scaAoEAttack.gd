static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Attack')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(caster: ResCombatant, targets, animation_scene):
	for target in targets:
		var animation = animation_scene.instantiate()
		target.SCENE.add_child(animation)
		animation.playAnimation(target.SCENE.position)
		CombatGlobals.calculateDamage(caster, target, 'brawn', 'grit', 4, 0.75, CombatGlobals.loadDamageType('Neutral'))
		
	CombatGlobals.emit_ability_executed()
	
