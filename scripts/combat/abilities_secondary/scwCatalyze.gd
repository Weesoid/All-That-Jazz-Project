static func applyEffects(_caster: ResCombatant, targets, animation_scene):
	var effects = [preload("res://resources/combat/status_effects/Chilled.tres"), preload("res://resources/combat/status_effects/Singed.tres"), preload("res://resources/combat/status_effects/Poison.tres")]
	for target in targets:
		randomize()
		if CombatGlobals.randomRoll(0.65):
			OverworldGlobals.playSound('res://audio/sounds/488392__wobesound__poisongasrelease.ogg')
			var effect = effects.pick_random().NAME
			CombatGlobals.manual_call_indicator.emit(target, 'CATALYZED! %s' % [effect], 'Reaction')
			CombatGlobals.addStatusEffect(target, effect)
			await CombatGlobals.playAbilityAnimation(target, animation_scene, 0.1)
