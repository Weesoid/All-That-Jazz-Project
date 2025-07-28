static func animate(caster: CombatantScene, target: CombatantScene, ability: ResAbility):
	await CombatGlobals.getCombatScene().setOnslaught(target.combatant_resource, true)
	
	CombatGlobals.getCombatScene().fadeCombatant(caster, true)
	caster.setProjectileTarget(target, 2.0, ability)
	await caster.doAnimation('Onslaught', ability.ability_script)
	
	await CombatGlobals.getCombatScene().setOnslaught(target.combatant_resource, false)
	CombatGlobals.ability_finished.emit()

static func applyEffects(caster: CombatantScene , target: CombatantScene, _ability: ResAbility=null):
	CombatGlobals.calculateRawDamage(
		target.combatant_resource, 
		CombatGlobals.useDamageFormula(target.combatant_resource, 10), 
		caster.combatant_resource, 
		true, 
		-1, 
		false, 
		0.15,
		false
		)
	for combatant in CombatGlobals.getCombatScene().getCombatantGroup('team'):
		if !combatant.isDead() and !target.combatant_resource.stat_modifiers.keys().has('block') and combatant != target.combatant_resource: 
			CombatGlobals.calculateRawDamage(
				combatant, 
				CombatGlobals.useDamageFormula(combatant, 10), 
				caster.combatant_resource, 
				true, 
				-1, 
				false, 
				0.15, 
				false
				)
