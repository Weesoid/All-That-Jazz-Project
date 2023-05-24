static func animateCast(caster: Combatant):
	caster.getAnimator().play('Attack')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(caster: Combatant, target: Combatant, animation_scene):
	# Visual Feedback
	CombatGlobals.playSingleTargetAnimation(target, animation_scene)
	CombatGlobals.calculateHealing(caster, target, 10, 0.6)
	await animation_scene.get_node('AnimationPlayer').animation_finished
	CombatGlobals.emit_ability_executed()
