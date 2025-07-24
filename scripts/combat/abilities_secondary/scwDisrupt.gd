static func applyEffects(_caster: ResCombatant, targets, animation_scene):
	OverworldGlobals.playSound('res://audio/sounds/442873__euanmj__puffofsmoke.ogg')
	for target in targets:
		CombatGlobals.playAbilityAnimation(target, animation_scene.animation)
		CombatGlobals.addStatusEffect(target, 'Disrupted')
		CombatGlobals.manual_call_indicator.emit(target, 'DISRUPTED!', 'Reaction')
