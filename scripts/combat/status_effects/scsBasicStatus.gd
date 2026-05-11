static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.effect_type != ResStatusEffect.EffectType.ON_HIT: 
		runEffects(target, status_effect)

static func applyOnHitEffects(target: ResCombatant, _caster: ResCombatant, _value, status_effect: ResStatusEffect):
	runEffects(target, status_effect)

static func runEffects(target: ResCombatant, status_effect: ResStatusEffect):
	for effect in status_effect.basic_effects:
		if effect.apply_on_expiry: continue
		run(effect,target,status_effect)

static func run(effect,target,status_effect):
	if effect.sound_effect != '': 
		OverworldGlobals.playSound(effect.sound_effect)
	if effect is ResStatChangeEffect and checkApplyOnce(effect, status_effect):
		changeStat(effect, status_effect,target)
	elif effect is ResStatusDamageEffect and checkApplyOnce(effect, status_effect):
		var damage = effect.damage
		if effect.rank_scaling:
			damage *= status_effect.current_rank
		effect.bonus_stats['is_dot']=true
		CombatGlobals.calculateRawDamage(
			status_effect.afflicted_combatant, 
			damage, 
			null,
			true, 
			effect.crit_chance, 
			effect.variation, 
			effect.trigger_on_hits, 
			effect.sound_path,
			effect.indicator_bb,
			effect.bonus_stats,
			effect.use_damage_formula
			)
	elif effect is ResStatusCommandAbility:
		CombatGlobals.execute_ability.emit(target, effect.ability)
	elif effect is ResStatusAddStatus:
		CombatGlobals.addStatusEffect(target, effect.status_effect)

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	var expiry_effects = status_effect.basic_effects.filter(func(effect): return effect.apply_on_expiry)
	if target.stat_modifiers.has(status_effect.name):
		CombatGlobals.resetStat(target, status_effect.name)
	print('is val?! ', CombatGlobals.getCombatScene().isCombatValid())
	if !CombatGlobals.getCombatScene().isCombatValid():
		return
	
	print('running expiries!')
	for effect in expiry_effects:
		run(effect, target, status_effect)

static func checkApplyOnce(effect: ResBasicEffect, status_effect: ResStatusEffect):
	if (!effect.apply_once) or (effect.apply_once and status_effect.apply_once):
		var message = ''
		if effect.message != '' and avoidMessageSpam(status_effect):
			message = effect.message
		if message != '':
			CombatGlobals.manual_call_indicator.emit(status_effect.afflicted_combatant, message, 'Show')
		
		return true
	else:
		return false

static func avoidMessageSpam(status_effect: ResStatusEffect):
	return (status_effect.tick_any_turn and status_effect.apply_once) or !status_effect.tick_any_turn

static func changeStat(effect: ResStatChangeEffect, status_effect: ResStatusEffect,target:ResCombatant):
	var scale
	if effect.rank_scaling:
		scale = status_effect.current_rank
	else:
		scale = 0
	
#	if status_effect.lingers and target is ResPlayerCombatant and !target.temperment.has(CombatGlobals.getTempermentModiferID(status_effect,effect.status_change)):
#		target.temperment.append(CombatGlobals.getTempermentModiferID(status_effect,effect.status_change))
#		target.applyTemperments()
#	elif !status_effect.lingers:
	CombatGlobals.modifyStat(
		status_effect.afflicted_combatant, 
		effect.getStatChanges(scale), 
		status_effect.name
		)
