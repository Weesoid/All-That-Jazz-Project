static func animateEffect(caster):
	pass
	
static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	var damage = target.STAT_VALUES['health'] * 0.5
	target.STAT_VALUES['health'] -= damage
	CombatGlobals.playAndResetAnimation(target, 'Hit')
	CombatGlobals.playIndicatorAnimation(target, 'Poisoned!', damage)
	
static func endEffects(target: ResCombatant):
	print('Poison Ended!')
	
