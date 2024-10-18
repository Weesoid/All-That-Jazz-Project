static func applyEffects(_caster: ResCombatant, target, animation_scene):
	CombatGlobals.playAbilityAnimation(target, animation_scene)
	CombatGlobals.addStatusEffect(target, 'Vulnerate')
	OverworldGlobals.playSound("res://audio/sounds/189575__unopiate__breaking-glass.ogg")
	CombatGlobals.manual_call_indicator.emit(target, 'VULNERATED!', 'Reaction')
