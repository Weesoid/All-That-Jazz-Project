static func applyEffects(_caster: ResCombatant, targets, animation_scene):
	var effects = [
		load("res://resources/combat/status_effects/Chilled.tres"), 
		load("res://resources/combat/status_effects/Burn.tres"), 
		load("res://resources/combat/status_effects/Poison.tres")
		]
	for target in targets:
		randomize()
		if CombatGlobals.randomRoll(0.75):
			OverworldGlobals.playSound('res://audio/sounds/488392__wobesound__poisongasrelease.ogg')
			var effect = effects.pick_random().name
			CombatGlobals.manual_call_indicator.emit(target, 'CATALYZED! %s' % [effect], 'Reaction')
			CombatGlobals.addStatusEffect(target, effect)
			await CombatGlobals.playAbilityAnimation(target, animation_scene.animation, 0.1)
