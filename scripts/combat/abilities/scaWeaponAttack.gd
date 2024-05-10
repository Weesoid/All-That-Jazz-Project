var points

static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Cast')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(caster: ResCombatant, target: ResCombatant, animation_scene):
#	var damage = 10
#	if caster is ResPlayerCombatant:
#		var qte = preload("res://scenes/quick_time_events/Timing.tscn").instantiate()
#		qte.global_position = target.SCENE.global_position
#		qte.max_points = 3
#		CombatGlobals.getCombatScene().add_child(qte)
#		await CombatGlobals.qte_finished
#
#		if qte.points >= 1:
#			CombatGlobals.manual_call_indicator.emit(target, '10!', 'QTE')
#			damage += 10
#		if qte.points >= 2:
#			CombatGlobals.manual_call_indicator.emit(target, '20!', 'QTE')
#			damage += 20
#		if qte.points >= 3:
#			CombatGlobals.getCombatScene().combat_log.writeCombatLog('PERFECTION!')
#			CombatGlobals.manual_call_indicator.emit(target, '30!', 'QTE')
#			damage += 30
#		if qte.points >= 4:
#			CombatGlobals.manual_call_indicator.emit(target, 'SINGE!', 'QTE')
#			CombatGlobals.addStatusEffect(target, 'Poison')
#
#		qte.queue_free()
	
	CombatGlobals.playAbilityAnimation(target, animation_scene)
	CombatGlobals.calculateRawDamage(target, 49)
