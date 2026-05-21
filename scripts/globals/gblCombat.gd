extends Node

enum Enemy_Factions {
	Scavs
}
var FACTION_PATROLLER_PROPERTIES = {
	Enemy_Factions.Scavs: load("res://resources/combat/faction_patrollers/Scavs.tres")
}
var back_up_enemies = [
	'res://resources/combat/combatants_enemies/mercenaries/'
]
const OtherStats = {
	'heal_skill': 'heal_skill'
}

var tension: int = 0
var critical_bb = '[img color=red]res://images/status_icons/icon_crit_eye.png[/img][color=red]'
signal combat_won(unique_id)
signal combat_lost(unique_id)
signal dialogue_signal(flag)
signal combat_conclusion_dialogue(dialogue, result)
signal animation_done
signal exp_updated(value: float, max_value: float)
signal received_combatant_value(combatant: ResCombatant, caster: ResCombatant, value)
signal manual_call_indicator(combatant: ResCombatant, text: String, animation: String)
signal status_effect_added(combatant: ResCombatant, status_effect: ResStatusEffect)
signal status_effect_removed(combatant: ResCombatant, status_effect: ResStatusEffect)
#signal manual_call_indicator_bb(combatant: ResCombatant, text: String, animation: String, bb: String)
signal execute_ability(target, ability: ResAbility)
signal qte_finished()
signal ability_finished
signal ability_casted(ability: ResAbility)
#signal active_combatant_changed(combatant: ResCombatant)
signal tension_changed(previous_tension,current_tension,from_target)
signal extra_stat_added(combatant,stat)
signal ability_selected(ability)
signal ability_cancelled(ability)

# To be added
signal health_changed(health, combatant)
signal tp_changed(health, combatant)


#********************************************************************************
# COMBAT PROGRESSION / SIGNALS
#********************************************************************************
func emit_exp_updated(value, max_value):
	exp_updated.emit(value, max_value)

#********************************************************************************
# ability EFFECTS & UTILITY
#********************************************************************************
## Calculate damage using basic formula and parameters
func calculateDamage(caster, target, modifier, can_crit = true, sound:String='', indicator_bb_code: String='', attack_bonuses: Dictionary={}):
	if caster is CombatantScene:
		caster = caster.combatant_resource
	if target is CombatantScene:
		target = target.combatant_resource
	
	damageTarget(caster, target, modifier, can_crit, sound, indicator_bb_code, attack_bonuses)

## Calculate damage using custom formula and parameters
func calculateRawDamage(target, damage, caster: ResCombatant = null, can_crit = false, crit_chance = -1.0, variation = -1.0, trigger_on_hits = false, sound:String='', indicator_bb_code:String='', attack_bonuses:Dictionary={}):
	if !target is ResCombatant:
		target = target.combatant_resource
	var bonus_crit = attack_bonuses.get('crit',0)
	damage += attack_bonuses.get('damage',0)
	if target.stat_modifiers.has('block'):
		damage = 0
	#damage = useDamageFormula(target, damage)
	if variation != -1.0:
		damage = valueVariate(damage, variation)
	if can_crit and ((caster != null and randomRoll(caster.stat_values['crit']+bonus_crit)) or (crit_chance != -1.0 and randomRoll(crit_chance+bonus_crit))):
		damage = doCritEffects(damage, caster, attack_bonuses.get(CombatExtras.CRIT_AMP,0))
		indicator_bb_code += critical_bb
	target.changeHealth(-int(damage))
	#target.stat_values['health'] -= int(damage)
	doPostDamageEffects(caster, target, damage, sound, indicator_bb_code, trigger_on_hits, attack_bonuses)

## Basic damage calculations
func damageTarget(caster: ResCombatant, target: ResCombatant, modifier:float, can_crit: bool, sound:String='', indicator_bb_code: String='', attack_bonuses: Dictionary={}):
	var damage = (caster.stat_values['damage'] + attack_bonuses.get('damage',0)) * calcDamageModifier(caster) * modifier
	damage = valueVariate(damage, caster.stat_values['dmg_variance'])
	if target.stat_modifiers.has('block'):
		damage = 0
	
	if randomRoll(caster.stat_values['crit']+attack_bonuses.get('crit',0)) and can_crit:
		damage = doCritEffects(damage, caster, attack_bonuses.get(CombatExtras.CRIT_AMP,0))
		indicator_bb_code += critical_bb
	if checkSpecialStat('non-lethal', attack_bonuses, target) and target.stat_values['health']-damage <= 0:
		damage = 0
	
	target.changeHealth(-int(damage))
	#target.stat_values['health'] -= int(damage)
	doPostDamageEffects(caster, target, damage, sound, indicator_bb_code, true, attack_bonuses)

func calcDamageModifier(combatant:ResCombatant):
	return (1+combatant.stat_values.get(CombatExtras.DAMAGE_MODIFIER,0))
