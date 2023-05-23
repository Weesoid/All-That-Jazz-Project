static func animateCast(caster: Combatant):
	caster.getAnimator().play('Attack')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(caster: Combatant, target: Combatant, animation_scene):
	# Effects
	target.STAT_HEALTH = target.STAT_HEALTH - caster.STAT_BRAWN
	
	# Visual Feedback
	animation_scene.position = target.SCENE.global_position
	animation_scene.get_node('AnimationPlayer').play('Execute')
	target.playIndicator(caster.STAT_BRAWN)
	target.getAnimator().play('Hit')
	await target.getAnimator().animation_finished
	target.getAnimator().play('Idle')
	target.updateHealth(target.STAT_HEALTH)
