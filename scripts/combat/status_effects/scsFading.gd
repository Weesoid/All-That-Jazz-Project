static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.apply_once:
		var throbber = load("res://scenes/animations_quick/SpriteThrobber.tscn")
		target.combatant_scene.moveTo(target.combatant_scene.get_parent(), 0.25, Vector2(0,0), true)
		CombatGlobals.playFadingTween(target)
		target.combatant_scene.playIdle('Hurt')
		OverworldGlobals.showQuickAnimation(throbber, target.getSprite())
		#CombatGlobals.modifyStat(target, {'speed': -999}, status_effect.name)
		target.combatant_scene.blocking = false
	
	if CombatGlobals.randomRoll(0.025) and canAddQTE(status_effect):
		var qte = load("res://scenes/quick_time_events/Timing.tscn").instantiate()
		qte.target_speed = 1.0 + randf_range(0.5, 1.0)
		qte.global_position = Vector2(0, -40)
		CombatGlobals.getCombatScene().add_child(qte)
		await CombatGlobals.qte_finished
		if qte.points >= 1:
			CombatGlobals.calculateHealing(target, target.base_stat_values['health']*0.2, true, false)
			CombatGlobals.resetStat(target, status_effect.name)
		qte.queue_free()
		status_effect.removeStatusEffect()
		#CombatGlobals.addStatusEffect(target,'Guard')
	
	elif target.stat_values['health'] > 0:
		status_effect.removeStatusEffect()

static func canAddQTE(status_effect: ResStatusEffect)-> bool:
	return status_effect.duration != status_effect.max_duration - 1 and status_effect.duration > 0 and !CombatGlobals.getCombatScene().has_node('QTE') and CombatGlobals.getCombatScene().isCombatValid() and status_effect.afflicted_combatant.isDead()

static func endEffects(target: ResCombatant, _status_effect: ResStatusEffect):
	var throbber_list = target.getSprite().get_children().filter(func(child): return child.has_meta('is_sprite_throbber'))
	if throbber_list.size() > 0:
		throbber_list[0].queue_free()
	
	if  CombatGlobals.getCombatScene().combat_result >= 1:
		CombatGlobals.applyFaded(target)
		CombatGlobals.calculateHealing(target, int(target.base_stat_values['health']*0.25),false,false)
	elif target.stat_values['health'] <= 0.0 and CombatGlobals.getCombatScene().combat_result != 1:
		CombatGlobals.addStatusEffect(target, 'KnockOut')
	else:
		CombatGlobals.applyFaded(target)
		CombatGlobals.playSecondWindTween(target)
		target.combatant_scene.playIdle('Idle')
	
	#CombatGlobals.resetStat(target, status_effect.name)
