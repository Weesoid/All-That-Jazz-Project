static func applyEffects(_caster: ResCombatant, targets, animation_scene):
	for i in targets:
		CombatGlobals.playAbilityAnimation(i, animation_scene)
		CombatGlobals.calculateRawDamage(i, 999.0)
