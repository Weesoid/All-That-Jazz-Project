static func animateCast(_caster: ResCombatant):
	pass
	
static func applyEffects(_caster: ResCombatant, target: ResCombatant, animation_scene):
	var damage = target.getStatusEffect('Poison').duration * (target.STAT_VALUES['health'] * 0.05)
	CombatGlobals.manual_call_indicator.emit(target, str(int(damage), ' CAUTERIZED!'), 'Reaction')
	target.STAT_VALUES['health'] -= int(damage)
	OverworldGlobals.playSound('90143__pengo_au__steam_burst.ogg')
	await CombatGlobals.playAbilityAnimation(target, animation_scene)
