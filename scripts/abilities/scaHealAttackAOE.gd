static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Attack')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')

static func applyEffects(caster: ResCombatant, target, animation_scene):
	# Visual Feedback
	for combatant in target:
		var animation = animation_scene.instantiate()
		animation.playAnimation(target.SCENE.global_position)
		CombatGlobals.calculateHealing(caster, combatant, 'wit', 100, 0.6)
		await animation_scene.get_node('AnimationPlayer').animation_finished
	CombatGlobals.emit_ability_executed()

static func applyOverworldEffects(caster: ResCombatant, target, _animation_scene):
	for combatant in target:
		CombatGlobals.calculateHealing(caster, combatant, 'wit', 100, 0.6)

