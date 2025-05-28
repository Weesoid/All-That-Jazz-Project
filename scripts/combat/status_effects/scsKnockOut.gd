static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.APPLY_ONCE and !target.hasStatusEffect('Deathmark'):
		target.SCENE.moveTo(target.SCENE.get_parent(), 0.25, Vector2(0,0), true)
		CombatGlobals.modifyStat(target, {'hustle': -999}, status_effect.NAME)
		CombatGlobals.playKnockOutTween(target)
		target.SCENE.collision.disabled = true
		if target is ResPlayerCombatant:
			if target.SCENE.weapon != null: target.SCENE.weapon.hide()
#		target.SCENE.playIdle('KO')

static func endEffects(target: ResCombatant, status_effect: ResStatusEffect):
	if CombatGlobals.getCombatScene().combat_result >= 1 and (target is ResPlayerCombatant and target.MANDATORY): 
		CombatGlobals.calculateHealing(target, int(target.BASE_STAT_VALUES['health']*0.25))
		CombatGlobals.playSecondWindTween(target)
#		target.SCENE.playIdle('Idle')
		applyFaded(target)
	elif CombatGlobals.getCombatScene().combat_result == 0:
		applyFaded(target)
	CombatGlobals.resetStat(target, status_effect.NAME)

static func applyFaded(target: ResCombatant):
#	var concluded_combat = CombatGlobals.getCombatScene().combat_result != 0
	if getFadedLevel(target) == 0:
		print('Plah')
		target.LINGERING_STATUS_EFFECTS.append('Faded I')
	elif getFadedLevel(target) < 4:
		var escalated_level = getFadedLevel(target)+1
		CombatGlobals.addStatusEffect(target, applyFadedStatus(escalated_level))
		target.LINGERING_STATUS_EFFECTS.erase(applyFadedStatus(escalated_level-1, true))
		CombatGlobals.removeStatusEffect(target, applyFadedStatus(escalated_level-1, true))

static func getFadedLevel(target: ResCombatant):
	if target.hasStatusEffect('Faded I') or target.LINGERING_STATUS_EFFECTS.has('Faded I'):
		return 1
	elif target.hasStatusEffect('Faded II') or target.LINGERING_STATUS_EFFECTS.has('Faded II'):
		return 2
	elif target.hasStatusEffect('Faded III') or target.LINGERING_STATUS_EFFECTS.has('Faded III'):
		return 3
	elif target.hasStatusEffect('Faded IV') or target.LINGERING_STATUS_EFFECTS.has('Faded IV'):
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