#
#func getBonusStat(bonus_stats: Dictionary, key: String, target: ResCombatant):
#	pass
#	if hasBonusStat(bonus_stats, key) and checkBonusStatConditions(bonus_stats, key, target):
#		return getBonusStatValue(bonus_stats, key)
#	else:
#		return 0
#
func hasBonusStat(bonus_stats: Dictionary, key: String)-> bool:
	return false
#	var out = []
#	for stat in bonus_stats.keys():
#		out.append(stat.split('/')[0])
#
#	return out.has(key)
#
func getBonusStatValue(bonus_stats: Dictionary, key: String):
	pass
#	for stat in bonus_stats.keys():
#		if stat.split('/')[0] == key: 
#			if bonus_stats[stat] is String and bonus_stats[stat].is_valid_float():
#				return float(bonus_stats[stat])
#			elif bonus_stats[stat] is String and bonus_stats[stat].is_valid_int():
#				return int(bonus_stats[stat])
#			else:
#				return bonus_stats[stat]
#
func checkBonusStatConditions(bonus_stats: Dictionary, key: String, target: ResCombatant)-> bool:
	return false

func getStatChanges(stat_dict:Dictionary):
	var out = {}
	for stat in stat_dict:
		if stat_dict[stat] != 0: out[stat] = stat_dict[stat]
	return out
	
#	var conditions: Array
#	for stat in bonus_stats.keys():
#		if key == stat.split('/')[0] and (stat.split('/').size() > 1):
#			conditions = stat.split('/')
#			conditions.remove_at(0)
#			break
#		elif key == stat.split('/')[0]:
#			return true
#
#	return checkConditions(conditions, target)
#
#func checkConditions(conditions, target: ResCombatant)->bool:
#	if conditions is String:
#		conditions = conditions.split('/')
#	if conditions[0] == '':
#		return true
#
#	for condition in conditions:
#		var condition_data = condition.split(':')
#		#if condition_data.contains()
#		match condition_data[0]:
#			's': # ex. s:bleed or s:guard:2
#				if !target.hasStatusEffect(condition_data[1]): 
#					return false
#
#				var rank_condition = true
#				if condition_data.size() > 2:
#					var operator = '>'
#					if condition_data[2].split(',').size() > 1:
#						operator = condition_data[2].split(',')[1]
#					match operator:
#						'>': rank_condition = target.getStatusEffect(condition_data[1]).current_rank >= int(condition_data[2])
#						'<': rank_condition = target.getStatusEffect(condition_data[1]).current_rank <= int(condition_data[2])
#						'=': rank_condition = target.getStatusEffect(condition_data[1]).current_rank == int(condition_data[2])
#
#				return target.hasStatusEffect(condition_data[1]) and rank_condition
#			'hp': # ex. hp:>:0.5 or hp:<:0.45
#				#print(target.stat_values['health'], ' vs ', float(condition_data[2])*target.getMaxHealth())
#				if condition_data[1] == '>':
#					#print('supple')
#					return target.stat_values['health'] >= float(condition_data[2])*target.getMaxHealth()
#				if condition_data[1] == '<':
#					#print('sex')
#					return target.stat_values['health'] <= float(condition_data[2])*target.getMaxHealth()
#
#			'combo': # ex crit/combo
#				if target.hasStatusEffect('Combo'):
#					target.getStatusEffect('Combo').removeStatusEffect()
#					manual_call_indicator.emit(target, '%s %sCOMBO !' % [loadStatusEffect('Combo').getMessageIcon(),loadStatusEffect('Combo').getIconColor(true)], 'Show')
#					return true
#
#			'combo!': # ex. crit/combo!
#				return target.hasStatusEffect('Combo')
#
#			'%': # ex. crit/%:0.50
#				return randomRoll(float(condition_data[1]))
#
#	#assert(false,'Incorrect format! '+str(conditions))
#	return false
#
#func stringifyBonusStatConditions(conditions: Array, unit:String='Target')->String:
#	for condition in conditions:
#		var condition_data = condition.split(':')
#		match condition_data[0]:
#			's': # ex. s:bleed or s:guard:2
#				return 'If %s '% unit+loadStatusEffect(condition_data[1]).getMessageIcon()
#			'hp': # ex. hp:>:0.5 or hp:<:0.45
#				if condition_data[1] == '>':
#					return 'If %s HP > '% unit+str(float(condition_data[2])*100)+'%'
#				if condition_data[1] == '<':
#					return 'If %s HP < '% unit+str(float(condition_data[2])*100)+'%'
#			'combo': # ex crit/combo
#				return 'If %s %s' % [unit, loadStatusEffect('Combo').getMessageIcon()]
#			'combo!': # ex. crit/combo!
#				return 'If  %s %s' % [unit, loadStatusEffect('Combo').getMessageIcon()]
#			'%': # ex. crit/%:0.50
#				return str(float(condition_data[1])*100)+'% chance to'
#
#	return 'UNKNOWN CONDITION: '+str(conditions)
#
#func stringifySpecialStat(stat: String,value:String):
#	if stat == 'status_effect':
#		var out = 'Apply '
#		for effect in value.split('+'):
#			var effect_data = effect.split('^')
#			effect = effect_data[0]
#			out += loadStatusEffect(effect).getMessageIcon()+' '
#			if effect_data.size() > 1: out += stringifyStatusOverrides(effect_data[1])+' '
#		return out
#	elif stat == 'move':
#		var out = ''
#		var movement = value.split(',')
#		if movement[0] == 'f':
#			out += '[color=dark_turquoise]Pull '
#		elif movement[0] == 'b':
#			out += '[color=dark_turquoise]Push '
#		return out+' '+str(movement[1])+'[/color]'
#	elif stat == 'non-lethal':
#		return 'Non-lethal'
#	elif stat == 'tp':
#		return 'Gain '+value+'[img]res://images/sprites/icon_tp.png[/img]'
#
#func stringifyStatusOverrides(overrides:String):
#	var overrides_dict = JSON.parse_string(overrides)
#	var out = '' # TODO Add color
#	if overrides_dict.has('max_duration') and overrides_dict.has('be_tickdmg'):
#		out += '%s (%s turns)' % [overrides_dict['max_duration'], overrides_dict['be_tickdmg']['damage']]
#
#	return out
#
#func hasStatCondition(key):
#	return key.contains('/')

