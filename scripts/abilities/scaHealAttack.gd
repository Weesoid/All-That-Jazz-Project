static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Attack')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')

static func applyEffects(caster: ResCombatant, target: ResCombatant, animation_scene):
	# Visual Feedback
	var animation = animation_scene.instantiate()
	animation.playAnimation(target.SCENE.global_position)
	CombatGlobals.calculateHealing(caster, target, 'wit', 10, 0.6)
	await animation_scene.get_node('AnimationPlayer').animation_finished
	CombatGlobals.emit_ability_executed()

static func applyOverworldEffects(caster: ResCombatant, target: ResCombatant, _animation_scene):
	CombatGlobals.calculateHealing(caster, target, 'wit', 10, 0.6)
