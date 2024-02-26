extends Node

signal combat_won(unique_id)
signal combat_lost(unique_id)
signal turn_increment(count)
signal ability_used(ability)
signal combatant_stats(combatant)
signal combat_conclusion_dialogue(dialogue, result)
signal animation_done

signal exp_updated(value: float, max_value: float)
signal received_combatant_value(combatant: ResCombatant, caster: ResCombatant, value)
signal manual_call_indicator(combatant: ResCombatant, text: String, animation: String)
signal call_indicator(animation: String, combatant: ResCombatant)
signal execute_ability(target, ability: ResAbility)
signal qte_finished()

#********************************************************************************
# COMBAT PROGRESSION / SIGNALS
#********************************************************************************
func emit_exp_updated(value, max_value):
	exp_updated.emit(value, max_value)

#********************************************************************************
# ABILITY EFFECTS & UTILITY
#********************************************************************************
## Calculate damage using basic formula and parameters
func calculateDamage(caster: ResCombatant, target:ResCombatant, base_damage, can_miss = true, can_crit = true):
	if randomRoll(caster.STAT_VALUES['accuracy']) and can_miss:
		if randomRoll(1.0 - target.STAT_VALUES['dodge']):
			damageTarget(caster, target, base_damage, can_crit)
		else:
			manual_call_indicator.emit(target, 'Dodged!', 'Whiff')
			call_indicator.emit('Show', target)
	elif can_miss:
		manual_call_indicator.emit(target, 'Whiff!', 'Whiff')
		call_indicator.emit('Show', target)
	else:
		damageTarget(caster, target, base_damage, can_crit)

## Calculate damage using custom formula and parameters
func calculateRawDamage(target: ResCombatant, damage, can_crit = false, caster: ResCombatant = null, crit_chance = -1.0, can_miss = false, variation = -1.0, message = null, trigger_on_hits = false):
	if can_miss and !randomRoll(caster.STAT_VALUES['accuracy']):
		manual_call_indicator.emit(target, 'Whiff!', 'Whiff')
		return
	
	if variation != -1.0:
		damage = valueVariate(damage, variation)
	
	if can_crit:
		if caster != null and randomRoll(caster.STAT_VALUES['crit']):
			damage *= 2.0
			manual_call_indicator.emit(target, 'CRITICAL!!!', 'Crit')
			call_indicator.emit('Show', target)
		elif crit_chance != -1.0 and randomRoll(crit_chance):
			damage *= 2.0
			manual_call_indicator.emit(target, 'CRITICAL!!!', 'Crit')
			call_indicator.emit('Show', target)
	else:
		call_indicator.emit('Show', target)
	
	if message != null:
		manual_call_indicator.emit(target, "%s %s" % [int(damage), message], 'Show')
	
	target.STAT_VALUES['health'] -= int(damage)
	if trigger_on_hits: received_combatant_value.emit(target, caster, int(damage))
	playAndResetAnimation(target, 'Hit')

func damageTarget(caster: ResCombatant, target: ResCombatant, base_damage, can_crit: bool):
	base_damage += caster.STAT_VALUES['brawn'] * base_damage
	base_damage -= caster.STAT_VALUES['grit'] * base_damage
	
	base_damage = valueVariate(base_damage, 0.15)
	if randomRoll(caster.STAT_VALUES['crit']) and can_crit:
		base_damage *= 2.0
		manual_call_indicator.emit(target, 'CRITICAL!!!', 'Crit')
		call_indicator.emit('Show', target)
	else:
		call_indicator.emit('Show', target)
	
	target.STAT_VALUES['health'] -= int(base_damage)
	received_combatant_value.emit(target, caster, int(base_damage))
	playAndResetAnimation(target, 'Hit')

func calculateHealing(caster: ResCombatant, target:ResCombatant, healing_stat: String, base_healing):
	base_healing += caster.STAT_VALUES[healing_stat] * base_healing
	base_healing = valueVariate(base_healing, 0.15)
	base_healing *= target.STAT_VALUES['heal mult']
	
	if target.STAT_VALUES['health'] + base_healing > target.getMaxHealth():
		target.STAT_VALUES['health'] = target.getMaxHealth()
	else:
		manual_call_indicator.emit(target, "%s HEALED!" % [int(base_healing)], 'Heal')
		target.STAT_VALUES['health'] += int(base_healing)
	
	received_combatant_value.emit(target, caster, int(base_healing))
	call_indicator.emit('Show', target)

func randomRoll(percent_chance: float):
	assert(percent_chance <= 1.0 and percent_chance >= 0, "% chance must be between 0 to 1")
	percent_chance = 1.0 - percent_chance
	randomize()
	var roll = randf_range(0, 1.0)
	if roll > percent_chance:
		return true
	else:
		return false

func valueVariate(value, percent_variance: float):
	var variation = value * percent_variance
	randomize()
	value += randf_range(variation*-1, variation)
	return value

