extends Node

signal ability_executed
signal secondary_ability_executed
signal exp_updated(value: float, max_value: float)
signal manual_call_indicator(combatant: ResCombatant, text: String, animation: String)
signal call_indicator(animation: String, combatant: ResCombatant)
signal execute_ability(target, ability: ResAbility)

#********************************************************************************
# COMBAT PROGRESSION / SIGNALS
#********************************************************************************
func emit_ability_executed():
	ability_executed.emit()

func emit_exp_updated(value, max_value):
	exp_updated.emit(value, max_value)
	
#********************************************************************************
# ABILITY EFFECTS & UTILITY
#********************************************************************************
func calculateDamage(caster: ResCombatant, target:ResCombatant, attacker_stat: String, defender_stat: String, base_damage, bonus_scaling, damage_type: ResDamageType, can_miss = true, can_crit = true):
	if randomRoll(caster.STAT_VALUES['accuracy']) and can_miss:
		damageTarget(caster, target, base_damage, bonus_scaling, attacker_stat, defender_stat, damage_type, can_crit)
	elif can_miss:
		manual_call_indicator.emit(target, 'Whiff!', 'Whiff')
		call_indicator.emit('Show', target)
	else:
		damageTarget(caster, target, base_damage, bonus_scaling, attacker_stat, defender_stat, damage_type, can_crit)

func calculateHealing(caster: ResCombatant, target:ResCombatant, healing_stat: String, base_healing, bonus_scaling):
	var healing = base_healing + (caster.STAT_VALUES[healing_stat] * bonus_scaling) # Multiply by heal multplier
	healing = valueVariate(healing, 0.1)
	healing *= target.STAT_VALUES['heal mult']
	
	if target.STAT_VALUES['health'] + healing > target.getMaxHealth():
		target.STAT_VALUES['health'] = target.getMaxHealth()
	else:
		target.STAT_VALUES['health'] += healing
	
	call_indicator.emit('Show', target)

func damageTarget(caster: ResCombatant, target: ResCombatant, base_damage, bonus_scaling, attacker_stat: String, defender_stat: String, damage_type: ResDamageType, can_crit: bool):
	# Raw Damage Calculation
	base_damage += caster.STAT_VALUES[attacker_stat] * bonus_scaling
	var damage = (base_damage) * ((100.0) / (100.0+target.STAT_VALUES[defender_stat]))
	var multiplier = getDamageMultiplier(damage_type, getCombatantArmorType(target))
	if multiplier > 1.0:
		manual_call_indicator.emit(target, 'WALLOP!!!', 'Wallop')
	elif multiplier < 1.0:
		manual_call_indicator.emit(target, 'RESISTED!', 'Resist')
	damage *= multiplier
	
	# RNG Rolls
	damage = valueVariate(damage, 0.15)
	damage_type.rollEffect(target)
	if randomRoll(caster.STAT_VALUES['crit']) and can_crit:
		damage *= 2.0
		manual_call_indicator.emit(target, 'CRITICAL!!!', 'Crit')
		call_indicator.emit('Show', target)
	else:
		call_indicator.emit('Show', target)
	
	# Damage target
	target.STAT_VALUES['health'] -= int(damage)
	playAndResetAnimation(target, 'Hit')

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

func loadDamageType(damage_type_name: String)-> ResDamageType:
	return load(str("res://resources/damage_types/"+damage_type_name+".tres"))

func loadArmorType(armor_type_name: String)-> ResArmorType:
	return load(str("res://resources/armor_types/"+armor_type_name+".tres"))

func getDamageMultiplier(damage_type: ResDamageType, armor_type: ResArmorType):
	if armor_type == null:
		return loadArmorType('Unarmored').getMultiplier(damage_type)
	
	return armor_type.getMultiplier(damage_type)

func getCombatantArmorType(combatant: ResCombatant):
	if combatant.isEquipped('armor'):
		return combatant.EQUIPMENT['armor'].ARMOR_TYPE
	
	return null

func modifyStat(target: ResCombatant, stat: String, percent_scale: float):
	target.STAT_VALUES[stat] += target.STAT_VALUES[stat] * percent_scale

func modifyStatFlat(target: ResCombatant, stat: String, value: float):
	target.STAT_VALUES[stat] += value
	if target.STAT_VALUES[stat] < 0:
		target.STAT_VALUES[stat] = 0

func resetStat(target: ResCombatant, stat: String):
	target.STAT_VALUES[stat] = target.BASE_STAT_VALUES[stat]
	
#********************************************************************************
# ANIMATION HANDLING
#********************************************************************************
func playSingleTargetAnimation(target:ResCombatant, animation_scene):
	animation_scene.position = target.SCENE.global_position
	animation_scene.get_node('AnimationPlayer').play('Execute')
	
func playAndResetAnimation(target: ResCombatant, animation_name: String):
	target.getAnimator().play(animation_name)
	await target.getAnimator().animation_finished
	target.getAnimator().play('Idle')
	
#********************************************************************************
# STATUS EFFECT HANDLING
#********************************************************************************
func loadStatusEffect(status_effect_name: String)-> ResStatusEffect:
	return load(str("res://resources/status_effects/"+status_effect_name+".tres")).duplicate()
	
func addStatusEffect(target: ResCombatant, status_effect: ResStatusEffect):
	if status_effect.NAME not in target.getStatusEffectNames():
		status_effect.afflicted_combatant = target
		status_effect.initializeStatus()
		target.STATUS_EFFECTS.append(status_effect)
	else:
		rankUpStatusEffect(target, status_effect)
	
	checkReactions(target)

func checkReactions(target: ResCombatant):
	print(target.getStatusEffectNames())
	if target.getStatusEffectNames().has('Singed') and target.getStatusEffectNames().has('Poison'):
		execute_ability.emit(target, preload("res://resources/abilities/ReactionCauterize.tres"))
		removeStatusEffect(target, 'Singed')
		removeStatusEffect(target, 'Poison')
	elif target.getStatusEffectNames().has('Singed') and target.getStatusEffectNames().has('Chilled'):
		runReaction(target, 'Singed', 'Chilled', preload("res://resources/abilities/ReactionScald.tres"))
	elif target.getStatusEffectNames().has('Jolted') and target.getStatusEffectNames().has('Poison'):
		runReaction(target, 'Jolted', 'Poison', preload("res://resources/abilities/ReactionCatalyze.tres"))
	elif target.getStatusEffectNames().has('Singed') and target.getStatusEffectNames().has('Jolted'):
		execute_ability.emit(target, preload("res://resources/abilities/ReactionCatalyze.tres"))
		removeStatusEffect(target, 'Singed')
		removeStatusEffect(target, 'Jolted')
	elif target.getStatusEffectNames().has('Chilled') and target.getStatusEffectNames().has('Jolted'):
		runReaction(target, 'Chilled', 'Jolted', preload("res://resources/abilities/ReactionDisrupt.tres"))
	elif target.getStatusEffectNames().has('Chilled') and target.getStatusEffectNames().has('Poison'):
		runReaction(target, 'Chilled', 'Poison', preload("res://resources/abilities/ReactionVulnerate.tres"))
	# DISRUPT (Cold shocking)


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