func doDodgeEffects(caster: ResCombatant, target: ResCombatant, damage):
	caster.removeTokens(ResStatusEffect.RemoveType.MISSED)
	manual_call_indicator.emit(target, 'Whiff!', 'Whiff')
	playDodgeTween(target)
	#checkMissCases(target, caster, damage)

func doCritEffects(base_damage, caster: ResCombatant, bonus_mult:float=0.0):
	var base_mult = 1.5
	if  caster != null:
		var modified_crit_dmg = max(1.1,base_mult+caster.stat_values.get(CombatExtras.CRIT_AMP,0)+bonus_mult)
		base_damage *= (modified_crit_dmg)
	else:
		base_damage *= base_mult+bonus_mult
	base_damage = ceil(base_damage)
	getCombatScene().combat_camera.shake(15.0, 10.0)
	OverworldGlobals.playSound("res://audio/sounds/13_Ice_explosion_01.ogg")
	return base_damage

# TODO Change bonus stats to attack bonuses!
func doPostDamageEffects(caster: ResCombatant, target: ResCombatant, damage, sound: String, indicator_bb_code: String='', trigger_on_hits: bool=true, bonus_stats: Dictionary={}):
	var message = str(int(damage))
	message = indicator_bb_code+message
	
	if indicator_bb_code.contains('crit'):
		manual_call_indicator.emit(target, message, 'Crit')
	elif damage > 0:
		manual_call_indicator.emit(target, message, 'Damage')
	target.removeTokens(ResStatusEffect.RemoveType.GET_HIT)
	if caster != null:
		caster.removeTokens(ResStatusEffect.RemoveType.HIT)
	if trigger_on_hits:
		received_combatant_value.emit(target, caster, int(damage))
		
	## Resolve handling
	if target.isDead() and target.stat_values['resolve'] > 0 and ((bonus_stats.has('is_dot') and !target.resolve_dot_shield) or !bonus_stats.has('is_dot')) and !target.resolve_gate and damage > 0 and !target.stat_modifiers.has('block'): 
		if target.stat_values['resolve'] - 1 <= 0 and randomRoll(target.stat_values.get(CombatExtras.REBUKE_CHANCE,0.0)):
			getCombatScene().doRebuke(target,caster)
		else:
			target.stat_values['resolve'] -= 1
			addInjury(target, 1.0-target.stat_values['resist'])
	elif target.isDead() and target.resolve_gate:
		playBrinkEffects(target)
		#OverworldGlobals.freezeFrame(0.3, 0.5)
		target.resolve_gate=false
		addInjury(target, 1.0-target.stat_values['resist'])
	if target.isDead() and bonus_stats.has('is_dot'): 
		target.resolve_dot_shield = true
	
	if bonus_stats.has('status_effects'):
		for effect in bonus_stats['status_effects']: addStatusEffect(target, effect, false)
	
	if bonus_stats.has('move'):
		var move_data:ResAttackMove = bonus_stats['move']
		getCombatScene().changeCombatantPosition(target, move_data.direction,false,move_data.move_count)
	
	if hasBonusStat(bonus_stats, 'tp') and caster is ResPlayerCombatant:
		pass # DO LATER
		#addTension(getBonusStat(bonus_stats,'tp',target), target.combatant_scene)
	
	playHurtAnimation(target, damage, sound)
	if target.isDead(true):
		addStatusEffect(target,'Knockback',true)
		playKnockOutTween(target)
		target.combatant_scene.collision.set_deferred('disabled',true)
		OverworldGlobals.freezeFrame()

