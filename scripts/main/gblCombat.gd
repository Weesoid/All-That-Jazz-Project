extends Node

signal ability_executed
signal exp_updated(value: float, max_value: float)
signal call_indicator(target: ResCombatant, indicator: String, value: int)

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
func calculateDamage(caster: ResCombatant, target:ResCombatant, attacker_stat: String, defender_stat: String, base_damage, bonus_scaling):
	base_damage += caster.STAT_VALUES[attacker_stat] * bonus_scaling
	var damage = ((base_damage + (caster.STAT_VALUES[attacker_stat] * bonus_scaling)) * ((100.0) / (100.0+target.STAT_VALUES[defender_stat]))) * getDamageMultiplier(caster, target)
	target.STAT_VALUES['health'] -= int(damage)
	playAndResetAnimation(target, 'Hit')
	call_indicator.emit(target, 'Hit!', int(damage))
	target.updateHealth()
	
func calculateHealing(caster: ResCombatant, target:ResCombatant, healing_stat: String, base_healing, bonus_scaling):
	var healing = base_healing + (caster.STAT_VALUES[healing_stat] * bonus_scaling)
	
	if target.STAT_VALUES['health'] + healing > target.getMaxHealth():
		target.STAT_VALUES['health'] = target.getMaxHealth()
	else:
		target.STAT_VALUES['health'] += healing
	
	call_indicator.emit(target, 'Healed!', healing)
	target.updateHealth()
	
func getDamageMultiplier(caster: ResCombatant, target:ResCombatant):
	if !caster.isEquipped('weapon') or caster.EQUIPMENT['weapon'].DAMAGE_TYPE == caster.EQUIPMENT['weapon'].DamageType.NEUTRAL:
		if !target.isEquipped('armor'):
			return 1.0
		if target.EQUIPMENT['armor'].ARMOR_TYPE == target.EQUIPMENT['armor'].ArmorType.LIGHT:
			print('Resisted!')
			return 0.5
		elif target.EQUIPMENT['armor'].ARMOR_TYPE == target.EQUIPMENT['armor'].ArmorType.HEAVY:
			print('Resisted!')
			return 0.25
	
	elif caster.EQUIPMENT['weapon'].DAMAGE_TYPE == caster.EQUIPMENT['weapon'].DamageType.BLUNT: 
		if !target.isEquipped('armor'):
			print('Effective!')
			return 2.0
		if target.EQUIPMENT['armor'].ARMOR_TYPE == target.EQUIPMENT['armor'].ArmorType.LIGHT:
			print('Resisted!')
			return 0.75
		elif target.EQUIPMENT['armor'].ARMOR_TYPE == target.EQUIPMENT['armor'].ArmorType.HEAVY:
			print('Effective!')
			return 1.75
	
	elif caster.EQUIPMENT['weapon'].DAMAGE_TYPE == caster.EQUIPMENT['weapon'].DamageType.EDGED:
		if !target.isEquipped('armor'):
			print('Effective!')
			return 2.0
		if target.EQUIPMENT['armor'].ARMOR_TYPE == target.EQUIPMENT['armor'].ArmorType.LIGHT:
			print('Effective!')
			return 1.75
		elif target.EQUIPMENT['armor'].ARMOR_TYPE == target.EQUIPMENT['armor'].ArmorType.HEAVY:
			print('Resisted!')
			return 0.5
	
	else: 
		print('Neutral!!')
		return 1.0

func modifyStat(target: ResCombatant, stat: String, percent_scale: float):
	target.STAT_VALUES[stat] += target.STAT_VALUES[stat] * percent_scale
	
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
	status_effect.afflicted_combatant = target
	status_effect.initializeStatus()
	target.STATUS_EFFECTS.append(status_effect)
	
func rankUpStatusEffect(afflicted_target: ResCombatant, status_effect: ResStatusEffect):
	for effect in afflicted_target.STATUS_EFFECTS:
		if effect.NAME == status_effect.NAME:
			effect.duration = effect.MAX_DURATION
		if effect.current_rank != effect.MAX_RANK and effect.MAX_RANK != 0:
			effect.APPLY_ONCE = true
			effect.current_rank += 1
	
