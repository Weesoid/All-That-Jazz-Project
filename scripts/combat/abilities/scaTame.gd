static func animate(caster: CombatantScene, target: CombatantScene, ability: ResAbility):
	await caster.doAnimation('Cast_Misc')
	if canTame(target):
		CombatGlobals.playAbilityAnimation(target.combatant_resource, ability.ANIMATION)
		CombatGlobals.getCombatScene().tamed_combatants.append(target.combatant_resource.tamed_combatant.resource_path)
		CombatGlobals.calculateRawDamage(target, 999)
		CombatGlobals.getCombatScene().combat_log.writeCombatLog('[color=yellow]%s[/color] has been tamed!' % target.combatant_resource.tamed_combatant.NAME)
	else:
		CombatGlobals.calculateRawDamage(target, 5)
	
	CombatGlobals.ability_finished.emit()

static func canTame(target, tame_threshold:float=1.0):
	var tame_target: ResPlayerCombatant = target.combatant_resource.tamed_combatant
	return target.combatant_resource.is_converted and target.combatant_resource.STAT_VALUES['health'] <= target.combatant_resource.getMaxHealth()*tame_threshold and !OverworldGlobals.getMapRewardBank('tamed').has(tame_target.resource_path) and !CombatGlobals.getCombatScene().tamed_combatants.has(tame_target.resource_path) and !PlayerGlobals.getTeamMemberNames().has(tame_target.NAME)

static func applyEffects(_target: CombatantScene , _caster: CombatantScene, _ability: ResAbility=null):
	pass
