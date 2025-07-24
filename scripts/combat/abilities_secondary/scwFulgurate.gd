static func applyEffects(_caster: ResCombatant, targets, animation_scene):
	for target in targets:
		var damage = target.base_stat_values['health'] * 0.15
		CombatGlobals.calculateRawDamage(target, CombatGlobals.useDamageFormula(target, damage))
		OverworldGlobals.playSound('res://audio/sounds/401609__1histori__air-explosion.ogg')
		await CombatGlobals.playAbilityAnimation(target, animation_scene.animation, 0.05)
