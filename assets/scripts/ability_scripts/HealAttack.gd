static func animateCast(caster: Combatant):
	caster.getAnimator().play('Attack')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(caster: Combatant, target: Combatant, animation_scene):
	# Effects
	target.STAT_HEALTH = target.STAT_HEALTH + caster.STAT_WIT
	if (target.STAT_HEALTH > target.getSprite().get_node("HealthBar").max_value):
		target.STAT_HEALTH = target.getSprite().get_node("HealthBar").max_value
	
	# Visual Feedback
	target.playIndicator(str('+',caster.STAT_WIT))
	animation_scene.position = target.SCENE.global_position
	animation_scene.get_node('AnimationPlayer').play('Execute')
	target.updateHealth(target.STAT_HEALTH)
	
