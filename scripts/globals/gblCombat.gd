extends Node

enum Enemy_Factions {
	Neutral,
	Unggboys
}
var FACTION_MUSIC = {
	Enemy_Factions.Neutral: [
		"res://audio/music/706171__timbre__atmosphere-prince-funk-via-stableaudio.ogg"
	],
	Enemy_Factions.Unggboys: [
		"res://audio/music/Little Speck DV.ogg"
	]
}
signal combat_won(unique_id)
signal combat_lost(unique_id)
signal dialogue_signal(flag)
signal combat_conclusion_dialogue(dialogue, result)
signal animation_done
signal exp_updated(value: float, max_value: float)
signal received_combatant_value(combatant: ResCombatant, caster: ResCombatant, value)
signal manual_call_indicator(combatant: ResCombatant, text: String, animation: String)
signal call_indicator(animation: String, combatant: ResCombatant)
signal execute_ability(target, ability: ResAbility)
signal qte_finished()
signal ability_finished
signal ability_casted(ability: ResAbility)

#********************************************************************************
# COMBAT PROGRESSION / SIGNALS
#********************************************************************************
func emit_exp_updated(value, max_value):
	exp_updated.emit(value, max_value)

#********************************************************************************
# ABILITY EFFECTS & UTILITY
#********************************************************************************
## Calculate damage using basic formula and parameters
func calculateDamage(caster, target, base_damage, can_miss = true, can_crit = true)-> bool:
	if !caster is ResCombatant:
		caster = caster.combatant_resource
	if !target is ResCombatant:
		target = target.combatant_resource
	
	if randomRoll(caster.STAT_VALUES['accuracy']) and can_miss:
		damageTarget(caster, target, base_damage, can_crit)
		return true
	elif can_miss:
		manual_call_indicator.emit(target, 'Whiff!', 'Whiff')
		call_indicator.emit('Show', target)
		playDodgeTween(target)
		checkMissCases(target, caster, base_damage)
		return false
	else:
		damageTarget(caster, target, base_damage, can_crit)
		return true

## Calculate damage using custom formula and parameters
func calculateRawDamage(target, damage, caster: ResCombatant = null, can_crit = false, crit_chance = -1.0, can_miss = false, variation = -1.0, message = null, trigger_on_hits = false)-> bool:
	if !target is ResCombatant:
		target = target.combatant_resource
	
	if can_miss and !randomRoll(caster.STAT_VALUES['accuracy']):
		manual_call_indicator.emit(target, 'Whiff!', 'Whiff')
		playDodgeTween(target)
		checkMissCases(target, caster, damage)
		return false
	if variation != -1.0:
		damage = valueVariate(damage, variation)
	if can_crit:
		if caster != null and randomRoll(caster.STAT_VALUES['crit']):
			damage *= 1.5
			manual_call_indicator.emit(target, 'CRITICAL!!!', 'Crit')
			call_indicator.emit('Show', target)
			getCombatScene().combat_camera.shake(15.0, 10.0)
			OverworldGlobals.playSound("res://audio/sounds/13_Ice_explosion_01.ogg")
		elif crit_chance != -1.0 and randomRoll(crit_chance):
			damage *= 2.0
			manual_call_indicator.emit(target, 'CRITICAL!!!', 'Crit')
			call_indicator.emit('Show', target)
			getCombatScene().combat_camera.shake(15.0, 10.0)
			OverworldGlobals.playSound("res://audio/sounds/13_Ice_explosion_01.ogg")
	else:
		call_indicator.emit('Show', target)
	if message != null:
		manual_call_indicator.emit(target, "%s %s" % [int(damage), message], 'Show')
	target.STAT_VALUES['health'] -= int(damage)
	if trigger_on_hits: received_combatant_value.emit(target, caster, int(damage))
	playHurtAnimation(target)
	return true

## Basic damage calculations
func damageTarget(caster: ResCombatant, target: ResCombatant, base_damage, can_crit: bool):
	base_damage += caster.STAT_VALUES['brawn'] * base_damage
	base_damage = useDamageFormula(target, base_damage)
	
	base_damage = valueVariate(base_damage, 0.15)
	if randomRoll(caster.STAT_VALUES['crit']) and can_crit:
		base_damage *= 1.5
		manual_call_indicator.emit(target, 'CRITICAL!!!', 'Crit')
		call_indicator.emit('Show', target)
		getCombatScene().combat_camera.shake(15.0, 10.0)
		OverworldGlobals.playSound("res://audio/sounds/13_Ice_explosion_01.ogg")
	else:
		call_indicator.emit('Show', target)
	
	target.STAT_VALUES['health'] -= int(base_damage)
	received_combatant_value.emit(target, caster, int(base_damage))
	playHurtAnimation(target)

