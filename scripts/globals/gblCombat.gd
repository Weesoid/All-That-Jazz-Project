extends Node


enum Enemy_Factions {
	Neutral,
	Unggboys,
	Mercenaries,
	Scavs
}
var FACTION_PATROLLER_PROPERTIES = {
	Enemy_Factions.Scavs: preload("res://resources/combat/faction_patrollers/Scavs.tres")
}

var TENSION: int = 0
signal combat_won(unique_id)
signal combat_lost(unique_id)
signal dialogue_signal(flag)
signal combat_conclusion_dialogue(dialogue, result)
signal animation_done
signal exp_updated(value: float, max_value: float)
signal received_combatant_value(combatant: ResCombatant, caster: ResCombatant, value)
signal manual_call_indicator(combatant: ResCombatant, text: String, animation: String)
signal manual_call_indicator_bb(combatant: ResCombatant, text: String, animation: String, bb: String)
signal execute_ability(target, ability: ResAbility)
signal qte_finished()
signal ability_finished
signal ability_casted(ability: ResAbility)
signal active_combatant_changed(combatant: ResCombatant)
signal tension_changed(previous_tension, tension)
signal click_block

#********************************************************************************
# COMBAT PROGRESSION / SIGNALS
#********************************************************************************
func emit_exp_updated(value, max_value):
	exp_updated.emit(value, max_value)

#********************************************************************************
# ABILITY EFFECTS & UTILITY
#********************************************************************************
## Calculate damage using basic formula and parameters
func calculateDamage(caster, target, base_damage, can_miss = true, can_crit = true, sound:String='', indicator_bb_code: String='', bonus_stats: Dictionary={})-> bool:
	if caster is CombatantScene:
		caster = caster.combatant_resource
	if target is CombatantScene:
		target = target.combatant_resource
	
	if target is ResPlayerCombatant and target.SCENE.blocking:
		can_miss=false
	
	if randomRoll(caster.STAT_VALUES['accuracy']+getBonusStat(bonus_stats, 'accuracy', target)) and can_miss:
		damageTarget(caster, target, base_damage, can_crit, sound, indicator_bb_code, bonus_stats)
		return true
	elif can_miss:
		doDodgeEffects(caster, target, base_damage)
		return false
	else:
		damageTarget(caster, target, base_damage, can_crit, sound, indicator_bb_code)
		return true

## Calculate damage using custom formula and parameters
func calculateRawDamage(target, damage, caster: ResCombatant = null, can_crit = false, crit_chance = -1.0, can_miss = false, variation = -1.0, _message = null, trigger_on_hits = false, sound:String='', indicator_bb_code:String='', bonus_stats:Dictionary={}, use_damage_formula:bool=false)-> bool:
	if !target is ResCombatant:
		target = target.combatant_resource
	if target is ResPlayerCombatant and target.SCENE.blocking:
		can_miss=false
	
	damage += getBonusStat(bonus_stats, 'damage', target)
	if use_damage_formula:
		damage = useDamageFormula(target, damage)
	if can_miss and !randomRoll(caster.STAT_VALUES['accuracy']+getBonusStat(bonus_stats, 'accuracy', target)):
		doDodgeEffects(caster, target, damage)
		return false
	if variation != -1.0:
		damage = valueVariate(damage, variation)
	if can_crit and ((caster != null and randomRoll(caster.STAT_VALUES['crit']+getBonusStat(bonus_stats, 'crit', target))) or (crit_chance != -1.0 and randomRoll(crit_chance+getBonusStat(bonus_stats, 'crit', target)))):
		damage = doCritEffects(damage, caster, 2.0+getBonusStat(bonus_stats,'crit_dmg', target), true)
		indicator_bb_code += '[img]res://images/sprites/icon_crit.png[/img][color=red]'
	target.STAT_VALUES['health'] -= int(damage)
	doPostDamageEffects(caster, target, damage, sound, indicator_bb_code, trigger_on_hits, bonus_stats)
	
	return true

