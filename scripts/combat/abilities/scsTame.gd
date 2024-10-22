static func animate(caster: CombatantScene, target: CombatantScene, ability: ResAbility):
	await caster.doAnimation('Cast_Misc')
	if target.combatant_resource.is_converted and target.combatant_resource.STAT_VALUES['health'] <= target.combatant_resource.getMaxHealth()*0.25:
		CombatGlobals.playAbilityAnimation(target.combatant_resource, ability.ANIMATION)
		CombatGlobals.getCombatScene().tamed_combatants.append(caster.tamed_combatant)

static func applyEffects(target: CombatantScene , caster: CombatantScene, _ability: ResAbility=null):
	pass
