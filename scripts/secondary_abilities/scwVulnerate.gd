static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Cast')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(_caster: ResCombatant, target, _animation_scene):
	CombatGlobals.addStatusEffect(target, preload("res://resources/status_effects/Vulnerate.tres").duplicate())
	CombatGlobals.manual_call_indicator.emit(target, 'VULNERATED!', 'Reaction')
	
	CombatGlobals.secondary_ability_executed.emit()
