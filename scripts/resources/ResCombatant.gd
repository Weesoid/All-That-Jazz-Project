# Refactor Exstensions
extends Resource
class_name ResCombatant

@export var name: String
@export var preferred_alias:String
@export var packed_scene: PackedScene
@export var bullet_texture: Texture2D
@export_multiline var description: String
@export var stat_values = {
	'health': 20,
	'damage': 4,
	'handling': 0,
	'speed': 0,
	'crit': 0.0,
	'resist': 0.0,
	'dmg_variance': 0.0,
	'resolve': 0
}
@export var scale_stats: Dictionary = {
	'health': 0.0,
	'damage': 0.0,
	'handling': 0.0,
	'speed': 0.0,
	'crit': 0.0,
	'resist': 0.0,
	'dmg_variance': 0.0,
	'resolve': 0.0
}
@export var ability_set: Array[ResAbility] # May need to be refactored to dict for specific selection
@export var max_turn_charges = 1
@export var riposte_effect: ResAttackEffect
@export var assigned_position:int = -1
@export var ai_package: GDScript
var percent_health:float
var percent_resolve:float
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
signal health_changed(combatant)
signal resolve_changed
signal stat_modified(combatant, stat_dict)
signal stat_removed(combatant, stat_dict)
signal extra_stat_added(combatant, stat)
signal status_effect_stored(status_effect)

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
			scaled_stat = floor(scale_stats[stat] * (PlayerGlobals.team_level))
		else:
			scaled_stat = snapped(scale_stats[stat] * (PlayerGlobals.team_level),0.01)
		if scaled_stat <= 0:
			continue
		
		stat_bonuses[stat] = scaled_stat
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

func getMissingHealth():
	return base_stat_values['health'] - stat_values['health']

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
			stat_modifiers[modifier_id] = CombatGlobals.combineDictionaries(stat_modifiers[modifier_id], append_stats)

func addTemporaryModifer(modifier_id:String, duration:int, stat_dict: Dictionary, append_stats:bool,per_battle:bool=false, resistable:bool=false,show_indicator:bool=true):
	var key
	var data
	if per_battle:
		data = 'tempmod/battle/'+JSON.stringify(stat_dict)
	else:
		data = 'tempmod/turns/'+JSON.stringify(stat_dict)
	key = data+'|'+modifier_id # Will look smth like: tempmod/battle/{"damage":67}|<modifier id>
	
	CombatGlobals.modifyStat(self, stat_dict, key, append_stats,resistable,show_indicator)
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
	if !key.contains('tempmod/'):
		removeTempModifierWithName(key)
	
	if stat_modifiers.has(key):
		removeStatModification(key)
	if temp_modifier_tracker.has(key):
		temp_modifier_tracker.erase(key)

func removeTempModifierWithName(key):
	var temp_mods = getTemporaryModifierKeys()
	for modifier in temp_mods:
		if modifier.split('|')[1] == key:
			removeTemporaryModifier(modifier)
			return

func hasTemporaryModifier(key:String):
	return getTemporaryModifierKeys('/',true).has(key)

func getTemporaryModifierKeys(type:String='/', names_only:bool=false):
	assert(type == 'turns' or type == 'battle' or type == '/', 'Type can only be: "turns" or "battle" !')
	var out = []
	
	for modifier in stat_modifiers:
		if modifier.contains('tempmod/') and modifier.contains(type): 
			out.append(modifier if !names_only else modifier.split('|')[1])
	
	return out

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
					extra_stat_added.emit(self,stat)
			stat_modified.emit(self, stat_modifiers[modifier_id])
			return

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
			stat_removed.emit(self, modifier)
			return
	
	#removeEmptyStats()

func changeHealth(value:int,set_to:bool=false):
	if set_to:
		stat_values['health'] = value
	else:
		stat_values['health'] += value
	if stat_values['health'] > getMaxHealth():
		stat_values['health']=getMaxHealth()
	percent_health = float(stat_values['health'])/float(getMaxHealth())
	health_changed.emit(self)

func changeResolve(value:int):
	print('received val ', value)
	var fag = stat_values['resolve']+value
	if fag > getMaxResolve():
		fag=getMaxResolve()
	print('setting resolve to ', fag, ' (was %s)' % stat_values['resolve'])
	stat_values['resolve'] = fag
	print('resolve is now: ', stat_values['resolve'])
	percent_resolve = float(stat_values['resolve'])/float(getMaxResolve())
	resolve_changed.emit()

func removeEmptyStats():
	var stat_keys = stat_modifiers.keys()
	stat_keys.reverse()
	for stat in stat_modifiers.keys():
		if !base_stat_values.keys().has(stat):
			continue
		if stat_modifiers[stat] == 0.0:
			stat_modifiers.erase(stat)

# TODO: Figure out a wway to handle negative health via statmodifiers
func updateHealth(amount:int):
	base_stat_values['health'] += amount
	var scaled = int(getMaxHealth()*percent_health)
	if scaled <= 0 and percent_health > 0:
		scaled = 1
	stat_values['health'] = scaled



func updateResolve(amount: int):
	base_stat_values['resolve'] += amount
	var scaled = int(base_stat_values['resolve']*percent_resolve)
	if scaled <= 0 and percent_resolve > 0:
		scaled = 1
	stat_values['resolve'] = scaled

func clearAbilityMutations():
	for ability in ability_set.filter(func(ability): return ability.mutated):
		ability.restoreProperties()

func _to_string():
	return str(name)

func applyStoredStatusEffects():
	stored_status_effects.reverse()
	for effect in stored_status_effects:
		var effect_data = effect.split('/')
		CombatGlobals.addStatusEffect(self, effect_data[0])
		if effect_data.size()==1: 
			stored_status_effects.erase(effect)

func storeStatusEffect(effect, persistent:bool=false):
	if effect is String:
		effect = CombatGlobals.loadStatusEffect(effect)
	if stored_status_effects.has(effect.getFilename()) or stored_status_effects.has(effect.getFilename()+'/persist'):
		return
	
	if persistent:
		stored_status_effects.append(effect.getFilename()+'/persist')
	else:
		stored_status_effects.append(effect.getFilename())
	status_effect_stored.emit(effect)

func unstoreStatusEffect(remove_effect: ResStatusEffect):
	for effect in stored_status_effects:
		var effect_data = effect.split('/')
		if effect_data[0] == remove_effect.getFilename(): stored_status_effects.erase(effect)

#func freeBreathingTweens():
#	stopBreatheTween()
#	if is_instance_valid(scale_tween):
#		scale_tween=null
#	if is_instance_valid(pos_tween):
#		pos_tween=null
