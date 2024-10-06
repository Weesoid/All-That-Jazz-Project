static func animateCast(_caster: ResCombatant):
	pass
	
static func applyEffects(_caster: ResCombatant, targets, animation_scene):
	for target in targets:
		CombatGlobals.playAbilityAnimation(target, animation_scene)
		CombatGlobals.addStatusEffect(target, 'Disrupted')
		CombatGlobals.manual_call_indicator.emit(target, 'DISRUPTED!', 'Reaction')
	
	
