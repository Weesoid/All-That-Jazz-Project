static func applyEffects(target: CombatantScene , caster: CombatantScene, _ability: ResAbility=null):
	CombatGlobals.calculateDamage(caster, target, 5+caster.combatant_resource.STAT_VALUES['health']*0.15)

static func applyHitEffects(target, caster, value, status_effect: ResStatusEffect):
	status_effect.current_rank = value
	target.SCENE.doAnimation('Cast_Melee', status_effect.STATUS_SCRIPT)

static func endEffects(_target: ResCombatant, _status_effect: ResStatusEffect):
	pass
