static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Cast')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(_caster: ResCombatant, targets, animation_scene):
	for target in targets:
		var damage = (target.STAT_VALUES['health'] * 0.15) * ((100.0) / (100.0+target.STAT_VALUES['grit']))
		
		CombatGlobals.manual_call_indicator.emit(target, str(int(damage), ' FULGURATED!'), 'Reaction')
		target.STAT_VALUES['health'] -= int(damage)
	
	CombatGlobals.secondary_ability_executed.emit()
