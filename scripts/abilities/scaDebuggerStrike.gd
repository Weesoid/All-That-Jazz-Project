static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Cast')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(_caster: ResCombatant, targets, animation_scene):
	for target in targets:
		CombatGlobals.playSingleTargetAnimation(target, animation_scene)
		CombatGlobals.manual_call_indicator.emit(target, '25 REACTION', 'Show')
		target.STAT_VALUES['health'] -= 25
		CombatGlobals.playAndResetAnimation(target, 'Hit')
		await animation_scene.get_node('AnimationPlayer').animation_finished
		
	CombatGlobals.emit_ability_executed()
	
