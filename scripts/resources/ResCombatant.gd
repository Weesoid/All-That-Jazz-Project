# Refactor Exstensions
extends Resource
class_name ResCombatant

@export var name: String
@export var packed_scene: PackedScene
@export var bullet_texture: Texture2D
@export_multiline var description: String
@export var stat_values = {
	'health': 20,
	'damage': 4,
	'handling': 0,
	'speed': 1,
	'crit': 0.05,
	'crit_dmg': 1.5,
	'heal_mult': 1.0,
	'resist': 0.05,
	'dmg_variance': 0.1,
	'resolve': 3
}
@export var scale_stats: Dictionary = {
	'health': 0.0,
	'damage': 0.0,
	'handling': 0.0,
	'speed': 0.0,
	'crit': 0.0,
	'crit_dmg': 0.0,
	'heal_mult': 0.0,
	'resist': 0.0,
	'dmg_variance': 0.0,
	'resolve': 0.0
}
@export var ability_set: Array[ResAbility] # May need to be refactored to dict for specific selection
@export var max_turn_charges = 1
@export var riposte_effect: ResDamageEffect
@export var ai_package: GDScript
var resolve_gate:bool=true
var resolve_dot_shield:bool=false
var turn_charges: int
var stat_modifiers = {}
var temp_modifier_tracker = {}
var status_effects: Array[ResStatusEffect]
## Status effects gained from the overworld or means outside of combat, stores them as their filenames. 
var stored_status_effects: Array[String]
#var lingering_effects: Array[String]
var base_stat_values: Dictionary
var acted: bool
var combatant_scene: CombatantScene
var pos_tween: Tween
var scale_tween: Tween

signal enemy_turn
signal player_turn

func initializeCombatant():
	pass

func resetSprite():
	getSprite().position = Vector2.ZERO
	getSprite().scale = Vector2(1.0,1.0)

func startBreatheTween(await_start:bool):
	if await_start:
		randomize()
		await CombatGlobals.get_tree().create_timer(randf_range(0.0,1.0)).timeout
	if self is ResEnemyCombatant and self.is_converted:
		setBreatheTween(1)
	else:
		setBreatheTween(0)

func stopBreatheTween():
	if scale_tween == null or pos_tween == null:
		return

	scale_tween.stop()
	pos_tween.stop()
	resetSprite()

func setBreatheTween(mode:int):
	if is_instance_valid(combatant_scene) and (scale_tween == null and pos_tween == null or !scale_tween.is_valid() and !pos_tween.is_valid()):
		scale_tween = combatant_scene.create_tween().set_loops()
		pos_tween = combatant_scene.create_tween().set_loops()
	elif is_instance_valid(combatant_scene) and !scale_tween.is_running() and !pos_tween.is_running() and scale_tween != null and pos_tween != null:
		scale_tween.play()
		pos_tween.play()
		return
	else:
		return
	
	getSprite().position = Vector2.ZERO
	match mode:
		0: # Normal Breathing
			scale_tween.tween_property(getSprite(), "scale", Vector2(1.0,1.05), 1.5)
			scale_tween.tween_property(getSprite(), "scale", Vector2(1.0,1.0), 1.5)
			pos_tween.tween_property(getSprite(), "position", Vector2(0.0,-1.0), 1.5)
			pos_tween.tween_property(getSprite(), "position", Vector2(0.0,0.0), 1.5)
		1: # Inverted Breathing (For converted enemies)
			scale_tween.tween_property(getSprite(), "scale", Vector2(1.0,1.05), 1.5)
			scale_tween.tween_property(getSprite(), "scale", Vector2(1.0,1.0), 1.5)
			pos_tween.tween_property(getSprite(), "position", Vector2(0.0,1.0), 1.5)
			pos_tween.tween_property(getSprite(), "position", Vector2(0.0,0.0), 1.5)

func act():
	pass

