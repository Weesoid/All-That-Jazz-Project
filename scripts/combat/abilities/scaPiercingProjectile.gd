static func animate(caster: CombatantScene, _target: CombatantScene, ability: ResAbility):
	await caster.doAnimation('Cast_Ranged', ability.ability_script, {'target'=null,'frame_time'=0.7, 'ability'=ability})
	CombatGlobals.ability_finished.emit()

static func applyEffects(target: CombatantScene , caster: CombatantScene, _ability: ResAbility=null):
	CombatGlobals.calculateDamage(caster, target, 5.0)
