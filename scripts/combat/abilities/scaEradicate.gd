static func animate(caster: CombatantScene, target: CombatantScene, ability: ResAbility):
	await caster.doAnimation('Cast_Ranged', ability.ABILITY_SCRIPT, {'target'=target,'frame_time'=0.7,'ability'=ability})
	#CombatGlobals.addStatusEffect(caster.combatant_resource, 'Guard', true)
	CombatGlobals.ability_finished.emit()

static func applyEffects(caster: CombatantScene , target: CombatantScene, _ability: ResAbility=null):
	if target.combatant_resource.hasStatusEffect('Deathmark'):
		#wtarget.playIdle('KO')
		#await CombatGlobals.playKnockOutTween(target.combatant_resource)
		#print('ERADICATE!')
		while !target.combatant_resource.STATUS_EFFECTS.is_empty():
			target.combatant_resource.STATUS_EFFECTS[0].removeStatusEffect()
		for charm in target.combatant_resource.CHARMS.values():
			if charm == null: continue
			OverworldGlobals.getMapRewardBank('loot')[charm]=1
		CombatGlobals.calculateDamage(caster, target, 999)
		PlayerGlobals.removeCombatant(target.combatant_resource)
		CombatGlobals.getCombatScene().removeCombatant(target.combatant_resource)
