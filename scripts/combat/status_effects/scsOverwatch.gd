static func applyEffects(caster: CombatantScene , target: CombatantScene, _ability: ResAbility=null):
	CombatGlobals.calculateDamage(caster, target, 5+caster.combatant_resource.stat_values['health']*0.1)

static func animate(caster, target):
	caster.combatant_scene.doAnimation('Cast_Melee')
	applyEffects(caster.combatant_scene, target)

static func endEffects(_target: ResCombatant, _status_effect: ResStatusEffect):
	pass
