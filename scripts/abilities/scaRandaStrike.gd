static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Attack')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(caster: ResCombatant, targets, animation_scene):
	for i in range(3):
		targets.shuffle()
		var target = targets.pick_random()
		var animation = animation_scene.instantiate()
		animation.playAnimation(target.SCENE.global_position)
		CombatGlobals.calculateDamage(caster, target, 'brawn', 'grit',  2, 0.5, CombatGlobals.loadDamageType('Neutral'))
		await animation_scene.get_node('AnimationPlayer').animation_finished
		
	CombatGlobals.emit_ability_executed()