## Basic damage calculations
func damageTarget(caster: ResCombatant, target: ResCombatant, base_damage, can_crit: bool, sound:String='', indicator_bb_code: String='', bonus_stats: Dictionary = {}):
	base_damage += getBonusStat(bonus_stats, 'damage', target)
	base_damage += (caster.STAT_VALUES['brawn']+getBonusStat(bonus_stats, 'brawn', target)) * base_damage
	base_damage = useDamageFormula(target, base_damage)
	base_damage = valueVariate(base_damage, 0.1)
	if randomRoll(caster.STAT_VALUES['crit']+getBonusStat(bonus_stats, 'crit', target)) and can_crit:
		base_damage = doCritEffects(base_damage, caster, getBonusStat(bonus_stats,'crit_dmg', target),true)
		indicator_bb_code += '[img]res://images/sprites/icon_crit.png[/img][color=red]'
	if checkSpecialStat('non-lethal', bonus_stats, target) and target.STAT_VALUES['health']-base_damage <= 0:
		base_damage = 0
	
	target.STAT_VALUES['health'] -= int(base_damage)
	doPostDamageEffects(caster, target, base_damage, sound, indicator_bb_code, true, bonus_stats)

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
	var base_bonus_stats = []
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
		print('deep checking: ', condition)
		var condition_data = condition.split(':')
		match condition_data[0]:
			's': # ex. s:bleed or s:guard:2,=
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
					return target.STAT_VALUES['health'] >= float(condition_data[2])*target.getMaxHealth()
				if condition_data[1] == '<':
					return target.STAT_VALUES['health'] <= float(condition_data[2])*target.getMaxHealth()
			'combo': # ex crit/combo
				if target.hasStatusEffect('Combo'):
					target.getStatusEffect('Combo').removeStatusEffect()
					return true
			'combo!': # ex. crit/combo!
				return target.hasStatusEffect('Combo')
			'%': # ex. crit/%:0.50
				return randomRoll(float(condition_data[1]))

func doDodgeEffects(caster: ResCombatant, target: ResCombatant, damage):
	manual_call_indicator.emit(target, 'Whiff!', 'Whiff')
	playDodgeTween(target)
	checkMissCases(target, caster, damage)

func doCritEffects(base_damage, caster: ResCombatant, crit_damage:float=2.0, stack_crit_damage:bool=false):
	if  caster != null:
		if stack_crit_damage:
			base_damage *= (caster.STAT_VALUES['crit_dmg']+crit_damage)
		else:
			base_damage *= caster.STAT_VALUES['crit_dmg']
	else:
		base_damage *= crit_damage
	getCombatScene().combat_camera.shake(15.0, 10.0)
	OverworldGlobals.playSound("res://audio/sounds/13_Ice_explosion_01.ogg")
	return base_damage

func doPostDamageEffects(caster: ResCombatant, target: ResCombatant, damage, sound: String, indicator_bb_code: String='', trigger_on_hits: bool=true, bonus_stats: Dictionary={}):
	var message = str(int(damage))
	message = indicator_bb_code+'[outline_size=8] '+message
	if damage > 0:
		manual_call_indicator.emit(target, message, 'Damage')
	target.removeTokens(1)
	if caster != null:
		caster.removeTokens(0)
	if trigger_on_hits:
		received_combatant_value.emit(target, caster, int(damage))
	if caster != null and target.isDead() and abs(target.STAT_VALUES['health']) >= target.getMaxHealth() * 0.25:
		calculateHealing(caster, caster.getMaxHealth()*0.15)
		if caster is ResPlayerCombatant:
			addTension(1)
			manual_call_indicator.emit(target, "OVERKILL", 'Wallop')
	
	playHurtAnimation(target, damage, sound)
	# The wall of post damage effects
	if hasBonusStat(bonus_stats, 'execute') and target.STAT_VALUES['health'] <= getBonusStat(bonus_stats, 'execute', target)*target.getMaxHealth():
		OverworldGlobals.showQuickAnimation("res://scenes/animations_quick/SkullKill.tscn", target.SCENE.global_position)
		target.STAT_VALUES['health'] -= 999
		manual_call_indicator.emit(target, 'EXECUTED!', 'Damage')
	if checkSpecialStat('status_effect', bonus_stats, target):
		var status_effects = getBonusStatValue(bonus_stats, 'status_effect').split(',')
		for effect in status_effects:
			CombatGlobals.addStatusEffect(target, effect)
	if checkSpecialStat('move', bonus_stats, target):
		var move_data = getBonusStatValue(bonus_stats, 'move').split(',')
		var direction
		match move_data[0]:
			'f': direction = 1
			'b': direction = -1
		CombatGlobals.getCombatScene().changeCombatantPosition(target, direction,false,int(move_data[1]))
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
	var grit = target.STAT_VALUES['grit']
	if grit > 0.7 and (CombatGlobals.inCombat() and !target.SCENE.blocking):
		grit = 0.7
	var out_damage = damage - (grit * damage)
	if out_damage < 0.0: 
		out_damage = 0
	return out_damage

