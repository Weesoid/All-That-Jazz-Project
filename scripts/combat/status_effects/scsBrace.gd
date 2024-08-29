static func applyEffects(target, _status_effect):
	target.SCENE.setBlocking(true)

static func applyHitEffects(target, _caster, value, status_effect):
	var bonus = 0.1*status_effect.current_rank
	if target.STAT_MODIFIERS.keys().has('block'):
		if CombatGlobals.randomRoll(target.BASE_STAT_VALUES['grit'] + 0.5 + bonus):
			var heal_bonus = 0.15 + (bonus * 0.5)
			CombatGlobals.calculateHealing(target, target.getMaxHealth() * heal_bonus)
		CombatGlobals.rankUpStatusEffect(target, status_effect)

static func endEffects(target, _status_effect: ResStatusEffect):
	target.SCENE.setBlocking(false)
	CombatGlobals.addStatusEffect(target, 'GuardBreak')
