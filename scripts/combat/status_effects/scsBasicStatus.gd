static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.effect_type != 1: 
		runEffects(target, status_effect)

static func applyHitEffects(target: ResCombatant, _caster: ResCombatant, _value, status_effect: ResStatusEffect):
	runEffects(target, status_effect)

static func runEffects(target: ResCombatant, status_effect: ResStatusEffect):
	for effect in status_effect.basic_effects:
		if effect.sound_effect != '': 
			OverworldGlobals.playSound(effect.sound_effect)
		if effect is ResStatChangeEffect and checkApplyOnce(effect, status_effect):
			changeStat(effect, status_effect)
		elif effect is ResStatusDamageEffect and checkApplyOnce(effect, status_effect):
			CombatGlobals.calculateRawDamage(status_effect.afflicted_combatant, CombatGlobals.useDamageFormula(status_effect.afflicted_combatant, effect.damage), null, true, effect.crit_chance, false, effect.variation, null, effect.trigger_on_hits, effect.sound_path)
		elif effect is ResStatusCommandAbility:
			CombatGlobals.execute_ability.emit(target, effect.ability)

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if target.stat_modifiers.has(status_effect.name):
		CombatGlobals.resetStat(target, status_effect.name)

static func checkApplyOnce(effect: ResBasicEffect, status_effect: ResStatusEffect):
	if (!effect.apply_once) or (effect.apply_once and status_effect.apply_once):
		var message = ''
		if effect.message != '' and avoidMessageSpam(status_effect):
			message = effect.message
		elif avoidMessageSpam(status_effect):
			message = status_effect.name
		if message != '':
			CombatGlobals.manual_call_indicator.emit(status_effect.afflicted_combatant, message, 'Show')
		
		return true
	else:
		return false

static func avoidMessageSpam(status_effect: ResStatusEffect):
	return (status_effect.tick_any_turn and status_effect.apply_once) or !status_effect.tick_any_turn

static func changeStat(effect: ResStatChangeEffect, status_effect: ResStatusEffect):
	var scale
	if effect.rank_scaling:
		scale = status_effect.current_rank
	else:
		scale = 0
	
	CombatGlobals.modifyStat(status_effect.afflicted_combatant, effect.getStatChanges(scale), status_effect.name)
