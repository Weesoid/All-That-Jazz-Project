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

var tension: int = 0
signal combat_won(unique_id)
signal combat_lost(unique_id)
signal dialogue_signal(flag)
signal combat_conclusion_dialogue(dialogue, result)
signal animation_done
signal exp_updated(value: float, max_value: float)
signal received_combatant_value(combatant: ResCombatant, caster: ResCombatant, value)
signal manual_call_indicator(combatant: ResCombatant, text: String, animation: String)
#signal manual_call_indicator_bb(combatant: ResCombatant, text: String, animation: String, bb: String)
signal execute_ability(target, ability: ResAbility)
signal qte_finished()
signal ability_finished
signal ability_casted(ability: ResAbility)
signal active_combatant_changed(combatant: ResCombatant)
signal tension_changed(previous_tension,current_tension,from_target)
signal click_block

#********************************************************************************
# COMBAT PROGRESSION / SIGNALS
#********************************************************************************
func emit_exp_updated(value, max_value):
	exp_updated.emit(value, max_value)

#********************************************************************************
# ability EFFECTS & UTILITY
#********************************************************************************
## Calculate damage using basic formula and parameters
func calculateDamage(caster, target, modifier, can_miss = true, can_crit = true, sound:String='', indicator_bb_code: String='', bonus_stats: Dictionary={})-> bool:
	if caster is CombatantScene:
		caster = caster.combatant_resource
	if target is CombatantScene:
		target = target.combatant_resource
	
	if target is ResPlayerCombatant and target.combatant_scene.blocking:
		can_miss=false
	
	if randomRoll(caster.stat_values['accuracy']+getBonusStat(bonus_stats, 'accuracy', target)) and can_miss:
		damageTarget(caster, target, modifier, can_crit, sound, indicator_bb_code, bonus_stats)
		return true
	elif can_miss:
		doDodgeEffects(caster, target, modifier)
		return false
	else:
		damageTarget(caster, target, modifier, can_crit, sound, indicator_bb_code)
		return true

## Calculate damage using custom formula and parameters
func calculateRawDamage(target, damage, caster: ResCombatant = null, can_crit = false, crit_chance = -1.0, can_miss = false, variation = -1.0, trigger_on_hits = false, sound:String='', indicator_bb_code:String='', bonus_stats:Dictionary={}, use_damage_formula:bool=false)-> bool:
	if !target is ResCombatant:
		target = target.combatant_resource
	if target is ResPlayerCombatant and target.combatant_scene.blocking:
		can_miss=false
	
	damage += getBonusStat(bonus_stats, 'damage', target)
	if use_damage_formula:
		damage = useDamageFormula(target, damage)
	if can_miss and !randomRoll(caster.stat_values['accuracy']+getBonusStat(bonus_stats, 'accuracy', target)):
		doDodgeEffects(caster, target, damage)
		return false
	if variation != -1.0:
		damage = valueVariate(damage, variation)
	if can_crit and ((caster != null and randomRoll(caster.stat_values['crit']+getBonusStat(bonus_stats, 'crit', target))) or (crit_chance != -1.0 and randomRoll(crit_chance+getBonusStat(bonus_stats, 'crit', target)))):
		damage = doCritEffects(damage, caster, 2.0+getBonusStat(bonus_stats,'crit_dmg', target), true)
		indicator_bb_code += '[img]res://images/status_icons/icon_crit.png[/img][color=red]'
	target.stat_values['health'] -= int(damage)
	doPostDamageEffects(caster, target, damage, sound, indicator_bb_code, trigger_on_hits, bonus_stats)
	
	return true

