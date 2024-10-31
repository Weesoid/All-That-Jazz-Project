static func animate(caster: CombatantScene, target: CombatantScene, ability: ResAbility):
	var prev_pos = caster.get_parent().global_position
	caster.get_parent().global_position = Vector2(0, -16)
	await CombatGlobals.getCombatScene().setOnslaught(target.combatant_resource, true)
	
	caster.setProjectileTarget(target, 2.0)
	await caster.doAnimation('Onslaught', ability.ABILITY_SCRIPT)
	caster.get_parent().global_position = prev_pos
	
	await CombatGlobals.getCombatScene().setOnslaught(target.combatant_resource, false)
	caster.moveTo(caster.get_parent())
	await target.moveTo(target.get_parent())
	CombatGlobals.ability_finished.emit()

static func applyEffects(target: CombatantScene , caster: CombatantScene, _ability: ResAbility=null):
	CombatGlobals.calculateRawDamage(caster.combatant_resource, CombatGlobals.useDamageFormula(caster.combatant_resource, 10), target.combatant_resource, true, -1, false, 0.15, null, false)
