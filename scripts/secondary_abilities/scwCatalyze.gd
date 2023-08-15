static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Cast')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(_caster: ResCombatant, targets, animation_scene):
	var effects = [preload("res://resources/status_effects/Chilled.tres"), preload("res://resources/status_effects/Jolted.tres"),
	preload("res://resources/status_effects/Singed.tres"), preload("res://resources/status_effects/Poison.tres")]
	randomize()
	for target in targets:
		randomize()
		if CombatGlobals.randomRoll(0.85):
			CombatGlobals.playAbilityAnimation(target, animation_scene)
			var effect = effects.pick_random().duplicate()
			CombatGlobals.manual_call_indicator.emit(target, 'CATALYZED! %s' % [effect.NAME], 'Reaction')
			CombatGlobals.addStatusEffect(target, effect)
		else:
			print('Miss on ', target)
	
	
