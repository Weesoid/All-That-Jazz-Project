static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.apply_once:
		CombatGlobals.addStatusEffect(target, 'Stunned')
	if status_effect.duration >= 5:
		status_effect.removeStatusEffect()

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.resetStat(target, status_effect.name)
	var damage = 2 * status_effect.duration
	var message = '[color=yellow]'
	if status_effect.duration >= 5:
		message = '[color=yellow]OVERCHAGRE!'
	CombatGlobals.calculateRawDamage(
		target, 
		damage, 
		null, 
		false, 
		-1.0, 
		false, 
		-1.0, 
		false, 
		"",
		message
	)
