static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Attack')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(caster: ResCombatant, targets, animation_scene):
	for i in range(3):
		targets.shuffle()
		var target = targets.pick_random()
		CombatGlobals.playSingleTargetAnimation(target, animation_scene)
		CombatGlobals.calculateDamage(caster, target, 'brawn', 'grit',  2, 0.5)
		await animation_scene.get_node('AnimationPlayer').animation_finished
		
	CombatGlobals.emit_ability_executed()
