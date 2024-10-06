static func animateCast(_caster: ResCombatant):
	pass
	
static func applyEffects(_caster: ResCombatant, target, animation_scene):
	CombatGlobals.playAbilityAnimation(target, animation_scene)
	CombatGlobals.addStatusEffect(target, 'Vulnerate')
	CombatGlobals.manual_call_indicator.emit(target, 'VULNERATED!', 'Reaction')
