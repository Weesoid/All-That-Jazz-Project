static func animateCast(caster: ResCombatant):
	pass
	
static func applyEffects(_caster: ResCombatant, target, animation_scene):
	OverworldGlobals.playSound("res://audio/sounds/334674__yoyodaman234__intense-sizzling-2.ogg")
	CombatGlobals.calculateRawDamage(target, target.BASE_STAT_VALUES['health'] * 0.25)
	await CombatGlobals.playAbilityAnimation(target, animation_scene)
