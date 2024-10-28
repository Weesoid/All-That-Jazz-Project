static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.APPLY_ONCE:
		target.SCENE.moveTo(target.SCENE.get_parent(), 0.25, Vector2(0,0), true)
		CombatGlobals.playFadingTween(target)
		CombatGlobals.playAnimation(target, 'Fading')
		CombatGlobals.modifyStat(target, {'hustle': -999}, status_effect.NAME)
		target.SCENE.blocking = false
	
	CombatGlobals.manual_call_indicator.emit(target, 'Fading...', 'Resist')

	if CombatGlobals.randomRoll(1.15) and canAddQTE(status_effect):
		var qte = preload("res://scenes/quick_time_events/Timing.tscn").instantiate()
		qte.target_speed = 1.0 + randf_range(0.5, 1.0)
		qte.global_position = Vector2(0, -40)
		CombatGlobals.getCombatScene().add_child(qte)
		await CombatGlobals.qte_finished
		if qte.points >= 1:
			CombatGlobals.manual_call_indicator.emit(target, 'Saved!', 'QTE')
			target.STAT_VALUES['health'] = target.BASE_STAT_VALUES['health'] * 0.3
			if target.STAT_VALUES['health'] <= 0:
				target.STAT_VALUES['health'] = 1
			
			CombatGlobals.resetStat(target, status_effect.NAME)
		qte.queue_free()
		status_effect.removeStatusEffect()
	elif target.STAT_VALUES['health'] > 0:
		status_effect.removeStatusEffect()

static func canAddQTE(status_effect: ResStatusEffect)-> bool:
	return status_effect.duration != status_effect.MAX_DURATION - 1 and status_effect.duration > 0 and !CombatGlobals.getCombatScene().has_node('QTE') and CombatGlobals.getCombatScene().isCombatValid()

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if target.STAT_VALUES['health'] <= 0.0 and CombatGlobals.getCombatScene().combat_result != 1:
		CombatGlobals.manual_call_indicator.emit(target, 'Out cold!', 'Resist')
		CombatGlobals.addStatusEffect(target, 'KnockOut', true)
	else:
		CombatGlobals.playSecondWindTween(target)
		#CombatGlobals.addStatusEffect(target, 'SecondWind', true)
		applyFaded(target)
		CombatGlobals.playAnimation(target, 'Idle')
	
	CombatGlobals.resetStat(target, status_effect.NAME)
	if CombatGlobals.getCombatScene().combat_result == 1: 
		CombatGlobals.calculateHealing(target, target.BASE_STAT_VALUES['health']*0.25)

static func applyFaded(target: ResCombatant):
	if target.hasStatusEffect('Faded I'):
		target.LINGERING_STATUS_EFFECTS.erase('Faded I')
		CombatGlobals.removeStatusEffect(target, 'Faded I')
		CombatGlobals.addStatusEffect(target, 'FadedII', true)
	elif target.hasStatusEffect('Faded II'):
		target.LINGERING_STATUS_EFFECTS.erase('Faded II')
		CombatGlobals.removeStatusEffect(target, 'Faded II')
		CombatGlobals.addStatusEffect(target, 'FadedIII', true)
	elif target.hasStatusEffect('Faded III'):
		target.LINGERING_STATUS_EFFECTS.erase('Faded III')
		CombatGlobals.removeStatusEffect(target, 'Faded III')
		CombatGlobals.addStatusEffect(target, 'FadedIV', true)
	elif !target.hasStatusEffect('Faded IV'):
		CombatGlobals.addStatusEffect(target, 'FadedI', true)
