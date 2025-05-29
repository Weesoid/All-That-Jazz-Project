static func applyEffects(caster: CombatantScene , target: CombatantScene, _ability: ResAbility=null):
	var caster_riposte = caster.combatant_resource.RIPOSTE_EFFECT
	if caster_riposte != null:
		CombatGlobals.calculateDamage(
			caster, 
			target, 
			caster_riposte.damage,
			caster_riposte.can_miss,
			caster_riposte.can_crit,
			'',
			'[img]res://images/sprites/icon_riposte.png[/img][color=orange]',
			caster_riposte.bonus_stats
		)
	else:
		CombatGlobals.calculateDamage(
			caster, 
			target, 
			5+(target.combatant_resource.getMaxHealth()*0.1),
			true,
			true,
			'',
			'[img]res://images/sprites/icon_riposte.png[/img][color=orange]'
		)

static func applyHitEffects(target,caster, _value, status_effect: ResStatusEffect):
	if target != CombatGlobals.getCombatScene().active_combatant and !status_effect.afflicted_combatant.isImmobilized() and ((target is ResPlayerCombatant and target.STAT_MODIFIERS.has('block')) or target is ResEnemyCombatant):
		var riposte_anim = determineRiposte(target, caster)
		if riposte_anim == 'Cast_Melee':
			target.SCENE.doAnimation(riposte_anim, status_effect.STATUS_SCRIPT, {'anim_speed'=1.5})
		else:
			target.SCENE.doAnimation(riposte_anim, status_effect.STATUS_SCRIPT, {'target'=caster.SCENE,'frame_time'=0.7,'ability'=null,'anim_speed'=2.0})

static func determineRiposte(target, caster):
	var distance = target.SCENE.global_position.distance_to(caster.SCENE.global_position)
	if distance > 40:
		return 'Cast_Ranged'
	else:
		return 'Cast_Melee'

static func endEffects(target: ResCombatant, _status_effect: ResStatusEffect):
	pass
	#applyHitEffects(target, null, null, _status_effect)