func checkMissCases(target: ResCombatant, caster: ResCombatant, damage):
	if target is ResPlayerCombatant and target.SCENE.blocking:
		CombatGlobals.calculateHealing(target, target.getMaxHealth() * 0.25)
		CombatGlobals.addStatusEffect(target, 'Guard')
	if target.getStatusEffectNames().has('Riposte'):
		target.getStatusEffect('Riposte').onHitTick(target, caster, damage)

func useDamageFormula(target: ResCombatant, damage):
	var out_damage = damage - (target.STAT_VALUES['grit'] * damage)
	if out_damage < 0.0: 
		out_damage = 0
	return out_damage

func calculateHealing(target:ResCombatant, base_healing):
	if target.STAT_VALUES['health'] < 0:
		target.STAT_VALUES['health'] = 0
	
	base_healing = valueVariate(base_healing, 0.15)
	base_healing *= target.STAT_VALUES['heal mult']
	
	if target.STAT_VALUES['health'] + base_healing > target.getMaxHealth():
		manual_call_indicator.emit(target, "FULL HEAL!", 'Heal')
		target.STAT_VALUES['health'] = target.getMaxHealth()
	else:
		manual_call_indicator.emit(target, "%s HEALED!" % [int(base_healing)], 'Heal')
		target.STAT_VALUES['health'] += int(base_healing)
	
	#received_combatant_value.emit(target, caster, int(base_healing))
	call_indicator.emit('Show', target)
	OverworldGlobals.playSound('02_Heal_02.ogg')

func randomRoll(percent_chance: float):
	percent_chance = 1.0 - percent_chance
	if percent_chance > 1.0:
		percent_chance = 1.0
	elif percent_chance < 0.0:
		percent_chance = 0.0
	randomize()
	return randf_range(0, 1.0) > percent_chance

# TO DO
#func normalizeValue():
#	var grit_normalized: float
#	if target.BASE_STAT_VALUES['grit'] > 1.0:
#		grit_normalized = 1.0
#	else:
#		grit_normalized = target.BASE_STAT_VALUES['grit']
#
#	var grit_bonus = (grit_normalized - 0.0) / (1.0 - 0.0) * 0.5

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
	if time > 0.0:
		animation.playAnimation(target.SCENE.position)
		await get_tree().create_timer(time).timeout
	else:
		await animation.playAnimation(target.SCENE.position)

func playHurtAnimation(target: ResCombatant):
	if !target.STAT_MODIFIERS.keys().has('block'):
		randomize()
		OverworldGlobals.playSound('522091__magnuswaker__pound-of-flesh-%s.ogg' % randi_range(1, 2))
		if target is ResEnemyCombatant:
			OverworldGlobals.playSound('524950__magnuswaker__punch-hard-%s.ogg' % randi_range(1, 2), -6.0)
		else:
			OverworldGlobals.playSound("530117__magnuswaker__pound-of-flesh-3.ogg", -8.0)
		if !target.isDead():
			playHurtTween(target)
		else:
			getCombatScene().combat_camera.shake(25.0, 10.0)
			if target is ResEnemyCombatant:
				CombatGlobals.playAnimation(target, 'KO')
				if target.ELITE:
					OverworldGlobals.playSound("res://audio/sounds/542052__rob_marion__gasp_space-shot_1_ELITE.ogg")
				else:
					OverworldGlobals.playSound("res://audio/sounds/542052__rob_marion__gasp_space-shot_1.ogg")
			else:
				OverworldGlobals.playSound("res://audio/sounds/542038__rob_marion__gasp_sweep-shot_2.ogg")
	else:
		OverworldGlobals.playSound('348244__newagesoup__punch-boxing-01.ogg')

func playDodgeTween(target: ResCombatant):
	OverworldGlobals.playSound('607862__department64__whipstick-28.ogg')
	var tween = getCombatScene().create_tween().set_trans(Tween.TRANS_CUBIC)
	var sprite_push = 16
	if target is ResPlayerCombatant: sprite_push *= -1
	tween.tween_property(target.getSprite(), 'position', target.getSprite().position + Vector2(sprite_push, 0), 0.15)
	tween.tween_property(target.getSprite(), 'position', Vector2(0, 0), 0.5)