func calculateHealing(target, base_healing, use_mult:bool=true, trigger_on_heal:bool=true):
	if target is CombatantScene:
		target = target.combatant_resource
	if target.STAT_VALUES['health'] < 0:
		target.STAT_VALUES['health'] = 0
	base_healing = valueVariate(base_healing, 0.15)
	if use_mult:
		base_healing *= target.STAT_VALUES['heal_mult']
	if base_healing <= 0: 
		base_healing = 0
		
	if target.STAT_VALUES['health'] + base_healing > target.getMaxHealth():
		target.STAT_VALUES['health'] = target.getMaxHealth()
	else:
		target.STAT_VALUES['health'] += int(base_healing)
	
	if base_healing > 0:
		manual_call_indicator.emit(target, '[color=green]'+str(int(base_healing)), 'Damage')
		OverworldGlobals.playSound('02_Heal_02.ogg')
	else:
		manual_call_indicator.emit(target, "Broken.", 'Flunk')
	
	if trigger_on_heal:
		target.removeTokens(2)
	#print(target.SCENE.idle_animation)
	if target.SCENE.animator.current_animation == 'Fading' and !target.isDead():
		target.SCENE.playIdle('Idle')

func randomRoll(percent_chance: float):
	percent_chance = 1.0 - percent_chance
	if percent_chance > 1.0:
		percent_chance = 1.0
	elif percent_chance < 0.0:
		percent_chance = 0.0
	randomize()
	return randf_range(0, 1.0) > percent_chance

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
	if !is_instance_valid(target.SCENE): return
	var animation = animation_scene.instantiate()
	target.SCENE.add_child(animation)
	if time > 0.0:
		animation.playAnimation(target.SCENE.position)
		await get_tree().create_timer(time).timeout
	else:
		await animation.playAnimation(target.SCENE.position)

func playHurtAnimation(target: ResCombatant, damage, sound_path: String=''):
	if !target.STAT_MODIFIERS.keys().has('block'):
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
				CombatGlobals.playAnimation(target, 'KO')
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
	var sprite = target.SCENE.get_node('Sprite2D')
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
	tween.tween_property(target.SCENE, 'scale', target.SCENE.scale + Vector2(-1, 0), 0.15)
	tween.tween_property(target.SCENE, 'scale', Vector2(1, 1), 0.15)

func playSecondWindTween(target: ResCombatant):
	OverworldGlobals.playSound("res://audio/sounds/458533__shyguy014__healpop.ogg")
	var tween = getCombatScene().create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(target.SCENE, 'scale', target.SCENE.scale + Vector2(-1, 0), 0.05)
	tween.tween_property(target.SCENE, 'scale', Vector2(1, 1), 0.15)

func playKnockOutTween(target: ResCombatant):
	if target is ResPlayerCombatant: OverworldGlobals.playSound("res://audio/sounds/542039__rob_marion__gasp_sweep-shot_1.ogg")

	var tween = getCombatScene().create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(target.SCENE, 'scale', target.SCENE.scale + Vector2(-1, 0), 0.15)
	tween.tween_property(target.SCENE, 'scale', Vector2(1, 1), 0.15)
	await tween.finished

func playAnimation(target: ResCombatant, animation_name: String):
	target.getAnimator().play(animation_name)

func showWarning(target: CombatantScene):
	var warning = preload("res://scenes/user_interface/TargetWarning.tscn").instantiate()
	target.add_child(warning)

func setCombatantVisibility(target: CombatantScene, set_to:bool):
	var tween = CombatGlobals.getCombatScene().create_tween()
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
	await CombatGlobals.qte_finished
	return qte

func playCombatantAnimation(combatant_name: String, animation_name: String, wait=true):
	for combatant in getCombatScene().COMBATANTS:
		if combatant.NAME == combatant_name:
			if wait:
				await combatant.SCENE.doAnimation(animation_name)
			else:
				combatant.SCENE.doAnimation(animation_name)
			return

