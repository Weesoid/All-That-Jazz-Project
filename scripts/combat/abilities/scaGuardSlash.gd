static func animate(caster: CombatantScene, target: CombatantScene, ability: ResAbility):
	await caster.moveTo(target)
	await caster.doAnimation('Cast_Melee', ability.ABILITY_SCRIPT)
	await caster.moveTo(caster.get_parent())
	CombatGlobals.addStatusEffect(caster.combatant_resource, 'Brace', true)
	CombatGlobals.ability_finished.emit()

static func applyEffects(target: CombatantScene , caster: CombatantScene, _ability: ResAbility=null):
	CombatGlobals.calculateDamage(caster, target, 2.0)