func playHurtTween(target: ResCombatant):
	randomize()
	var sprite = target.SCENE.get_node('Sprite2D')
	var tween = getCombatScene().create_tween().set_trans(Tween.TRANS_CUBIC)
	var shake = Vector2(8, 0) + Vector2(randf_range(0, 8), 0)
	var duration = 0.05 + randf_range(0, 0.025)
	tween.tween_property(sprite, 'position', sprite.position + shake, duration)
	tween.tween_property(sprite, 'position', sprite.position - shake, duration)
	tween.tween_property(sprite, 'position', Vector2(0, 0), duration)

func playFadingTween(target: ResCombatant):
	OverworldGlobals.playSound('woosh.ogg')
	var tween = getCombatScene().create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(target.SCENE, 'scale', target.SCENE.scale + Vector2(-1, 0), 0.15)
	tween.tween_property(target.SCENE, 'scale', Vector2(1, 1), 0.15)

func playSecondWindTween(target: ResCombatant):
	OverworldGlobals.playSound("res://audio/sounds/458533__shyguy014__healpop.ogg")
	var tween = getCombatScene().create_tween().set_trans(Tween.TRANS_CUBIC)
	var opacity_tween = getCombatScene().create_tween()
	tween.tween_property(target.SCENE, 'scale', target.SCENE.scale + Vector2(-1, 0), 0.05)
	tween.tween_property(target.SCENE, 'scale', Vector2(1, 1), 0.15)
	opacity_tween.tween_property(target.SCENE, 'modulate', Color(Color.WHITE, 1.0), 0.5)

func playKnockOutTween(target: ResCombatant):
	if target is ResPlayerCombatant: OverworldGlobals.playSound("res://audio/sounds/542039__rob_marion__gasp_sweep-shot_1.ogg")
	var tween = getCombatScene().create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(target.SCENE, 'scale', target.SCENE.scale + Vector2(-1, 0), 0.15)
	tween.tween_property(target.SCENE, 'scale', Vector2(1, 1), 0.15)

func playAnimation(target: ResCombatant, animation_name: String):
	target.getAnimator().play(animation_name)

func showWarning(target: CombatantScene):
	var warning = preload("res://scenes/user_interface/TargetWarning.tscn").instantiate()
	target.add_child(warning)

func setCombatantVisibility(target: CombatantScene, set_to:bool):
	var tween = CombatGlobals.getCombatScene().create_tween()
	if !set_to:
		tween.tween_property(target, 'modulate', Color(Color.TRANSPARENT, 0.5), 0.15)
		target.z_index = -1
	else:
		tween.tween_property(target, 'modulate', Color(Color.TRANSPARENT, 1.0), 0.15)
		target.z_index = 0
	target.get_node('CombatBars').visible = set_to

func spawnQuickTimeEvent(target: CombatantScene, type: String, max_points:int=1):
	OverworldGlobals.playSound('542044__rob_marion__gasp_ui_confirm.ogg')
	var qte = load("res://scenes/quick_time_events/%s.tscn" % type).instantiate()
	qte.max_points = max_points
	var offset = Vector2(0, -48)
	if type == 'Holding': offset = Vector2.ZERO
	qte.global_position = target.global_position + offset
	qte.z_index = 101
	getCombatScene().call_deferred('add_child',qte)
	await CombatGlobals.qte_finished
	return qte

#********************************************************************************
# STATUS EFFECT HANDLING
#********************************************************************************
func addStatusEffect(target: ResCombatant, effect, tick_on_apply=false, _base_chance = 2.0):
	var status_effect
	if effect is String:
		status_effect = load(str("res://resources/combat/status_effects/"+effect+".tres")).duplicate()
	elif effect is ResStatusEffect:
		status_effect = effect.duplicate()
	
	if !target.getStatusEffectNames().has(status_effect.NAME):
		status_effect.afflicted_combatant = target
		status_effect.initializeStatus()
		target.STATUS_EFFECTS.append(status_effect)
	else:
		rankUpStatusEffect(target, status_effect)
	if tick_on_apply:
		target.getStatusEffect(status_effect.NAME).tick(false)
	
	if status_effect.LINGERING and target is ResPlayerCombatant and !target.LINGERING_STATUS_EFFECTS.has(status_effect.NAME):
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
		#OverworldGlobals.playSound("res://audio/sounds/334674__yoyodaman234__intense-sizzling-2.ogg")
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
			CombatGlobals.manual_call_indicator.emit(afflicted_target, '%s Rank Up!' % status_effect.NAME , 'Show')

func removeStatusEffect(target: ResCombatant, status_name: String):
	for status in target.STATUS_EFFECTS:
		if status.NAME == status_name:
			status.removeStatusEffect()
			return

func getCombatScene()-> CombatScene:
	return get_parent().get_node('CombatScene')

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
