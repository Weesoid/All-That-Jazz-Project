static func animate(caster: ResCombatant, target, ability):
	await caster.SCENE.moveTo(target)
	await caster.SCENE.doAnimation('Cast_Melee', ability.ABILITY_SCRIPT)
	await caster.SCENE.moveTo(caster.SCENE.get_parent())

static func applyEffects(target: CombatantScene, caster: CombatantScene):
	CombatGlobals.calculateDamage(caster.combatant_resource, target.combatant_resource, 5)