func playBrinkEffects(target):
	if target.getSprite().has_node('Throbber'):
		return
	
	var throbber = load("res://scenes/animations_quick/SpriteThrobber.tscn")
	OverworldGlobals.showQuickAnimation(throbber, target.getSprite())
	target.combatant_scene.playIdle('Hurt')

func removeBrinkEffects(target):
	if target.getSprite().has_node('Throbber'):
		target.getSprite().get_node('Throbber').queue_free()
	target.combatant_scene.playIdle('Idle')

func addInjury(combatant: ResCombatant, chance:float,is_grevious:bool=false):
	if combatant.isDead(true):
		return
	if !randomRoll(chance):
		manual_call_indicator.emit(combatant, SettingsGlobals.ui_colors['up-bb']+'Injury Resisted!', 'Show',true)
		return
	var injuries = {
		'Bum Leg': {'speed':-1},
		'Broken Arm': {'damage':-1},
		'Shellshocked': {'crit':-0.03},
		'Pulled Muscle': {'crit_amp':-0.03},
		'Infected Wound': {'resist':-0.03}
		# Broken ribs: dmg taken +2%
		
	}
	if combatant is ResPlayerCombatant:
		injuries['Concussed'] = {'handling':-1}
	if is_grevious:
		for key in injuries: injuries[key] = multiplyStatModifications(injuries[key],10.0)
	
	var chosen_injury = injuries.keys().pick_random()
	var flag = 'injury' if !is_grevious else 'grevious_injury'
	var append_name = '' if !is_grevious else 'Greviously '
	
	if combatant is ResPlayerCombatant:
		combatant.addTrait(
			append_name+chosen_injury, 
			injuries[chosen_injury],
			{flag:true,'append':true},
			' [img %s]res://images/status_icons/injury.png[/img]'%SettingsGlobals.ui_colors['down-bb'].replace('[','').replace(']','')
			)
	else:
		combatant.addTemporaryModifer(
			chosen_injury,
			1,
			injuries[chosen_injury],
			true,
			true
			)

func removeInjury(combatant: ResPlayerCombatant,chance:float, count:int):
	var injuries = combatant.getTraitsWithFlag('injury')
	if count > injuries.size():
		count = injuries.size()
	for i in range(count):
		var chosen_injury = injuries.pick_random()
		injuries.erase(chosen_injury)
		combatant.removeTrait(chosen_injury)

func checkSpecialStat(special_stat: String, bonus_stats: Dictionary, target: ResCombatant):
	return hasBonusStat(bonus_stats, special_stat) and checkBonusStatConditions(bonus_stats, special_stat, target)

func calculatePercentHealing(target: ResCombatant, percentage:float, use_mult:bool=true, trigger_on_heal:bool=true):
	calculateHealing(target, ceil(target.getMaxHealth()*percentage), use_mult, trigger_on_heal)

func calculateHealing(target, base_healing, use_mult:bool=true, trigger_on_heal:bool=true):
	var from_death:bool=false
	
	if target is CombatantScene:
		target = target.combatant_resource
	if target.isDead():
		target.stat_values['health'] = 0
		if inCombat(): removeBrinkEffects(target)
		target.resolve_gate=true
		from_death=true
	base_healing = valueVariate(base_healing, 0.1)
	if use_mult:
		base_healing *= max(0, 1.0+target.stat_values.get(CombatExtras.HEAL_AMP,0))
	
	target.changeHealth(int(base_healing))
	
#	if target.stat_values['health'] + base_healing > target.getMaxHealth():
#		target.changeHealth(target.getMaxHealth(),true)
#	else:
		#target.stat_values['health'] += int(base_healing)
	
	if base_healing >= 1.0:
		manual_call_indicator.emit(target, '[color=green]'+str(int(base_healing)), 'Damage')
		OverworldGlobals.playSound('02_Heal_02.ogg')
	else:
		manual_call_indicator.emit(target, "Broken.", 'Flunk')
	
	if inCombat() and trigger_on_heal and base_healing >= 1:
		target.removeTokens(ResStatusEffect.RemoveType.GET_HEAL)

func healResolve(target: ResCombatant, amount:int):
	target.stat_values['resolve'] += amount
	if target.stat_values['resolve'] > target.getMaxResolve():
		target.stat_values['resolve'] = target.getMaxResolve()

func randomRoll(percent_chance: float):
	percent_chance = 1.0 - percent_chance
	if percent_chance > 1.0:
		percent_chance = 1.0
	elif percent_chance < 0.0:
		percent_chance = 0.0
	randomize()
	return randf_range(0, 1.0) > percent_chance

func valueVariate(value, percent_variance: float):
	randomize()
	var variation = value * percent_variance
	value += randf_range(variation*-1, variation)
	return round(value)