## Basic damage calculations
func damageTarget(caster: ResCombatant, target: ResCombatant, modifier:float, can_crit: bool, sound:String='', indicator_bb_code: String='', bonus_stats: Dictionary = {}):
	var damage = (caster.stat_values['damage']+getBonusStat(bonus_stats, 'damage', target))*caster.stat_values['dmg_modifier']
	damage = damage*modifier
	damage = valueVariate(damage, caster.stat_values['dmg_variance'])
	damage = useDamageFormula(target, damage)
	
	if randomRoll(caster.stat_values['crit']+getBonusStat(bonus_stats, 'crit', target)) and can_crit:
		damage = doCritEffects(damage, caster, getBonusStat(bonus_stats,'crit_dmg', target),true)
		indicator_bb_code += '[img]res://images/sprites/icon_crit.png[/img][color=red]'
	if checkSpecialStat('non-lethal', bonus_stats, target) and target.stat_values['health']-damage <= 0:
		damage = 0
	
	target.stat_values['health'] -= int(damage)
	doPostDamageEffects(caster, target, damage, sound, indicator_bb_code, true, bonus_stats)

func getBonusStat(bonus_stats: Dictionary, key: String, target: ResCombatant):
	if hasBonusStat(bonus_stats, key) and checkBonusStatConditions(bonus_stats, key, target):
		return getBonusStatValue(bonus_stats, key)
	else:
		return 0

func hasBonusStat(bonus_stats: Dictionary, key: String)-> bool:
	var out = []
	for stat in bonus_stats.keys():
		out.append(stat.split('/')[0])
	
	return out.has(key)

func getBonusStatValue(bonus_stats: Dictionary, key: String):
	for stat in bonus_stats.keys():
		if stat.split('/')[0] == key: 
			if bonus_stats[stat] is String and bonus_stats[stat].is_valid_float():
				return float(bonus_stats[stat])
			elif bonus_stats[stat] is String and bonus_stats[stat].is_valid_int():
				return int(bonus_stats[stat])
			else:
				return bonus_stats[stat]

func checkBonusStatConditions(bonus_stats: Dictionary, key: String, target: ResCombatant):
	var conditions: Array
	for stat in bonus_stats.keys():
		if key == stat.split('/')[0] and (stat.split('/').size() > 1):
			conditions = stat.split('/')
			conditions.remove_at(0)
			break
		elif key == stat.split('/')[0]:
			return true
	
	return checkConditions(conditions, target)

func checkConditions(conditions: Array, target: ResCombatant):
	for condition in conditions:
		var condition_data = condition.split(':')
		match condition_data[0]:
			's': # ex. s:bleed or s:guard:2
				if !target.hasStatusEffect(condition_data[1]): 
					return false
				
				var rank_condition = true
				if condition_data.size() > 2:
					var operator = '>'
					if condition_data[2].split(',').size() > 1:
						operator = condition_data[2].split(',')[1]
					match operator:
						'>': rank_condition = target.getStatusEffect(condition_data[1]).current_rank >= int(condition_data[2])
						'<': rank_condition = target.getStatusEffect(condition_data[1]).current_rank <= int(condition_data[2])
						'=': rank_condition = target.getStatusEffect(condition_data[1]).current_rank == int(condition_data[2])
				
				return target.hasStatusEffect(condition_data[1]) and rank_condition
			'hp': # ex. hp:>:0.5 or hp:<:0.45
				if condition_data[1] == '>':
					return target.stat_values['health'] >= float(condition_data[2])*target.getMaxHealth()
				if condition_data[1] == '<':
					return target.stat_values['health'] <= float(condition_data[2])*target.getMaxHealth()
			'combo': # ex crit/combo
				if target.hasStatusEffect('Combo'):
					target.getStatusEffect('Combo').removeStatusEffect()
					manual_call_indicator.emit(target, '[img]res://images/status_icons/icon_combo.png[/img][color=turquoise]COMBO!!', 'Show')
					return true
			'combo!': # ex. crit/combo!
				return target.hasStatusEffect('Combo')
			'%': # ex. crit/%:0.50
				return randomRoll(float(condition_data[1]))

func doDodgeEffects(caster: ResCombatant, target: ResCombatant, damage):
	caster.removeTokens(ResStatusEffect.RemoveType.MISSED)
	manual_call_indicator.emit(target, 'Whiff!', 'Whiff')
	playDodgeTween(target)
	checkMissCases(target, caster, damage)

