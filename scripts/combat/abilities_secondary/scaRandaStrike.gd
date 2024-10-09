static func applyEffects(_caster: ResCombatant, targets, animation_scene):
	for i in targets:
		CombatGlobals.calculateRawDamage(i, 1)
		await CombatGlobals.playAbilityAnimation(i, animation_scene, 0.25)
