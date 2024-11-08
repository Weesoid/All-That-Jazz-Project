static func applyEffects(caster: CombatantScene , target: CombatantScene, _ability: ResAbility=null):
	CombatGlobals.calculateDamage(caster, target, 5+caster.combatant_resource.STAT_VALUES['health']*0.1)

static func animate(caster, target):
	var ability = load("res://resources/combat/abilities/BasicProjectile.tres")
	await caster.SCENE.doAnimation('Cast_Ranged', ability.ABILITY_SCRIPT, {'target'=target.SCENE,'frame_time'=0.7,'ability'=ability})

static func endEffects(_target: ResCombatant, _status_effect: ResStatusEffect):
	pass