func doCritEffects(base_damage, caster: ResCombatant, crit_damage:float=2.0, stack_crit_damage:bool=false):
	if  caster != null:
		if stack_crit_damage:
			base_damage *= (caster.stat_values['crit_dmg']+crit_damage)
		else:
			base_damage *= caster.stat_values['crit_dmg']
	else:
		base_damage *= crit_damage
	getCombatScene().combat_camera.shake(15.0, 10.0)
	OverworldGlobals.playSound("res://audio/sounds/13_Ice_explosion_01.ogg")
	return base_damage

func doPostDamageEffects(caster: ResCombatant, target: ResCombatant, damage, sound: String, indicator_bb_code: String='', trigger_on_hits: bool=true, bonus_stats: Dictionary={}):
	var message = str(int(damage))
	message = indicator_bb_code+'[outline_size=2] '+message
	
	if indicator_bb_code.contains('crit'):
		manual_call_indicator.emit(target, message, 'Crit')
	elif damage > 0:
		manual_call_indicator.emit(target, message, 'Damage')
	target.removeTokens(ResStatusEffect.RemoveType.GET_HIT)
	if caster != null:
		caster.removeTokens(ResStatusEffect.RemoveType.HIT)
	if trigger_on_hits:
		received_combatant_value.emit(target, caster, int(damage))
	if caster != null and target.isDead() and abs(target.stat_values['health']) >= target.getMaxHealth() * 0.25:
		calculateHealing(caster, caster.getMaxHealth()*0.15)
		if caster is ResPlayerCombatant:
			addTension(1)
			manual_call_indicator.emit(target, "OVERKILL", 'Wallop')
	
	playHurtAnimation(target, damage, sound)
	
	# The wall of post damage effects
	if hasBonusStat(bonus_stats, 'execute') and target.stat_values['health'] <= getBonusStat(bonus_stats, 'execute', target)*target.getMaxHealth():
		OverworldGlobals.showQuickAnimation("res://scenes/animations_quick/SkullKill.tscn", target.combatant_scene.global_position)
		target.stat_values['health'] -= 999
		manual_call_indicator.emit(target, 'EXECUTED!', 'Damage')
	if checkSpecialStat('status_effect', bonus_stats, target):
		var status_effects = getBonusStatValue(bonus_stats, 'status_effect').split(',')
		for effect in status_effects:
			addStatusEffect(target, effect)
	if checkSpecialStat('move', bonus_stats, target):
		var move_data = getBonusStatValue(bonus_stats, 'move').split(',')
		var direction
		match move_data[0]:
			'f': direction = 1
			'b': direction = -1
		getCombatScene().changeCombatantPosition(target, direction,false,int(move_data[1]))
	if hasBonusStat(bonus_stats, 'tp') and caster is ResPlayerCombatant:
		addTension(getBonusStat(bonus_stats,'tp',target), target.combatant_scene)

#	if checkSpecialStat('plant', bonus_stats, target):
#
	if target.isDead():
		OverworldGlobals.freezeFrame()
#		if target is ResEnemyCombatant:
#			getCombatScene().fade_bars_animator.play('KOEnemy')
#		else:
#			getCombatScene().fade_bars_animator.play('KOAlly')

func checkSpecialStat(special_stat: String, bonus_stats: Dictionary, target: ResCombatant):
	return hasBonusStat(bonus_stats, special_stat) and checkBonusStatConditions(bonus_stats, special_stat, target)

func checkMissCases(target: ResCombatant, caster: ResCombatant, damage):
	if target.getStatusEffectNames().has('Riposte'):
		target.getStatusEffect('Riposte').onHitTick(target, caster, damage)

func useDamageFormula(target: ResCombatant, damage):
	var grit = target.stat_values['defense']
	if grit > 0.7 and (inCombat() and !target.combatant_scene.blocking):
		grit = 0.7
	var out_damage = damage - (grit * damage)
	if out_damage < 0.0: 
		out_damage = 0
	return out_damage

