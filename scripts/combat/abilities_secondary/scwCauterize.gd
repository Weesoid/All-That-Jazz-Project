static func applyEffects(_caster: ResCombatant, target: ResCombatant, animation_scene):
	var damage = target.getStatusEffect('Poison').duration * (target.stat_values['health'] * 0.06)
	CombatGlobals.calculateRawDamage(target, CombatGlobals.useDamageFormula(target, damage))
	OverworldGlobals.playSound('90143__pengo_au__steam_burst.ogg')
	await CombatGlobals.playAbilityAnimation(target, animation_scene.animation)