func moveCombatCamera(target_name: String, duration:float=0.25, wait=true):
	var target
	if target_name == 'RESET':
		target = getCombatScene().camera_position
	else:
		for combatant in getCombatScene().COMBATANTS:
			if combatant.NAME == target_name: target = combatant.SCENE.global_position
	
	if wait:
		await getCombatScene().moveCamera(target, duration)
	else:
		getCombatScene().moveCamera(target, duration)

#********************************************************************************
# STATUS EFFECT HANDLING
#********************************************************************************
func addStatusEffect(target: ResCombatant, effect, guaranteed:bool=false):
	var status_effect: ResStatusEffect
	if effect is String:
		#if status_effect.contains(' '): status_effect = status_effect.replace(' ', '')
		status_effect = load(str("res://resources/combat/status_effects/"+effect.replace(' ', '')+".tres")).duplicate()
	elif effect is ResStatusEffect:
		status_effect = effect.duplicate()
	var icon_path = str(status_effect.TEXTURE.get_path())
	if !guaranteed and (randomRoll(target.STAT_VALUES['resist']) and status_effect.RESISTABLE):
		manual_call_indicator.emit(target, '[img]'+icon_path+'[/img] Resisted!', 'Resist')
		return
	
	if !target.getStatusEffectNames().has(status_effect.NAME):
		status_effect.afflicted_combatant = target
		status_effect.initializeStatus()
		target.STATUS_EFFECTS.append(status_effect)
		if status_effect.SOUNDS['apply'] != '': OverworldGlobals.playSound(status_effect.SOUNDS['apply'])
	else:
		rankUpStatusEffect(target, status_effect)
	if status_effect.TICK_ON_APPLY:
		target.getStatusEffect(status_effect.NAME).tick(false)
	else:
		manual_call_indicator.emit(target, 'Applied [img]'+icon_path+'[/img]!', 'Show')
	
	if (!guaranteed and !CombatGlobals.randomRoll(0.15+target.STAT_VALUES['resist'])) and (status_effect.LINGERING and target is ResPlayerCombatant and !target.LINGERING_STATUS_EFFECTS.has(status_effect.NAME)):
		manual_call_indicator.emit(target, 'Afflicted %s!' % status_effect.NAME, 'Lingering')
		target.LINGERING_STATUS_EFFECTS.append(status_effect.NAME)
	
	checkReactions(target)

func checkReactions(target: ResCombatant):
	if target.getStatusEffectNames().has('Singed') and target.getStatusEffectNames().has('Chilled'):
		runReaction(target, 'Singed', 'Chilled', load("res://resources/combat/abilities_reactions/Scald.tres"))
	elif target.getStatusEffectNames().has('Jolted') and target.getStatusEffectNames().has('Poison'):
		runReaction(target, 'Jolted', 'Poison', load("res://resources/combat/abilities_reactions/Catalyze.tres"))
	elif target.getStatusEffectNames().has('Chilled') and target.getStatusEffectNames().has('Jolted'):
		runReaction(target, 'Chilled', 'Jolted', load("res://resources/combat/abilities_reactions/Disrupt.tres"))
	elif target.getStatusEffectNames().has('Chilled') and target.getStatusEffectNames().has('Poison'):
		runReaction(target, 'Chilled', 'Poison', load("res://resources/combat/abilities_reactions/Vulnerate.tres"))
	elif target.getStatusEffectNames().has('Singed') and target.getStatusEffectNames().has('Poison'):
		execute_ability.emit(target, load("res://resources/combat/abilities_reactions/Cauterize.tres"))
		removeStatusEffect(target, 'Singed')
		removeStatusEffect(target, 'Poison')
	elif target.getStatusEffectNames().has('Singed') and target.getStatusEffectNames().has('Jolted'):
		execute_ability.emit(target, load("res://resources/combat/abilities_reactions/Fulgurate.tres"))
		removeStatusEffect(target, 'Singed')
		removeStatusEffect(target, 'Jolted')

func runReaction(target: ResCombatant, effectA: String, effectB: String, reaction: ResAbility):
	#OverworldGlobals.playSound("res://audio/sounds/334674__yoyodaman234__intense-sizzling-2.ogg")
	removeStatusEffect(target, effectA)
	removeStatusEffect(target, effectB)
	execute_ability.emit(target, reaction)