func modifyStat(target: ResCombatant, stat_modifications: Dictionary, modifier_id: String):
	target.removeStatModification(modifier_id)
	target.STAT_MODIFIERS[modifier_id] = stat_modifications
	target.applyStatModifications(modifier_id)

func resetStat(target: ResCombatant, modifier_id: String):
	target.removeStatModification(modifier_id)

#********************************************************************************
# ANIMATION HANDLING
#********************************************************************************
func playAbilityAnimation(target:ResCombatant, animation_scene, time=0.0):
	var animation = animation_scene.instantiate()
	target.SCENE.add_child(animation)
	animation.playAnimation(target.SCENE.position)
	if time > 0.0:
		await get_tree().create_timer(time).timeout
		animation_done.emit()

func playAndResetAnimation(target: ResCombatant, animation_name: String):
	target.getAnimator().play(animation_name)
	await target.getAnimator().animation_finished
	if !target.isDead():
		target.getSprite().modulate.a = 1.0
		target.getAnimator().play('Idle')
	else:
		target.getSprite().modulate.a = 0.5
		target.getAnimator().play('KO')

func playAnimation(target: ResCombatant, animation_name: String):
	target.getAnimator().play(animation_name)

#********************************************************************************
# STATUS EFFECT HANDLING
#********************************************************************************
func loadStatusEffect(status_effect_name: String)-> ResStatusEffect:
	return load(str("res://resources/status_effects/"+status_effect_name+".tres")).duplicate()

func addStatusEffect(target: ResCombatant, status_effect_name: String, tick_on_apply=false, base_chance = 2.0):
	#if base_chance != 2.0 and !randomRoll(base_chance-target.STAT_VALUES['exposure']):
	#	manual_call_indicator.emit(target, '%s  Resisted!' % status_effect_name, 'Whiff')
	#	return
	
	var status_effect: ResStatusEffect = load(str("res://resources/combat/status_effects/"+status_effect_name+".tres")).duplicate()
	if status_effect.NAME not in target.getStatusEffectNames():
		status_effect.afflicted_combatant = target
		status_effect.initializeStatus()
		target.STATUS_EFFECTS.append(status_effect)
		if tick_on_apply:
			status_effect.tick()
	else:
		rankUpStatusEffect(target, status_effect)
		if tick_on_apply:
			target.getStatusEffect(status_effect.NAME).tick()
	
	if status_effect.LINGERING and target is ResPlayerCombatant and !target.LINGERING_STATUS_EFFECTS.has(status_effect.NAME):
		target.LINGERING_STATUS_EFFECTS.append(status_effect.NAME)
	
	checkReactions(target)

func checkReactions(target: ResCombatant):
	if target.getStatusEffectNames().has('Singed') and target.getStatusEffectNames().has('Poison'):
		execute_ability.emit(target, load("res://resources/abilities_reactions/Cauterize.tres"))
		removeStatusEffect(target, 'Singed')
		removeStatusEffect(target, 'Poison')
	elif target.getStatusEffectNames().has('Singed') and target.getStatusEffectNames().has('Chilled'):
		runReaction(target, 'Singed', 'Chilled', load("res://resources/abilities/Scald.tres"))
	elif target.getStatusEffectNames().has('Jolted') and target.getStatusEffectNames().has('Poison'):
		runReaction(target, 'Jolted', 'Poison', load("res://resources/abilities_reactions/Catalyze.tres"))
	elif target.getStatusEffectNames().has('Singed') and target.getStatusEffectNames().has('Jolted'):
		execute_ability.emit(target, load("res://resources/abilities_reactions/Fulgurate.tres"))
		removeStatusEffect(target, 'Singed')
		removeStatusEffect(target, 'Jolted')
	elif target.getStatusEffectNames().has('Chilled') and target.getStatusEffectNames().has('Jolted'):
		runReaction(target, 'Chilled', 'Jolted', load("res://resources/abilities_reactions/Disrupt.tres"))
	elif target.getStatusEffectNames().has('Chilled') and target.getStatusEffectNames().has('Poison'):
		runReaction(target, 'Chilled', 'Poison', load("res://resources/abilities_reactions/Vulnerate.tres"))

func runReaction(target: ResCombatant, effectA: String, effectB: String, reaction: ResAbility):
	removeStatusEffect(target, effectA)
	removeStatusEffect(target, effectB)
	execute_ability.emit(target, reaction)

func rankUpStatusEffect(afflicted_target: ResCombatant, status_effect: ResStatusEffect):
	for effect in afflicted_target.STATUS_EFFECTS:
		if effect.NAME == status_effect.NAME:
			effect.duration = effect.MAX_DURATION
		if effect.current_rank != effect.MAX_RANK and effect.MAX_RANK != 0:
			effect.APPLY_ONCE = true
			effect.current_rank += 1

func removeStatusEffect(target: ResCombatant, status_name: String):
	for status in target.STATUS_EFFECTS:
		if status.NAME == status_name:
			status.removeStatusEffect()
			return

func getCombatScene()-> CombatScene:
	return get_parent().get_node('CombatScene')
