static func animate(caster: CombatantScene, target: CombatantScene, ability: ResAbility):
	await caster.moveTo(target)
	await caster.doAnimation('Cast_Melee', ability.ABILITY_SCRIPT)
	await caster.moveTo(caster.get_parent())
	CombatGlobals.ability_finished.emit()


static func applyEffects(caster: CombatantScene , target: CombatantScene, _ability: ResAbility=null):
	if CombatGlobals.calculateDamage(caster, target, 2):
		randomize()
		var element = ['Poison'].pick_random()
		if element != '':
			CombatGlobals.addStatusEffect(target.combatant_resource, element, true)

