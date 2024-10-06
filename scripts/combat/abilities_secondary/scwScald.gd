static func animateCast(caster: ResCombatant):
	pass
	
static func applyEffects(_caster: ResCombatant, target, animation_scene):
	OverworldGlobals.playSound('90143__pengo_au__steam_burst.ogg')
	CombatGlobals.calculateRawDamage(target, target.BASE_STAT_VALUES['health'] * 0.25)
	await CombatGlobals.playAbilityAnimation(target, animation_scene)
