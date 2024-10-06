static func animateCast(_caster: ResCombatant):
	pass
	
static func applyEffects(_caster: ResCombatant, targets, animation_scene):
	for target in targets:
		CombatGlobals.calculateRawDamage(target, target.BASE_STAT_VALUES['health'] * 0.15)
		#CombatGlobals.manual_call_indicator.emit(target, str(int(damage), ' FULGURATED!'), 'Reaction')
		OverworldGlobals.playSound('res://audio/sounds/401609__1histori__air-explosion.ogg')
		await CombatGlobals.playAbilityAnimation(target, animation_scene, 0.05)
