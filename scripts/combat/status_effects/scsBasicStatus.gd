static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if !status_effect.ON_HIT: runEffects(target, status_effect)

static func applyHitEffects(target: ResCombatant, _caster: ResCombatant, _value, status_effect: ResStatusEffect):
	runEffects(target, status_effect)

static func runEffects(target: ResCombatant, status_effect: ResStatusEffect):
	for effect in status_effect.BASIC_EFFECTS:
		if effect is ResStatChangeEffect and checkApplyOnce(effect, status_effect):
			changeStat(effect, status_effect)
		elif effect is ResStatusDamageEffect and checkApplyOnce(effect, status_effect):
			CombatGlobals.calculateRawDamage(status_effect.afflicted_combatant, CombatGlobals.useDamageFormula(status_effect.afflicted_combatant, effect.damage), null, true, effect.crit_chance, false, effect.variation, null, effect.trigger_on_hits)
		elif effect is ResStatusCommandAbility:
			CombatGlobals.execute_ability.emit(target, effect.ability)

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if target.STAT_MODIFIERS.has(status_effect.NAME):
		CombatGlobals.resetStat(target, status_effect.NAME)

static func checkApplyOnce(effect: ResBasicEffect, status_effect: ResStatusEffect):
	if (!effect.apply_once) or (effect.apply_once and status_effect.APPLY_ONCE):
		var message
		if effect.message != '':
			message = effect.message
		else:
			message = status_effect.NAME
		CombatGlobals.manual_call_indicator.emit(status_effect.afflicted_combatant, message, 'Show')
		return true
	else:
		return false

static func changeStat(effect: ResStatChangeEffect, status_effect: ResStatusEffect):
	var scale
	if effect.rank_scaling:
		scale = status_effect.current_rank
	else:
		scale = 0
	
	CombatGlobals.modifyStat(status_effect.afflicted_combatant, effect.getStatChanges(scale), status_effect.NAME)