func rankUpStatusEffect(afflicted_target: ResCombatant, status_effect: ResStatusEffect):
	for effect in afflicted_target.STATUS_EFFECTS:
		if effect.NAME == status_effect.NAME:
			if effect.duration + status_effect.EXTEND_DURATION > effect.MAX_DURATION:
				effect.duration = effect.MAX_DURATION
			else:
				effect.duration += status_effect.EXTEND_DURATION
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

func generateCombatantSquad(patroller, faction: Enemy_Factions):
	randomize()
	var squad: EnemyCombatantSquad = preload("res://scenes/components/CombatantSquadEnemy.tscn").instantiate()
	var squad_size = randi_range(PlayerGlobals.getLevelTier(), PlayerGlobals.getLevelTier()+2)
	if squad_size > 4: squad_size = 4
	squad.FILL_EMPTY = true
	squad.ENEMY_POOL = getFactionEnemies(faction)
	# TO DO: Move this to PatrollerGroup!
#	if OverworldGlobals.getCurrentMap().EVENTS['additional_enemies'] != null:
#		squad.ENEMY_POOL.append_array(getFactionEnemies(OverworldGlobals.getCurrentMap().EVENTS['additional_enemies']))
#	if OverworldGlobals.getCurrentMap().EVENTS['patroller_effect'] != null:
#		squad.addLingeringEffect(OverworldGlobals.getCurrentMap().EVENTS['patroller_effect'])
#	squad.TAMEABLE_CHANCE = (0.01 * PlayerGlobals.PARTY_LEVEL) + OverworldGlobals.getCurrentMap().EVENTS['tameable_modifier']# Add story check later
	squad.ENEMY_POOL = squad.ENEMY_POOL.filter(func(combatant): return isWithinPlayerTier(combatant))
	squad.COMBATANT_SQUAD.resize(squad_size)
	squad.pickRandomEnemies()
	patroller.add_child(squad)

func createCombatantSquad(patroller, combatants: Array[ResCombatant], properties: Dictionary):
	var squad: EnemyCombatantSquad = preload("res://scenes/components/CombatantSquadEnemy.tscn").instantiate()
	squad.COMBATANT_SQUAD = combatants
	squad.setProperties(properties)
	patroller.add_child(squad)
	print('Added squab')

func getFactionEnemies(faction: Enemy_Factions)-> Array[ResEnemyCombatant]:
	var path
	match faction:
		Enemy_Factions.Neutral: path = "res://resources/combat/combatants_enemies/neutral/"
		Enemy_Factions.Unggboys: path = "res://resources/combat/combatants_enemies/unggboys/"
		Enemy_Factions.Mercenaries: path = "res://resources/combat/combatants_enemies/mercenaries/"
		Enemy_Factions.Scavs: path = "res://resources/combat/combatants_enemies/scavs/"
	
	var dir = DirAccess.open(path)
	var out: Array[ResEnemyCombatant] = []
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var combatant = load(path+'/'+file_name)
			out.append(combatant)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
		print(path)
	
	return out

func getFactionName(faction_value:int):
	return Enemy_Factions.find_key(faction_value)

func isWithinPlayerTier(enemy: ResEnemyCombatant)-> bool:
#	if enemy.TIER+1 <= PlayerGlobals.getLevelTier():
#		print('Adding %s [%s / %s]' % [enemy, enemy.TIER+1, PlayerGlobals.getLevelTier()])
#	else:
#		print('Removing %s [%s / %s]' % [enemy, enemy.TIER+1, PlayerGlobals.getLevelTier()])
	return enemy.TIER+1 <= PlayerGlobals.getLevelTier()

func addTension(amount: int):
#	if amount > 0:
#		OverworldGlobals.playSound("res://audio/sounds/220190__gameaudio__blip-pop.ogg")
#	elif amount < 0:
#		OverworldGlobals.playSound("res://audio/sounds/220189__gameaudio__blip-squeak.ogg")
	var prev_tension = TENSION
	if TENSION + amount > 8:
		TENSION = 8
	elif TENSION + amount < 0:
		TENSION = 0
	else:
		TENSION += amount
	tension_changed.emit(prev_tension, TENSION)
