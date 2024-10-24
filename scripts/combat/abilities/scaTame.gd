static func animate(caster: CombatantScene, target: CombatantScene, ability: ResAbility):
	await caster.doAnimation('Cast_Misc')
	if target.combatant_resource.is_converted and target.combatant_resource.STAT_VALUES['health'] <= target.combatant_resource.getMaxHealth()*0.25 and !PlayerGlobals.getTeamMembers().has(target.combatant_resource.tamed_combatant.NAME):
		CombatGlobals.playAbilityAnimation(target.combatant_resource, ability.ANIMATION)
		CombatGlobals.getCombatScene().tamed_combatants.append(target.combatant_resource.tamed_combatant)
		CombatGlobals.calculateRawDamage(target, 999)
	
	CombatGlobals.ability_finished.emit()

static func applyEffects(_target: CombatantScene , _caster: CombatantScene, _ability: ResAbility=null):
	pass
