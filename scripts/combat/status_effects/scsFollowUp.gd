static func applyEffects(caster: CombatantScene , target: CombatantScene, _ability: ResAbility=null):
	CombatGlobals.calculateDamage(caster, target, 5+caster.combatant_resource.stat_values['health']*0.1)

static func animate(caster, target):
	var ability = load("res://resources/combat/abilities/BasicProjectile.tres")
	await caster.combatant_scene.doAnimation('Cast_Ranged', ability.ability_script, {'target'=target.combatant_scene,'frame_time'=0.7,'ability'=ability})

static func endEffects(_target: ResCombatant, _status_effect: ResStatusEffect):
	pass