func modifyStat(target: ResCombatant, stat_modifications: Dictionary, modifier_id: String, append_stat:bool=false, show_indicator:bool=false,append_indiactor:String=''):
	var change_relevant:bool=false
	var stats_added = stat_modifications.duplicate()
	if append_stat and target.stat_modifiers.has(modifier_id):
		stat_modifications = combineDictionaries(stat_modifications, target.stat_modifiers[modifier_id])
		change_relevant=true
	elif !target.stat_modifiers.has(modifier_id):
		change_relevant=true
	
	target.removeStatModification(modifier_id)
	target.stat_modifiers[modifier_id] = stat_modifications
	target.applyStatModifications(modifier_id)
	
	if show_indicator:
		await get_tree().process_frame
		if (inCombat() or (OverworldGlobals.player != null and OverworldGlobals.player.camping)) and change_relevant:
			var string_stats = CombatGlobals.getStatListString(stats_added).split('\n')
			for stat_message in string_stats:
				var mes = stat_message.replace('[/color]','')
				if mes == '': continue
				manual_call_indicator.emit(target, mes+append_indiactor,'Show',true)
				await get_tree().create_timer(0.25).timeout

func combineDictionaries(dict_a:Dictionary, dict_b:Dictionary)-> Dictionary:
	var out = {}
	var appending_dict: Dictionary
	
	if dict_a.size() > dict_b.size() or dict_a.size() == dict_b.size():
		out = dict_a
		appending_dict = dict_b
	elif dict_a.size() < dict_b.size():
		out = dict_b
		appending_dict = dict_a
	
	for stat in appending_dict.keys():
		if out.has(stat) and (out[stat] is int or out[stat] is float):
			out[stat] += appending_dict[stat]
		elif out.has(stat) and out[stat] is Array:
			out[stat].append(appending_dict[stat])
		else:
			out[stat] = appending_dict[stat]
	
	return out

func multiplyStatModifications(modifiers:Dictionary, multiply:float):
	var out = {}
	for stat in modifiers.keys():
		out[stat] = modifiers[stat]*multiply
	return out

func resetStat(target: ResCombatant, modifier_id: String):
	target.removeStatModification(modifier_id)

#********************************************************************************
# ANIMATION HANDLING
#********************************************************************************
func playAbilityAnimation(target:ResCombatant, animation_scene, time=0.0):
	if !is_instance_valid(target.combatant_scene): return
	var animation = animation_scene.instantiate()
	target.combatant_scene.add_child(animation)
	if time > 0.0:
		animation.playAnimation(target.combatant_scene.position)
		await get_tree().create_timer(time).timeout
	else:
		await animation.playAnimation(target.combatant_scene.position)

func playHurtAnimation(target: ResCombatant, damage, sound_path: String=''):
	if target.stat_modifiers.keys().has('block'):
		playHurtTween(target, damage)
		OverworldGlobals.playSound('348244__newagesoup__punch-boxing-01.ogg')
		return
	
	randomize()
	if sound_path == '':
		OverworldGlobals.playSound('522091__magnuswaker__pound-of-flesh-%s.ogg' % randi_range(1, 2), -6.0)
		if target is ResEnemyCombatant:
			OverworldGlobals.playSound('524950__magnuswaker__punch-hard-%s.ogg' % randi_range(1, 2), -6.0)
		else:
			OverworldGlobals.playSound("530117__magnuswaker__pound-of-flesh-3.ogg", -8.0)
	if target.isDead(true):
		getCombatScene().combat_camera.shake(25.0, 10.0)
		if target is ResEnemyCombatant:
			OverworldGlobals.playSound("res://audio/sounds/542052__rob_marion__gasp_space-shot_1.ogg")
		elif target is ResPlayerCombatant:
			target.combatant_scene.playIdle('Hurt')
			OverworldGlobals.playSound("res://audio/sounds/542038__rob_marion__gasp_sweep-shot_2.ogg")
	target.combatant_scene.doAnimation('Hurt',null,{'no_anim_fallback':true,'low_priority':true,'bypass_invalid_pause':true})
	playHurtTween(target, damage)
	playFlashTween(target, Color.RED)
	if inCombat() and sound_path != '':
		OverworldGlobals.playSound(sound_path, -8.0)

func playDodgeTween(target: ResCombatant):
	OverworldGlobals.playSound('607862__department64__whipstick-28.ogg')
	var tween = getCombatScene().create_tween().set_trans(Tween.TRANS_CUBIC)
	var sprite_push = 16
	if target is ResPlayerCombatant: sprite_push *= -1
	tween.tween_property(target.getSprite(), 'position', target.getSprite().position + Vector2(sprite_push, 0), 0.15)
	tween.tween_property(target.getSprite(), 'position', Vector2(0, 0), 0.5)

func playHurtTween(target: ResCombatant, damage):
	var sprite = target.combatant_scene.get_node('Sprite2D')
	var sprite_shaker: SpriteShaker = load("res://scenes/components/SpriteShaker.tscn").instantiate()
	sprite_shaker.shake_speed = 12.0
	sprite_shaker.shake_strength = 25.0 + (damage*0.1)
	sprite.add_child(sprite_shaker)

