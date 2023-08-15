static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Cast')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(_caster: ResCombatant, target: ResCombatant, animation_scene):
	var damage = target.getStatusEffect('Poison').duration * (target.STAT_VALUES['health'] * 0.05)
	CombatGlobals.manual_call_indicator.emit(target, str(int(damage), ' CAUTERIZED!'), 'Reaction')
	target.STAT_VALUES['health'] -= int(damage)
	CombatGlobals.playAbilityAnimation(target, animation_scene)
	
