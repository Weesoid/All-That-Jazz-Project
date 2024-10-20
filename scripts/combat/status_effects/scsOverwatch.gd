static func applyEffects(caster: CombatantScene , target: CombatantScene, _ability: ResAbility=null):
	CombatGlobals.calculateDamage(caster, target, 5+caster.combatant_resource.STAT_VALUES['health']*0.1)

static func animate(caster, target):
	caster.SCENE.doAnimation('Cast_Melee')
	applyEffects(caster.SCENE, target)

static func endEffects(_target: ResCombatant, _status_effect: ResStatusEffect):
	pass