#func play 

func playFlashTween(target: ResCombatant, color:Color):
	var tween = getCombatScene().create_tween()
	tween.tween_property(target.getSprite(), 'modulate', color, 0.1)
	tween.tween_property(target.getSprite(), 'modulate', Color.WHITE, 0.2)
	
	if target is ResEnemyCombatant:
		getCombatScene().combat_camera.flash(Color.WHITE,0.1,0.05)
	else:
		getCombatScene().combat_camera.flash(Color.RED,0.1,0.05)
#	if !target.isDead():
#		getCombatScene().flasher_animator.play('Flash')
#	else:
#		getCombatScene().flasher_animator.play('Big_Flash')

func playFadingTween(target: ResCombatant):
	OverworldGlobals.playSound('woosh.ogg')
	var tween = getCombatScene().create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(target.combatant_scene, 'scale', target.combatant_scene.scale + Vector2(-1, 0), 0.15)
	tween.tween_property(target.combatant_scene, 'scale', Vector2(1, 1), 0.15)

func playSecondWindTween(target: ResCombatant):
	OverworldGlobals.playSound("res://audio/sounds/458533__shyguy014__healpop.ogg")
	var tween = getCombatScene().create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(target.combatant_scene, 'scale', target.combatant_scene.scale + Vector2(-1, 0), 0.05)
	tween.tween_property(target.combatant_scene, 'scale', Vector2(1, 1), 0.15)

func playKnockOutTween(target: ResCombatant):
	if target is ResPlayerCombatant: OverworldGlobals.playSound("res://audio/sounds/542039__rob_marion__gasp_sweep-shot_1.ogg")

	var tween = getCombatScene().create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(target.getSprite(), 'modulate', Color.BLACK, 0.75)
	#tween.tween_interval(3)
	tween.tween_property(target.getSprite(), 'self_modulate', Color.TRANSPARENT, 0.5)
	await tween.finished
	target.combatant_scene.hide()

#func playAnimation(target: ResCombatant, animation_name: String):
#	if !target.getAnimator().get_animation_list().has(animation_name):
#		return
#
#	target.getAnimator().play(animation_name)

func showWarning(target: CombatantScene):
	var warning = load("res://scenes/user_interface/TargetWarning.tscn").instantiate()
	target.add_child(warning)

func setCombatantVisibility(target: CombatantScene, set_to:bool):
	var tween = getCombatScene().create_tween()
	if !set_to:
		tween.tween_property(target.get_node('Sprite2D'), 'modulate', Color(Color.TRANSPARENT, 0.25), 0.15)
		target.z_index = -10
	else:
		tween.tween_property(target.get_node('Sprite2D'), 'modulate', Color(Color.TRANSPARENT, 1.0), 0.15)
		target.z_index = 0
	#if !target.combatant_resource.hasStatusEffect('KnockOut'):
	target.get_node('CombatBars').setBarVisibility(set_to)

func spawnQuickTimeEvent(target: CombatantScene, type: String, max_points:int=1, offset:Vector2=Vector2.ZERO):
	OverworldGlobals.playSound('542044__rob_marion__gasp_ui_confirm.ogg')
	var qte = load("res://scenes/quick_time_events/%s.tscn" % type).instantiate()
	qte.max_points = max_points
	if type == 'Holding': offset = Vector2.ZERO
	qte.global_position = target.global_position + offset
	qte.z_index = 101
	getCombatScene().call_deferred('add_child',qte)
	await qte_finished
	return qte

func moveCombatCamera(target_name: String, duration:float=0.25, wait=true):
	var target
	if target_name == 'RESET':
		target = getCombatScene().camera_position
	else:
		for combatant in getCombatScene().combatants:
			if combatant.name == target_name: target = combatant.combatant_scene.global_position
	
	if wait:
		await getCombatScene().moveCamera(target, duration)
	else:
		getCombatScene().moveCamera(target, duration)

