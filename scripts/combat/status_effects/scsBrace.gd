static func applyEffects(target, status_effect:ResStatusEffect):
	if !target.hasStatusEffect('Guard Break'):
		target.SCENE.setBlocking(true)
	else:
		status_effect.removeStatusEffect()

static func applyHitEffects(target, _caster, value, status_effect):
	var bonus = 0.1*status_effect.current_rank
	var heal_bonus = 0.15 + (bonus * 0.5)
	print(heal_bonus)
	if target is ResPlayerCombatant:
		CombatGlobals.addTension(50 * heal_bonus)
	if (target is ResPlayerCombatant and target.STAT_MODIFIERS.keys().has('block')) or (target is ResEnemyCombatant and CombatGlobals.randomRoll(0.75+target.STAT_VALUES['grit'])):
		if CombatGlobals.randomRoll(target.BASE_STAT_VALUES['grit'] + 0.5 + bonus) and target is ResPlayerCombatant:
			CombatGlobals.calculateHealing(target, target.getMaxHealth() * heal_bonus, false)
		elif CombatGlobals.randomRoll(target.BASE_STAT_VALUES['grit'] + 0.7 + bonus) and target is ResEnemyCombatant:
			target.SCENE.doAnimation('Block')
			CombatGlobals.calculateHealing(target, (target.getMaxHealth()+value) * 0.5, false)
		CombatGlobals.rankUpStatusEffect(target, status_effect)
		CombatGlobals.manual_call_indicator.emit(target, '[img]'+str(status_effect.TEXTURE.get_path())+'[/img] Blocked!', 'Resist')

static func endEffects(target, _status_effect: ResStatusEffect):
	target.SCENE.setBlocking(false)
	if !target.hasStatusEffect('Guard Break'):
		CombatGlobals.addStatusEffect(target, 'GuardBreak')
	else:
		CombatGlobals.removeStatusEffect(target, 'Guard Break')
