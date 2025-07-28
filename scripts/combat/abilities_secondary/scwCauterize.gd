static func applyEffects(_caster: ResCombatant, target: ResCombatant, animation_scene):
	var poison: ResStatusEffect = target.getStatusEffect('Poison')
	var damage = poison.duration * (2 * poison.current_rank)
	CombatGlobals.calculateRawDamage(target, damage)
	OverworldGlobals.playSound('90143__pengo_au__steam_burst.ogg')
	await CombatGlobals.playAbilityAnimation(target, animation_scene.animation)
