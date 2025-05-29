static func applyEffects(target, status_effect:ResStatusEffect):
	if status_effect.APPLY_ONCE:
		CombatGlobals.addStatusEffect(target, target.GUARD_EFFECT)
	if !target.hasStatusEffect('Guard Break'):
		target.SCENE.setBlocking(true)
		status_effect.current_rank = 1
	else:
		status_effect.removeStatusEffect()

static func applyHitEffects(target, caster, value, status_effect):
	if target is ResPlayerCombatant and target.STAT_MODIFIERS.keys().has('block'):
		CombatGlobals.getCombatScene().battleFlash('Flash', Color.WHITE)
		CombatGlobals.manual_call_indicator.emit(target, '[img]'+str(status_effect.TEXTURE.get_path())+'[/img] Blocked!', 'Resist')
		if target is ResPlayerCombatant and status_effect.current_rank == 1:
			CombatGlobals.addTension(1)
			status_effect.current_rank = 0
	else:
		target.SCENE.block_timer.start(0.8)

static func skillCheck(target: CombatantScene , caster: CombatantScene, check: String, count:int=1):
	var qte = await CombatGlobals.spawnQuickTimeEvent(target, check, count)
	var points = qte.points
	qte.queue_free()
	if points > 0:
		CombatGlobals.calculateDamage(target, caster, 2)

static func endEffects(target, _status_effect: ResStatusEffect):
	target.SCENE.setBlocking(false)
	if !target.hasStatusEffect('Guard Break'):
		CombatGlobals.addStatusEffect(target, 'GuardBreak')
	else:
		CombatGlobals.removeStatusEffect(target, 'Guard Break')
	CombatGlobals.removeStatusEffect(target, 'Riposte')