func scaleStats():
	var stat_bonuses = {}
	
	for stat in scale_stats.keys():
		var scaled_stat
		if stat_values[stat] is int:
			scaled_stat = floor(scale_stats[stat] * (PlayerGlobals.team_level-1))
		else:
			scaled_stat = snapped(scale_stats[stat] * (PlayerGlobals.team_level-1),0.01)
		if scaled_stat <= 0:
			continue
		
		stat_bonuses[stat] = scaled_stat
	print(stat_bonuses)
	#if !stat_bonuses.is_empty():
	CombatGlobals.modifyStat(self, stat_bonuses, 'scaled_stats')

func getSprite()-> Sprite2D:
	return combatant_scene.get_node('Sprite2D')

func getAnimator()-> AnimationPlayer:
	return combatant_scene.get_node('AnimationPlayer')

func getStatusEffectNames()-> Array[String]:
	var names: Array[String] = []
	for effect in status_effects:
		names.append(effect.name)
	return names

func removeTokens(remove_type: int):
	for effect in status_effects:
		if effect.remove_when.has(remove_type): 
			match effect.remove_style:
				ResStatusEffect.RemoveStyle.REMOVE: effect.removeStatusEffect()
				ResStatusEffect.RemoveStyle.TICK_DOWN: effect.tick(false, true)

func getMaxHealth():
	return base_stat_values['health']

func getMaxResolve():
	return base_stat_values['resolve']

func getStatusEffect(stat_name: String)-> ResStatusEffect:
	for status in status_effects:
		if status.name.to_lower() == stat_name.to_lower():
			return status
	
	return null

func hasStatusEffect(stat_name: String)-> bool:
	for status in status_effects:
		if status.name.to_lower() == stat_name.to_lower():
			return true
	
	return false

func isDead(check_resolve: bool=false)-> bool:
	return stat_values['health'] < 1.0 and (!check_resolve or (check_resolve and stat_values['resolve'] <= 0))

func isOnBrink():
	return stat_values['health'] < 1.0 and stat_values['resolve'] >= 0

func isImmobilized()-> bool:
	return stat_values['speed'] < -99 or hasStatusEffect('Stunned')

func getStringStats(current_stats=false):
	var result = ""
	var stats
	if current_stats:
		stats = base_stat_values
	else:
		stats = stat_values
	
	for key in stats:
		if key == 'health':
			result += key.to_upper() + ": " + str(int(stat_values[key])) + ' / ' + str(base_stat_values[key]) + "\n"
		elif base_stat_values[key] is float:
			result += key.to_upper() + ": " + str(base_stat_values[key]*100) + "%\n"
		else:
			result += key.to_upper() + ": " + str(base_stat_values[key]) + "\n"
	
	return result

func appendStatModification(modifier_id:String, append_stats: Dictionary):
	for modifier in stat_modifiers.keys():
		if modifier == modifier_id:
			stat_modifiers[modifier_id] = CombatGlobals.appendStatModifications(stat_modifiers[modifier_id], append_stats)

func applyStatModifications(modifier_id: String):
	for modifier in stat_modifiers.keys():
		if modifier == modifier_id:
			for stat in stat_modifiers[modifier]:
				if stat == 'health':
					updateHealth(stat_modifiers[modifier][stat])
				elif stat == 'resolve':
					updateResolve(stat_modifiers[modifier][stat])
				elif stat_values.has(stat):
					stat_values[stat] += stat_modifiers[modifier][stat]
				else:
					stat_values[stat] = stat_modifiers[modifier][stat]
				#if stat == 'resolve':
				#	CombatGlobals.healResolve(self,stat_modifiers[modifier][stat])
			return

# TODO?  Update handling. Replace outdated modifiers based on modifier_id?
func addTemporaryModifer(modifier_id:String, duration:int, stat_dict: Dictionary, append_stats:bool,per_battle:bool=false,show_indicator:bool=true):
	var key
	var data
	if per_battle:
		data = 'tempmod/battle/'+JSON.stringify(stat_dict)
	else:
		data = 'tempmod/turns/'+JSON.stringify(stat_dict)
	key = data+'|'+modifier_id # Will look smth like: tempmod/battle/{"damage":67}|<modifier id>
	
	CombatGlobals.modifyStat(self, stat_dict, key, append_stats,show_indicator)
	temp_modifier_tracker[key] = duration