func calculateHealing(target, base_healing, use_mult:bool=true, trigger_on_heal:bool=true):
	var from_death:bool=false
	if target is CombatantScene:
		target = target.combatant_resource
	if target.stat_values['health'] < 0:
		target.stat_values['health'] = 0
		from_death=true
	base_healing = valueVariate(base_healing, 0.15)
	if use_mult:
		base_healing *= target.stat_values['heal_mult']
	if base_healing <= 0: 
		base_healing = 0
	
	if target.stat_values['health'] + base_healing > target.getMaxHealth():
		target.stat_values['health'] = target.getMaxHealth()
	else:
		target.stat_values['health'] += int(base_healing)
	
	if base_healing >= 1.0:
		manual_call_indicator.emit(target, '[color=green]'+str(int(base_healing)), 'Damage')
		OverworldGlobals.playSound('02_Heal_02.ogg')
	else:
		manual_call_indicator.emit(target, "Broken.", 'Flunk')
	
	if inCombat() and trigger_on_heal and base_healing >= 1:
		target.removeTokens(ResStatusEffect.RemoveType.GET_HEAL)
	if inCombat() and target.combatant_scene.animator.current_animation == 'Fading' and !target.isDead():
		target.combatant_scene.playIdle('Idle')
	if !inCombat() and from_death:
		applyFaded(target)

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

func modifyStat(target: ResCombatant, stat_modifications: Dictionary, modifier_id: String):
	target.removeStatModification(modifier_id)
	target.stat_modifiers[modifier_id] = stat_modifications
	target.applyStatModifications(modifier_id)

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
	if !target.stat_modifiers.keys().has('block'):
		randomize()
		if sound_path == '':
			OverworldGlobals.playSound('522091__magnuswaker__pound-of-flesh-%s.ogg' % randi_range(1, 2), -6.0)
			if target is ResEnemyCombatant:
				OverworldGlobals.playSound('524950__magnuswaker__punch-hard-%s.ogg' % randi_range(1, 2), -6.0)
			else:
				OverworldGlobals.playSound("530117__magnuswaker__pound-of-flesh-3.ogg", -8.0)
		#getCombatScene().combat_camera.shake(50.0, 50.0)
		playHurtTween(target, damage)
		playFlashTween(target, Color.RED)
		if target.isDead():
			getCombatScene().combat_camera.shake(25.0, 10.0)
			if target is ResEnemyCombatant:
				playAnimation(target, 'KO')
				OverworldGlobals.playSound("res://audio/sounds/542052__rob_marion__gasp_space-shot_1.ogg")
			elif target is ResPlayerCombatant:
				OverworldGlobals.playSound("res://audio/sounds/542038__rob_marion__gasp_sweep-shot_2.ogg")
		if inCombat() and sound_path != '':
			OverworldGlobals.playSound(sound_path, -8.0)
	else:
		OverworldGlobals.playSound('348244__newagesoup__punch-boxing-01.ogg')

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

func playFlashTween(target: ResCombatant, color:Color):
	var tween = getCombatScene().create_tween()
	tween.tween_property(target.getSprite(), 'modulate', color, 0.1)
	tween.tween_property(target.getSprite(), 'modulate', Color.WHITE, 0.2)
	if target is ResEnemyCombatant:
		getCombatScene().flasher.modulate = Color.WHITE
	else:
		getCombatScene().flasher.modulate = Color.RED
	if !target.isDead():
		getCombatScene().flasher_animator.play('Flash')
	else:
		getCombatScene().flasher_animator.play('Big_Flash')

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
	tween.tween_property(target.combatant_scene, 'scale', target.combatant_scene.scale + Vector2(-1, 0), 0.15)
	tween.tween_property(target.combatant_scene, 'scale', Vector2(1, 1), 0.15)
	await tween.finished

func playAnimation(target: ResCombatant, animation_name: String):
	if !target.getAnimator().get_animation_list().has(animation_name):
		return
	
	target.getAnimator().play(animation_name)

