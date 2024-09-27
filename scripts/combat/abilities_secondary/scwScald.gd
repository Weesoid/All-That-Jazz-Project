static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Cast')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(_caster: ResCombatant, target, animation_scene):
	var damage = (target.STAT_VALUES['health'] * 0.25) * ((100.0) / (100.0+target.STAT_VALUES['grit']))
	
	#CombatGlobals.playAbilityAnimation(target, animation_scene)
	CombatGlobals.manual_call_indicator.emit(target, str(int(damage), ' SCALD!'), 'Reaction')
	CombatGlobals.calculateRawDamage(target, damage)
