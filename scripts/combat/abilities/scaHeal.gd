static func animate(caster, target, ability):
	await caster.doAnimation('Cast_Block')
	applyEffects(caster, target, ability)

static func applyEffects(caster, target, ability):
	for combatant in target:
		CombatGlobals.calculateHealing(combatant, 5)
		CombatGlobals.playAbilityAnimation(combatant, ability.ANIMATION)
	
	CombatGlobals.ability_finished.emit()