func showWarning(target: CombatantScene):
	var warning = load("res://scenes/user_interface/TargetWarning.tscn").instantiate()
	target.add_child(warning)

func setCombatantVisibility(target: CombatantScene, set_to:bool):
	var tween = getCombatScene().create_tween()
	if !set_to:
		tween.tween_property(target.get_node('Sprite2D'), 'modulate', Color(Color.TRANSPARENT, 0.5), 0.15)
		target.z_index = -10
	else:
		tween.tween_property(target.get_node('Sprite2D'), 'modulate', Color(Color.TRANSPARENT, 1.0), 0.15)
		target.z_index = 0
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

func playCombatantAnimation(combatant_name: String, animation_name: String, wait=true):
	for combatant in getCombatScene().combatants:
		if combatant.name == combatant_name:
			if wait:
				await combatant.combatant_scene.doAnimation(animation_name)
			else:
				combatant.combatant_scene.doAnimation(animation_name)
			return

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
func addStatusEffect(target: ResCombatant, effect, guaranteed:bool=false):
	var status_effect: ResStatusEffect
	var path
	if effect is String:
		path = str("res://resources/combat/status_effects/"+effect.replace(' ', '')+".tres")
		if !FileAccess.file_exists(path):
			return
		status_effect = load(str("res://resources/combat/status_effects/"+effect.replace(' ', '')+".tres")).duplicate()
	elif effect is ResStatusEffect:
		path = effect.resource_path
		status_effect = effect.duplicate()
	if !guaranteed and (randomRoll(target.stat_values['resist']) and status_effect.resistable):
		manual_call_indicator.emit(target, '[s]'+status_effect.getMessageIcon(), 'Resist')
		return
	if status_effect.resistable:
		target.removeTokens(ResStatusEffect.RemoveType.GET_STATUSED)
	
	if !target.getStatusEffectNames().has(status_effect.name):
		status_effect.afflicted_combatant = target
		status_effect.initializeStatus()
		target.status_effects.append(status_effect)
		if status_effect.sounds['apply'] != '': OverworldGlobals.playSound(status_effect.sounds['apply'])
	else:
		rankUpStatusEffect(target, status_effect)
		if status_effect.max_rank > 0:
			if status_effect.current_rank < status_effect.max_rank:
				manual_call_indicator.emit(target, status_effect.getMessageIcon(), 'Status_Up')
			elif status_effect.current_rank >= status_effect.max_rank:
				manual_call_indicator.emit(target, status_effect.getMessageIcon(), 'Status_Added')
	if status_effect.tick_on_apply:
		target.getStatusEffect(status_effect.name).tick(false)
	if target.status_effects.has(status_effect): # Because some effects get removed on apply!
		manual_call_indicator.emit(target, status_effect.getMessageIcon(), 'Status_Added')
	
	if (!guaranteed and !randomRoll(0.15+target.stat_values['resist'])) and (status_effect.lingers and target is ResPlayerCombatant):
		if OverworldGlobals.addLingerEffect(target,status_effect):
			manual_call_indicator.emit(target, 'Afflicted %s!' % status_effect.name, 'Lingering')
	
	checkReactions(target)

func removeStatusEffect(combatant: ResCombatant, effect_name:String):
	for effect in combatant.status_effects:
		if effect.name.to_lower() == effect_name.to_lower():
			effect.removeStatusEffect()

func removeStatusFaded(combatant: ResPlayerCombatant):
	combatant.lingering_effects = combatant.lingering_effects.filter(func(effect): return !effect.contains('Faded'))

