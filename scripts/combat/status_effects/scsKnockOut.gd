static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.apply_once and !target.hasStatusEffect('Deathmark'):
		target.combatant_scene.moveTo(target.combatant_scene.get_parent(), 0.25, Vector2(0,0), true)
		CombatGlobals.modifyStat(target, {'hustle': -999}, status_effect.name)
		CombatGlobals.playKnockOutTween(target)
		target.combatant_scene.collision.disabled = true
		if target is ResPlayerCombatant:
			if target.combatant_scene.weapon != null: target.combatant_scene.weapon.hide()
		target.combatant_scene.playIdle('KO')

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if CombatGlobals.getCombatScene().combat_result >= 1 and (target is ResPlayerCombatant and target.mandatory): 
		CombatGlobals.calculateHealing(target, int(target.base_stat_values['health']*0.25))
		CombatGlobals.playSecondWindTween(target)
		target.combatant_scene.playIdle('Idle')
		applyFaded(target)
	elif CombatGlobals.getCombatScene().combat_result == 0:
		applyFaded(target)
	CombatGlobals.resetStat(target, status_effect.name)

static func applyFaded(target: ResCombatant):
#	var concluded_combat = CombatGlobals.getCombatScene().combat_result != 0
	if getFadedLevel(target) == 0:
		#print('Plah')
		target.lingering_effects.append('Faded I')
	elif getFadedLevel(target) < 4:
		var escalated_level = getFadedLevel(target)+1
		CombatGlobals.addStatusEffect(target, applyFadedStatus(escalated_level))
		target.lingering_effects.erase(applyFadedStatus(escalated_level-1, true))
		CombatGlobals.removeStatusEffect(target, applyFadedStatus(escalated_level-1, true))

static func getFadedLevel(target: ResCombatant):
	if target.hasStatusEffect('Faded I') or target.lingering_effects.has('Faded I'):
		return 1
	elif target.hasStatusEffect('Faded II') or target.lingering_effects.has('Faded II'):
		return 2
	elif target.hasStatusEffect('Faded III') or target.lingering_effects.has('Faded III'):
		return 3
	elif target.hasStatusEffect('Faded IV') or target.lingering_effects.has('Faded IV'):
		return 4
	else:
		return 0

static func applyFadedStatus(level: int, add_space:bool=false):
	var out = ''
	match level:
		1: out = 'FadedI'
		2: out =  'FadedII'
		3: out =  'FadedIII'
		4: out =  'FadedIV'
	if add_space:
		out = out.insert(5, ' ')
	return out
