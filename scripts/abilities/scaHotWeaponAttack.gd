static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Attack')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(caster: ResCombatant, target: ResCombatant, animation_scene):
	var animation = animation_scene.instantiate()
	animation.playAnimation(target.SCENE.global_position)
	CombatGlobals.calculateDamage(caster, target, 'brawn', 'grit', 10, 0.5, CombatGlobals.loadDamageType('Hot'))
	
	CombatGlobals.emit_ability_executed()
	
