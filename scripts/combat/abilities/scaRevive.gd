static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Attack')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')

static func applyEffects(_caster: ResCombatant, target: ResCombatant, _animation_scene):
	CombatGlobals.playAndResetAnimation(target, 'Hit')
	CombatGlobals.removeStatusEffect(target, 'Knock Out')
	target.STAT_VALUES['health'] = 0.25 * target.BASE_STAT_VALUES['health']
