static func animate(caster, _target, ability):
	if ability.NAME == 'Advance':
		await CombatGlobals.getCombatScene().changeCombatantPosition(caster.combatant_resource, 1)
	elif ability.NAME == 'Recede':
		await CombatGlobals.getCombatScene().changeCombatantPosition(caster.combatant_resource, -1)
	
	CombatGlobals.ability_finished.emit()
