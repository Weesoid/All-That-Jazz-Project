static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.modifyStat(target, {'grit': 0.25}, status_effect.NAME)

static func applyHitEffects(target: ResCombatant, _caster:ResCombatant, value, _status_effect: ResStatusEffect):
	if !CombatGlobals.getCombatScene().has_node('QTE'):
		var qte = preload("res://scenes/quick_time_events/Timing.tscn").instantiate()
		qte.global_position = target.SCENE.global_position
		CombatGlobals.getCombatScene().add_child(qte)
		await CombatGlobals.qte_finished

		if qte.points >= 1:
			var heal = value * 0.25
			CombatGlobals.calculateHealing(target, heal)

		qte.queue_free()

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.resetStat(target, status_effect.NAME)
