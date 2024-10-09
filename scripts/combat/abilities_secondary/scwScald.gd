static func animateCast(caster: ResCombatant):
	pass
	
static func applyEffects(_caster: ResCombatant, target, animation_scene):
	OverworldGlobals.playSound("res://audio/sounds/334674__yoyodaman234__intense-sizzling-2.ogg")
	var damage = target.BASE_STAT_VALUES['health'] * 0.25
	CombatGlobals.calculateRawDamage(target, CombatGlobals.useDamageFormula(target, damage))
	await CombatGlobals.playAbilityAnimation(target, animation_scene)
