static func animate(caster: CombatantScene, target: CombatantScene, ability: ResAbility):
	if caster.combatant_resource is ResEnemyCombatant:
		match caster.combatant_resource.PREFERRED_POSITION:
			0:
				CombatGlobals.getCombatScene().changeCombatantPosition(caster.combatant_resource, 1, false)
				await caster.moveTo(target)
				await caster.doAnimation('Cast_Melee', ability.ABILITY_SCRIPT)
				await caster.moveTo(caster.get_parent())
			1:
				CombatGlobals.getCombatScene().changeCombatantPosition(caster.combatant_resource, -1)
				await caster.doAnimation('Cast_Ranged', ability.ABILITY_SCRIPT, {'target'=target,'frame_time'=0.7, 'ability'=ability})
	else:
		await caster.moveTo(target)
		await caster.doAnimation('Cast_Melee', ability.ABILITY_SCRIPT)
		await caster.moveTo(caster.get_parent())
	
	CombatGlobals.ability_finished.emit()

static func applyEffects(caster: CombatantScene , target: CombatantScene, _ability: ResAbility=null):
	CombatGlobals.calculateDamage(caster, target, 5.0)
