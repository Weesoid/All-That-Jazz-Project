static func animate(caster: CombatantScene, target: CombatantScene, ability: ResAbility):
	await caster.moveTo(target)
	await caster.doAnimation('Cast_Melee', ability.ABILITY_SCRIPT)
	await caster.moveTo(caster.get_parent())
	CombatGlobals.ability_finished.emit()

static func applyEffects(target: CombatantScene , caster: CombatantScene, ability: ResAbility=null):
	CombatGlobals.calculateDamage(caster, target, 3.0)
