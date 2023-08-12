static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Attack')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(caster: ResCombatant, target: ResCombatant, animation_scene):
	CombatGlobals.playSingleTargetAnimation(target, animation_scene)
	
	CombatGlobals.calculateDamage(caster, target, 'brawn', 'grit', 10, 0.5, CombatGlobals.loadDamageType('Edged'))
	
	await animation_scene.get_node('AnimationPlayer').animation_finished
	CombatGlobals.emit_ability_executed()
	
