static func animate(caster: CombatantScene, target: CombatantScene, ability: ResAbility):
	await caster.doAnimation('Cast_Ranged', ability.ABILITY_SCRIPT, true, {'target'=target,'frame_time'=0.7})
	CombatGlobals.ability_finished.emit()

static func applyEffects(target: CombatantScene , caster: CombatantScene, ability: ResAbility=null):
	CombatGlobals.calculateDamage(caster, target, 5.0)
