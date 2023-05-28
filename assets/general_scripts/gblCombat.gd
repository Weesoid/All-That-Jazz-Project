extends Node

signal ability_executed

#********************************************************************************
# COMBAT PROGRESSION / SIGNALS
#********************************************************************************
func emit_ability_executed():
	ability_executed.emit()
	
#********************************************************************************
# ABILITY EFFECTS & UTILITY
#********************************************************************************
func calculateDamage(caster: ResCombatant, target:ResCombatant, attacker_stat: String, defender_stat: String, base_damage, bonus_scaling):
	var damage = ((base_damage + caster.STAT_VALUES[attacker_stat] * bonus_scaling) * 100 ) / (100+target.STAT_VALUES[defender_stat])
	target.STAT_VALUES['health'] -= int(damage)
	playAndResetAnimation(target, 'Hit')
	playIndicatorAnimation(target, 'Hit!', damage)
	
func calculateHealing(caster: ResCombatant, target:ResCombatant, healing_stat: String, base_healing, bonus_scaling):
	var healing = base_healing + (caster.STAT_VALUES[healing_stat] * bonus_scaling)
	
	if target.STAT_VALUES['health'] + healing > target.getMaxHealth():
		target.STAT_VALUES['health'] = target.getMaxHealth()
	else:
		target.STAT_VALUES['health'] = target.STAT_VALUES['health'] + healing
	
	playIndicatorAnimation(target, 'Healed!', healing)
	
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
	
func playIndicatorAnimation(target: ResCombatant, indicator: String, value):
	target.playIndicator(str(indicator,' ', int(value)))
	target.updateHealth(target.STAT_VALUES['health'])
	
#********************************************************************************
# STATUS EFFECT HANDLING
#********************************************************************************
func loadStatusEffect(status_effect_name: String)-> ResStatusEffect:
	return load(str("res://assets/status_effects_resources/st"+status_effect_name+".tres")).duplicate()
	
func addStatusEffect(target: ResCombatant, status_effect: ResStatusEffect):
	status_effect.initializeStatus()
	status_effect.afflicted_combatant = target
	target.STATUS_EFFECTS.append(status_effect)
	status_effect.addStatusEffectIcon()
	
func rankUpStatusEffect(afflicted_target: ResCombatant, status_effect: ResStatusEffect):
	for effect in afflicted_target.STATUS_EFFECTS:
		if effect.NAME == status_effect.NAME: 
			effect.duration = effect.MAX_DURATION
		if effect.current_rank != effect.MAX_RANK:
			effect.APPLY_ONCE = true
			effect.current_rank += 1
	