func applyTemporaryModifiers():
	for key in temp_modifier_tracker:
		if !stat_modifiers.has(key):
			CombatGlobals.modifyStat(self, JSON.parse_string(key.split('|')[0].split('/')[2]), key)
	
	#removeEmptyStats()

func tickTemporaryModifiers(type:String):
	assert(type == 'turns' or type == 'battle', 'Type can only be: "turns" or "battle" !')
	var tracker_keys
	if type == 'turns':
		tracker_keys = temp_modifier_tracker.keys().filter(func(key): return key.contains('/turns'))
	elif type == 'battle':
		tracker_keys = temp_modifier_tracker.keys().filter(func(key): return key.contains('/battle'))
	
	#if name.contains('Willis'): print('!!!!!!!!!!!!!> keyz: '+str(tracker_keys))
	for key in tracker_keys:
		temp_modifier_tracker[key] -= 1
		if temp_modifier_tracker[key] <= 0:
			removeTemporaryModifier(key)
			#print('removing ', key, ' !')
	#if name.contains('Willis'):  print('!!!!!!!!!!!!!> curr tracker: '+str(temp_modifier_tracker))

func removeTemporaryModifier(key:String):
	if stat_modifiers.has(key):
		removeStatModification(key)
	if temp_modifier_tracker.has(key):
		temp_modifier_tracker.erase(key)

func getTemporaryModifierKeys(type:String='/'):
	assert(type == 'turns' or type == 'battle' or type == '/', 'Type can only be: "turns" or "battle" !')
	var out = []
	
	for modifier in stat_modifiers:
		if modifier.contains('tempmod/') and modifier.contains(type): 
			out.append(modifier)
	
	return out

func removeStatModification(modifier_id: String):
	for modifier in stat_modifiers.keys():
		if modifier == modifier_id:
			for stat in stat_modifiers[modifier]:
				if stat == 'health':
					updateHealth(-stat_modifiers[modifier][stat])
				elif stat == 'resolve':
					updateResolve(-stat_modifiers[modifier][stat])
				else:
					stat_values[stat] -= stat_modifiers[modifier][stat]
			stat_modifiers.erase(modifier)
			return
	
	#removeEmptyStats()

func removeEmptyStats():
	var stat_keys = stat_modifiers.keys()
	stat_keys.reverse()
	for stat in stat_modifiers.keys():
		if !base_stat_values.keys().has(stat):
			continue
		if stat_modifiers[stat] == 0.0:
			stat_modifiers.erase(stat)

# TODO: Figure out a wway to handle negative health via statmodifiers
func updateHealth(amount: int):
	var percent_health = float(stat_values['health']) / float(base_stat_values['health'])
	base_stat_values['health'] += amount
	if stat_values['health'] >= base_stat_values['health'] or percent_health == 1:
		stat_values['health'] = base_stat_values['health']

func updateResolve(amount: int, heal_resolve:bool=true):
	base_stat_values['resolve'] += amount
	if base_stat_values['resolve'] < stat_values['resolve']:
		stat_values['resolve'] = base_stat_values['resolve']
	if amount > 0 and heal_resolve:
		CombatGlobals.healResolve(self, amount)

func clearAbilityMutations():
	for ability in ability_set.filter(func(ability): return ability.mutated):
		ability.restoreProperties()

func _to_string():
	return str(name)

func applyStoredStatusEffects():
	stored_status_effects.reverse()
	for effect in stored_status_effects:
		CombatGlobals.addStatusEffect(self, effect)
		stored_status_effects.erase(effect)

func storeStatusEffect(effect: ResStatusEffect, persistent:bool=false):
	if persistent:
		stored_status_effects.append(effect.getFilename()+'/persist')
	else:
		stored_status_effects.append(effect.getFilename())

# TODO: Remove based on effect
func unstoreStatusEffect(effect: ResStatusEffect):
	pass

#func freeBreathingTweens():
#	stopBreatheTween()
#	if is_instance_valid(scale_tween):
#		scale_tween=null
#	if is_instance_valid(pos_tween):
#		pos_tween=null
