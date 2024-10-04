static func animate(caster, target, ability):
	await caster.doAnimation('Cast_Block')
	applyEffects(caster, target, ability)

static func applyEffects(_caster, target, ability):
	for combatant in target:
		CombatGlobals.calculateHealing(combatant, 5)
		await CombatGlobals.playAbilityAnimation(combatant, ability.ANIMATION, 0.25)
	
	CombatGlobals.ability_finished.emit()
