static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.APPLY_ONCE:
		target.SCENE.moveTo(target.SCENE.get_parent(), 0.25, Vector2(0,0), true)
		CombatGlobals.playFadingTween(target)
		#CombatGlobals.playAnimation(target, 'Fading')
		target.SCENE.playIdle('Fading')
		CombatGlobals.modifyStat(target, {'hustle': -999}, status_effect.NAME)
		target.SCENE.blocking = false
	if status_effect.duration != status_effect.MAX_DURATION:
		CombatGlobals.manual_call_indicator.emit(target, 'Fading...', 'Resist')
	if CombatGlobals.randomRoll(0.02) and canAddQTE(status_effect):
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
	return status_effect.duration != status_effect.MAX_DURATION - 1 and status_effect.duration > 0 and !CombatGlobals.getCombatScene().has_node('QTE') and CombatGlobals.getCombatScene().isCombatValid() and status_effect.afflicted_combatant.isDead()

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if  CombatGlobals.getCombatScene().combat_result >= 1:
		applyFaded(target)
		CombatGlobals.calculateHealing(target, int(target.BASE_STAT_VALUES['health']*0.25))
	elif target.STAT_VALUES['health'] <= 0.0 and CombatGlobals.getCombatScene().combat_result != 1:
		CombatGlobals.manual_call_indicator.emit(target, 'Out cold!', 'Resist')
		CombatGlobals.addStatusEffect(target, 'KnockOut')
	else:
		CombatGlobals.playSecondWindTween(target)
		applyFaded(target)
		target.SCENE.playIdle('Idle')
	
	CombatGlobals.resetStat(target, status_effect.NAME)

static func applyFaded(target: ResCombatant):
#	var concluded_combat = CombatGlobals.getCombatScene().combat_result != 0
	print(target,' FL studio ', getFadedLevel(target))
	if getFadedLevel(target) == 0:
		print('Plah!')
		target.LINGERING_STATUS_EFFECTS.append('Faded I')
	elif getFadedLevel(target) < 4:
		var escalated_level = getFadedLevel(target)+1
		CombatGlobals.addStatusEffect(target, applyFadedStatus(escalated_level))
		target.LINGERING_STATUS_EFFECTS.erase(applyFadedStatus(escalated_level-1, true))
		CombatGlobals.removeStatusEffect(target, applyFadedStatus(escalated_level-1, true))

static func getFadedLevel(target: ResCombatant):
	if target.hasStatusEffect('Faded I') or target.LINGERING_STATUS_EFFECTS.has('Faded I'):
		return 1
	elif target.hasStatusEffect('Faded II') or target.LINGERING_STATUS_EFFECTS.has('Faded II'):
		return 2
	elif target.hasStatusEffect('Faded III') or target.LINGERING_STATUS_EFFECTS.has('Faded III'):
		return 3
	elif target.hasStatusEffect('Faded IV') or target.LINGERING_STATUS_EFFECTS.has('Faded IV'):
		return 4
	else:
		return 0

static func applyFadedStatus(level: int, add_space:bool=false):
	var out = ''
	match level:
		1: out = 'FadedI'
		2: out =  'FadedII'
		3: out =  'FadedIII'
		4: out =  'FadedIV'
	if add_space:
		out = out.insert(5, ' ')
	return out
