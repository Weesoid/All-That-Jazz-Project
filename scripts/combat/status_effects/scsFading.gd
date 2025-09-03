static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.apply_once:
		target.combatant_scene.moveTo(target.combatant_scene.get_parent(), 0.25, Vector2(0,0), true)
		CombatGlobals.playFadingTween(target)
		target.combatant_scene.playIdle('Fading')
		CombatGlobals.modifyStat(target, {'speed': -999}, status_effect.name)
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

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	#await CombatGlobals.getCombatScene().get_tree().create_timer(0.5).timeout
	if  CombatGlobals.getCombatScene().combat_result >= 1:
		CombatGlobals.applyFaded(target)
		CombatGlobals.calculateHealing(target, int(target.base_stat_values['health']*0.25),true,false)
	elif target.stat_values['health'] <= 0.0 and CombatGlobals.getCombatScene().combat_result != 1:
		CombatGlobals.addStatusEffect(target, 'KnockOut')
	else:
		CombatGlobals.applyFaded(target)
		CombatGlobals.playSecondWindTween(target)
		target.combatant_scene.idle_animation = 'Idle'
	
	CombatGlobals.resetStat(target, status_effect.name)
