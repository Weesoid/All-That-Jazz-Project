static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.APPLY_ONCE:
		CombatGlobals.manual_call_indicator.emit(target, 'Fading!', 'Show')
		CombatGlobals.modifyStat(target, {'grit': -5.0, 'brawn': -5.0, 'hustle': -999.0}, status_effect.NAME)
	
	if CombatGlobals.randomRoll(1.0 + target.BASE_STAT_VALUES['grit']) and canAddQTE(status_effect):
		var qte = preload("res://scenes/quick_time_events/Timing.tscn").instantiate()
		qte.target_speed = 2.0 + randf_range(0.5, 1.0)
		qte.global_position = target.SCENE.global_position
		CombatGlobals.getCombatScene().add_child(qte)
		await CombatGlobals.qte_finished
	
		if qte.points >= 1:
			CombatGlobals.manual_call_indicator.emit(target, 'Saved!', 'QTE')
			target.STAT_VALUES['health'] = target.BASE_STAT_VALUES['health'] * 0.25
			CombatGlobals.playHurtAnimation(target)
			CombatGlobals.resetStat(target, status_effect.NAME)
	
		qte.queue_free()
		status_effect.duration = 0
		status_effect.tick()

static func canAddQTE(status_effect: ResStatusEffect)-> bool:
	return status_effect.duration != status_effect.MAX_DURATION - 1 and status_effect.duration > 0 and !CombatGlobals.getCombatScene().has_node('QTE')

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if target.STAT_VALUES['health'] < 0.0:
		CombatGlobals.manual_call_indicator.emit(target, 'Knock Out!', 'Resist')
		CombatGlobals.addStatusEffect(target, 'KnockOut', true)
	
	CombatGlobals.resetStat(target, status_effect.NAME)