func checkReactions(target: ResCombatant):
	if target.getStatusEffectNames().has('Burn') and target.getStatusEffectNames().has('Chilled'):
		runReaction(target, 'Burn', 'Chilled', load("res://resources/combat/abilities_reactions/Scald.tres"))
	elif target.getStatusEffectNames().has('Jolted') and target.getStatusEffectNames().has('Poison'):
		runReaction(target, 'Jolted', 'Poison', load("res://resources/combat/abilities_reactions/Catalyze.tres"))
	elif target.getStatusEffectNames().has('Chilled') and target.getStatusEffectNames().has('Jolted'):
		runReaction(target, 'Chilled', 'Jolted', load("res://resources/combat/abilities_reactions/Disrupt.tres"))
	elif target.getStatusEffectNames().has('Chilled') and target.getStatusEffectNames().has('Poison'):
		runReaction(target, 'Chilled', 'Poison', load("res://resources/combat/abilities_reactions/Vulnerate.tres"))
	elif target.getStatusEffectNames().has('Burn') and target.getStatusEffectNames().has('Poison'):
		execute_ability.emit(target, load("res://resources/combat/abilities_reactions/Cauterize.tres"))
		removeStatusEffect(target, 'Burn')
		removeStatusEffect(target, 'Poison')
	elif target.getStatusEffectNames().has('Burn') and target.getStatusEffectNames().has('Jolted'):
		execute_ability.emit(target, load("res://resources/combat/abilities_reactions/Fulgurate.tres"))
		removeStatusEffect(target, 'Burn')
		removeStatusEffect(target, 'Jolted')

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

func spawnIndicator(position: Vector2, message:String, animation:String='Show',add_to:Node=null):
	var indicator = load("res://scenes/user_interface/SecondaryIndicator.tscn").instantiate()
	
	if add_to != null:
		add_to.add_child(indicator)
	elif inCombat():
		getCombatScene().add_child(indicator)
	else:
		OverworldGlobals.getCurrentMap().add_child(indicator)
	
	indicator.global_position = position
	indicator.z_index = 99
	indicator.playAnimation(position, message, animation)

func getCombatScene()-> CombatScene:
	return get_parent().get_node('CombatScene')

func inCombat()-> bool:
	return get_parent().has_node('CombatScene')

func loadStatusEffect(status_effect_name: String)-> ResStatusEffect:
	return load(str("res://resources/combat/status_effects/"+status_effect_name.replace(' ', '')+".tres")).duplicate()

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
	if map_events.has('additional_enemies'):
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

func addTension(amount: int,from_target:CombatantScene=null):
	var previous_tension = tension
	if tension + amount > 8:
		tension = 8
	elif tension + amount < 0:
		tension = 0
	else:
		tension += amount
	tension_changed.emit(previous_tension, tension,from_target)

func applyFaded(target: ResCombatant):
	if inCombat() and (getCombatScene().combat_result != -1 and getFadedLevel(target) == 0):
		OverworldGlobals.addLingerEffect(target,'FadedI')
		return
	if inCombat() and (getCombatScene().combat_result != -1 and getFadedLevel(target) >= 4):
		return
	var escalated_level = getFadedLevel(target)+1
	
	# Remove previous faded
	target.lingering_effects.erase(applyFadedStatus(escalated_level-1))
	if inCombat():
		removeStatusEffect(target, applyFadedStatus(escalated_level-1,true))
	
	# Add escalated faded level
	if inCombat():
		addStatusEffect(target, applyFadedStatus(escalated_level,true))
	OverworldGlobals.addLingerEffect(target,applyFadedStatus(escalated_level))

func getFadedLevel(target: ResCombatant):
	if target.hasStatusEffect('Faded I') or target.lingering_effects.has('FadedI'):
		return 1
	elif target.hasStatusEffect('Faded II') or target.lingering_effects.has('FadedII'):
		return 2
	elif target.hasStatusEffect('Faded III') or target.lingering_effects.has('FadedIII'):
		return 3
	elif target.hasStatusEffect('Faded IV') or target.lingering_effects.has('FadedIV'):
		return 4
	else:
		return 0

func applyFadedStatus(level: int, add_space:bool=false):
	var out = ''
	match level:
		1: out = 'FadedI'
		2: out =  'FadedII'
		3: out =  'FadedIII'
		4: out =  'FadedIV'
	if add_space:
		out = out.insert(5, ' ')
	return out