#********************************************************************************
# STATUS effect HANDLING
#********************************************************************************
func addStatusEffect(target: ResCombatant, effect, guaranteed:bool=false, override_data:Dictionary={}):
	var status_effect: ResStatusEffect
	var path
	if effect is String:
		path = str("res://resources/combat/status_effects/"+effect.replace(' ', '')+".tres")
		assert(FileAccess.file_exists(path), 'Could not find "%s" effect!' % effect)
		status_effect = load(str("res://resources/combat/status_effects/"+effect.replace(' ', '')+".tres")).duplicate()
	elif effect is ResStatusEffect:
		path = effect.resource_path
		status_effect = effect.duplicate()
	if !guaranteed and (randomRoll(target.stat_values['resist']) and status_effect.resistable):
		#manual_call_indicator.emit(target, status_effect.getMessageIcon(), 'Status_Resisted')
		manual_call_indicator.emit(target, status_effect.getMessageIcon()+' [color=dark_gray]Resist', 'Resist')
		return
	if status_effect.resistable:
		target.removeTokens(ResStatusEffect.RemoveType.GET_STATUSED)
	if status_effect.remove_on_brink and target.isOnBrink():
		return
	
	for property in override_data.keys():
		if property.contains('be_'): # be stands fir basic_effect
			var effect_overrides = override_data[property]
			var id = property.split('_')[1]
			var basic_effect = findBasicEffect(id, status_effect)
			for basic_effect_property in effect_overrides:
				basic_effect.set(basic_effect_property, effect_overrides[basic_effect_property])
		elif status_effect.get(property) != null:
			status_effect.set(property, override_data[property])
	
	if !target.getStatusEffectNames().has(status_effect.name) or status_effect.seperate_instances:
		status_effect.afflicted_combatant = target
		status_effect.initializeStatus()
		if override_data.has('bonus_duration'):
			status_effect.duration += override_data['bonus_duration']
		target.status_effects.append(status_effect)
		if status_effect.sounds['apply'] != '': OverworldGlobals.playSound(status_effect.sounds['apply'])
	else:
		rankUpStatusEffect(target, status_effect)
		if status_effect.max_rank > 0:
			if target.getStatusEffect(status_effect.name).current_rank < status_effect.max_rank:
				manual_call_indicator.emit(target, status_effect.getMessageIcon(), 'Status_Up')
			elif target.getStatusEffect(status_effect.name).current_rank >= status_effect.max_rank:
				manual_call_indicator.emit(target, status_effect.getMessageIcon(), 'Status_Max')
	if status_effect.tick_on_apply:
		target.getStatusEffect(status_effect.name).tick(false)
	if target.status_effects.has(status_effect) and !status_effect.hide_icon: # Because some effects get removed on apply!
		manual_call_indicator.emit(target, status_effect.getMessageIcon()+' '+status_effect.getIconColor(true)+status_effect.name, 'Show')

func findBasicEffect(identifer:String, status_effect: ResStatusEffect)-> ResBasicEffect:
	for effect in status_effect.basic_effects:
		if effect.identifier == identifer: return effect
	
	assert(false, 'Could not find identifer "%s" in "%s" basic effects.' % [identifer, status_effect])
	return null

func removeStatusEffect(combatant: ResCombatant, effect_name:String):
	for effect in combatant.status_effects:
		if effect.name.to_lower() == effect_name.to_lower():
			effect.removeStatusEffect()

func runReaction(target: ResCombatant, effectA: String, effectB: String, reaction: ResAbility):
	removeStatusEffect(target, effectA)
	removeStatusEffect(target, effectB)
	execute_ability.emit(target, reaction)

func rankUpStatusEffect(afflicted_target: ResCombatant, status_effect: ResStatusEffect):
	for effect in afflicted_target.status_effects:
		if effect.name == status_effect.name:
			if effect.duration + status_effect.extend_duration > effect.max_duration:
				effect.duration = effect.max_duration
			else:
				effect.duration += status_effect.extend_duration
		if effect.current_rank != effect.max_rank and effect.max_rank != 0:
			effect.apply_once = true
			effect.current_rank += 1

func spawnIndicator(position: Vector2, message:String, animation:String='Show',add_to:Node=null,time:float=1.0):
	var indicator = load("res://scenes/user_interface/Indicator.tscn").instantiate()
	indicator.scale=Vector2(1,1)
	if add_to != null:
		add_to.add_child(indicator)
	elif inCombat():
		getCombatScene().add_child(indicator)
	else:
		OverworldGlobals.getCurrentMap().add_child(indicator)
	
	indicator.global_position = position
	indicator.z_index = 99
	indicator.playAnimation(position, message, animation,time)

func getCombatScene()-> CombatScene:
	return get_parent().get_node('CombatScene')

func inCombat()-> bool:
	return get_parent().has_node('CombatScene') and is_instance_valid(get_parent().get_node('CombatScene'))

func loadStatusEffect(status_effect_name: String)-> ResStatusEffect:
#	if status_effect_name.contains('linger|'):
#		status_effect_name = status_effect_name.split('|')[1]
	return load(str("res://resources/combat/status_effects/"+status_effect_name.replace(' ', '')+".tres"))

func getCombatantType(combatant):
	if combatant is CombatantScene:
		combatant = combatant.combatant_resource
	
	if combatant is ResPlayerCombatant:
		return 0
	elif combatant is ResEnemyCombatant:
		return 1

func isSameCombatantType(combatant_a, combatant_b):
	if combatant_a is CombatantScene:
		combatant_a = combatant_a.combatant_resource
	if combatant_b is CombatantScene:
		combatant_b = combatant_b.combatant_resource
	
	return getCombatantType(combatant_a) == getCombatantType(combatant_b)

