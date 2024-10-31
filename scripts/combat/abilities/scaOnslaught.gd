static func animate(caster: CombatantScene, target: CombatantScene, ability: ResAbility):
	var prev_pos = caster.get_parent().global_position
	caster.get_parent().global_position = Vector2(0, -16)
	await CombatGlobals.getCombatScene().changeCombatantPosition(target.combatant_resource, 0)
	caster.setProjectileTarget(target, 2.0)
	await caster.doAnimation('Onslaught', ability.ABILITY_SCRIPT)
	caster.get_parent().global_position = prev_pos
	
	await CombatGlobals.getCombatScene().setOnslaught(target.combatant_resource, false)
	caster.moveTo(caster.get_parent())
	await target.moveTo(target.get_parent())
	CombatGlobals.ability_finished.emit()

static func applyEffects(target: CombatantScene , caster: CombatantScene, _ability: ResAbility=null):
	CombatGlobals.calculateDamage(target, caster, 5.0, false, true)
