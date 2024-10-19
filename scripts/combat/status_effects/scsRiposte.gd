static func applyEffects(caster: CombatantScene , target: CombatantScene, _ability: ResAbility=null):
	CombatGlobals.calculateDamage(caster, target, 5+caster.combatant_resource.STAT_VALUES['health']*0.15)

static func applyHitEffects(target, _caster, value, status_effect: ResStatusEffect):
	target.SCENE.doAnimation('Cast_Melee', status_effect.STATUS_SCRIPT)

static func endEffects(_target: ResCombatant, _status_effect: ResStatusEffect):
	pass