## -1: Random Special, 0: Chaser, 1: Shooter, 2: Hybrid
func generateFactionPatroller(faction: Enemy_Factions, type:int)-> GenericPatroller:
	var faction_properties: ResFactionProperties = FACTION_PATROLLER_PROPERTIES[faction]
	if type == -1:
		type = faction_properties.pickRandomSpecial()
	var patroller: GenericPatroller = instantiatePatroller(type)
	faction_properties.getPatrollerProperties(type).setPatrollerProperties(patroller)
	return patroller

func generatePatroller(properties: ResPatrollerProperties)-> GenericPatroller:
	var patroller: GenericPatroller = instantiatePatroller(properties.getType())
	properties.setPatrollerProperties(patroller)
	return patroller

func instantiatePatroller(type:int)-> GenericPatroller:
	match type:
		0: return load("res://scenes/entities/mobs/Patroller.tscn").instantiate()
		1: return load("res://scenes/entities/mobs/PatrollerShooter.tscn").instantiate()
		2: return load("res://scenes/entities/mobs/PatrollerHybrid.tscn").instantiate()
	
	return null

func generateCombatantSquad(patroller: GenericPatroller, faction: Enemy_Factions):
	randomize()
	var squad: EnemyCombatantSquad = load("res://scenes/components/CombatantSquadEnemy.tscn").instantiate()
	var squad_size = randi_range(PlayerGlobals.getLevelTier(), PlayerGlobals.getLevelTier()+2)
	var map_events = OverworldGlobals.getCurrentMap().events
	if squad_size > 4: squad_size = 4
	squad.fill_empty = true
	squad.enemy_pool = getFactionEnemies(faction)
	print(map_events)
	if map_events.has('additional_enemies') and map_events['additional_enemies'] != null:
		squad.enemy_pool.append_array(ResourceGlobals.loadArrayFromPath(map_events['additional_enemies']))
	squad.enemy_pool = squad.enemy_pool.filter(func(combatant): return isWithinPlayerTier(combatant))
	squad.combatant_squad.resize(squad_size)
	squad.pickRandomEnemies()
	
	if patroller != null:
		patroller.add_child(squad)
	else:
		return squad

func createCombatantSquad(patroller, combatants: Array[ResCombatant], properties: Dictionary):
	var squad: EnemyCombatantSquad = load("res://scenes/components/CombatantSquadEnemy.tscn").instantiate()
	squad.combatant_squad = combatants
	squad.setProperties(properties)
	patroller.add_child(squad)

func getFactionEnemies(faction: Enemy_Factions):
	var out = ResourceGlobals.loadArrayFromPath(FACTION_PATROLLER_PROPERTIES[faction].combatants_path)
	var array_of_combatants: Array[ResEnemyCombatant]=[]
	array_of_combatants.assign(out)
	return array_of_combatants

func getFactionName(faction_value:int):
	return Enemy_Factions.find_key(faction_value)

func isWithinPlayerTier(enemy: ResEnemyCombatant)-> bool:
	return enemy.tier+1 <= PlayerGlobals.getLevelTier()

func addTension(amount: int,from_target:CombatantScene=null,gainer:ResPlayerCombatant=null):
	if gainer != null and gainer.hasStatusEffect('Burnout'):
		# manual call indicator
		gainer.getStatusEffect('Burnout').tick()
		return
	
	var previous_tension = tension
	if tension + amount > 4:
		tension = 4
	elif tension + amount < 0:
		tension = 0
	else:
		tension += amount
	tension_changed.emit(previous_tension, tension,from_target)

func getBasicEffectsDescription(basic_effects:Array, seperator:bool=true):
	var out = ''
	
	for i in range(basic_effects.size()):
		var effect = basic_effects[i]
		if effect == null:continue
		if !effect.has_method('_to_string'):
			continue
		out+=effect._to_string()
		if seperator and i != basic_effects.size()-1:
			out += SettingsGlobals.bb_line
		elif !seperator:
			out += '\n'
	return out

func getStatListString(stat_modifications:Dictionary, do_colors:bool=true):
	var result = ""
	for key in stat_modifications.keys():
		
		var val = stat_modifications[key]
		if val == 0.0:
			continue
		
		if stat_modifications[key] > 0 and stat_modifications[key]:
			if do_colors: result += SettingsGlobals.ui_colors['up-bb']
			if fmod(val, 1.0) != 0: 
				result += "+" + str(val*100) + "% " +key.to_upper().replace('_', ' ') + "\n"
			else:
				result += "+" + str(val) + " " +key.to_upper().replace('_', ' ') +  "\n"
		else:
			if do_colors: result += SettingsGlobals.ui_colors['down-bb'] #'[color=ORANGE_RED]'
			if fmod(val, 1.0) != 0: 
				result += str(val*100) + "% " +key.to_upper().replace('_', ' ') +  "\n"
			else:
				result += str(val) + " " +key.to_upper().replace('_', ' ') + "\n"
		if do_colors: result += '[/color]'
	return result
