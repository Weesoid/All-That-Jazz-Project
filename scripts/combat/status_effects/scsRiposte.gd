static func applyEffects(caster: CombatantScene , target: CombatantScene, _ability: ResAbility=null):
	CombatGlobals.calculateDamage(
		caster, 
		target, 
		5+caster.combatant_resource.STAT_VALUES['health']*0.15,
		true,
		true,
		'',
		'[img]res://images/sprites/icon_riposte.png[/img][color=orange]'
	)

static func applyHitEffects(target, _caster, _value, status_effect: ResStatusEffect):
	if target != CombatGlobals.getCombatScene().active_combatant:
		target.SCENE.doAnimation('Cast_Melee', status_effect.STATUS_SCRIPT, {'anim_speed'=2.0})

static func endEffects(target: ResCombatant, _status_effect: ResStatusEffect):
	applyHitEffects(target, null, null, _status_effect)
