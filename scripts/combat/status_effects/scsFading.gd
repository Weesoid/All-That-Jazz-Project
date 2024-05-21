static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.APPLY_ONCE:
		CombatGlobals.manual_call_indicator.emit(target, 'Fading!', 'Show')
		CombatGlobals.playFadingTween(target)
		CombatGlobals.modifyStat(target, {'hustle': -999.0}, status_effect.NAME)
	
	if CombatGlobals.randomRoll(1.0 + target.BASE_STAT_VALUES['grit']) and canAddQTE(status_effect):
		var qte = preload("res://scenes/quick_time_events/Timing.tscn").instantiate()
		qte.target_speed = 1.0 + randf_range(0.5, 1.0)
		qte.global_position = Vector2(0, 0)
		CombatGlobals.getCombatScene().add_child(qte)
		OverworldGlobals.playSound('641011__metkir__crying-sound-0.mp3')
		await CombatGlobals.qte_finished
	
		if qte.points >= 1:
			CombatGlobals.manual_call_indicator.emit(target, 'Saved!', 'QTE')
			target.STAT_VALUES['health'] = target.BASE_STAT_VALUES['health'] * 0.3
			if target.STAT_VALUES['health'] <= 0:
				target.STAT_VALUES['health'] = 1
			
			CombatGlobals.resetStat(target, status_effect.NAME)
	
		qte.queue_free()
		status_effect.duration = 0
		status_effect.tick()

static func canAddQTE(status_effect: ResStatusEffect)-> bool:
	return status_effect.duration != status_effect.MAX_DURATION - 1 and status_effect.duration > 0 and !CombatGlobals.getCombatScene().has_node('QTE') and CombatGlobals.getCombatScene().isCombatValid()

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if target.STAT_VALUES['health'] <= 0.0:
		CombatGlobals.manual_call_indicator.emit(target, 'Out cold!', 'Resist')
		CombatGlobals.addStatusEffect(target, 'KnockOut', true)
	else:
		CombatGlobals.playSecondWindTween(target)
		CombatGlobals.addStatusEffect(target, 'SecondWind', true)
	
	CombatGlobals.resetStat(target, status_effect.NAME)
