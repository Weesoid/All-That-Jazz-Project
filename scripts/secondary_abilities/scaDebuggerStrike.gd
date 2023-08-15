static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Cast')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(_caster: ResCombatant, targets, _animation_scene):
	for target in targets:
		CombatGlobals.manual_call_indicator.emit(target, '25 REACTION', 'Reaction')
		target.STAT_VALUES['health'] -= 25
		CombatGlobals.playAndResetAnimation(target, 'Hit')
	
	CombatGlobals.secondary_ability_executed.emit()
