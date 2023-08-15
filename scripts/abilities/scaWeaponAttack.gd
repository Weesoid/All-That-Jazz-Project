static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Attack')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(caster: ResCombatant, target: ResCombatant, animation_scene):
	var animation = animation_scene.instantiate()
	target.SCENE.add_child(animation)
	animation.playAnimation(target.SCENE.position)
	CombatGlobals.calculateDamage(caster, target, 'brawn', 'grit', 10, 0.5, CombatGlobals.loadDamageType('Neutral'))
	
	CombatGlobals.ability_executed.emit()
	
