static func applyEffects(target, status_effect:ResStatusEffect):
	if status_effect.apply_once and target.guard_effect != null:
		CombatGlobals.addStatusEffect(target, target.guard_effect)
	
	if target.stat_modifiers.keys().has('block') and !target.combatant_scene.allow_block:
		CombatGlobals.resetStat(target, 'block')
	
	if !target.hasStatusEffect('Guard Break'):
		if target.stat_values['health'] <= 0 and status_effect.apply_once:
			CombatGlobals.calculateHealing(target, 5,false)
		target.combatant_scene.setBlocking(true)
		status_effect.attached_data = 1
	else:
		status_effect.removeStatusEffect()

static func applyHitEffects(target, _caster, _value, status_effect):
	if target is ResPlayerCombatant and target.stat_modifiers.keys().has('block'):
		CombatGlobals.getCombatScene().battleFlash('Flash', Color.WHITE)
		#CombatGlobals.manual_call_indicator.emit(target, '[img]'+str(status_effect.texture.get_path())+'[/img] Blocked!', 'Resist')
		if target is ResPlayerCombatant and status_effect.attached_data == 1:
			CombatGlobals.addTension(1,target.combatant_scene)
			status_effect.attached_data = 0
	else:
		target.combatant_scene.block_timer.start(0.8)

static func endEffects(target, _status_effect: ResStatusEffect):
	target.combatant_scene.setBlocking(false)
	if !target.hasStatusEffect('Guard Break'):
		CombatGlobals.addStatusEffect(target, 'GuardBreak')
	else:
		CombatGlobals.removeStatusEffect(target, 'Guard Break')
	if target.stat_modifiers.keys().has('block') and !target.combatant_scene.allow_block:
		CombatGlobals.resetStat(target, 'block')
	if target.hasStatusEffect('Riposte'):
		CombatGlobals.removeStatusEffect(target, 'Riposte')
