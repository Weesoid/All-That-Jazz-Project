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
	'defense': 0,
	'handling': 0,
	'speed': 1,
	'accuracy': 0.95,
	'crit': 0.05,
	'crit_dmg': 1.5,
	'heal_mult': 1.0,
	'resist': 0.05,
	'dmg_variance': 0.25,
	'dmg_modifier': 1.0
}
@export var scale_stats: Dictionary = {
	'health': true,
	'damage': true,
	'defense': true,
	'handling': false,
	'speed': true,
	'accuracy': false,
	'crit': false,
	'crit_dmg': false,
	'heal_mult': false,
	'resist': false,
	'dmg_variance': false,
	'dmg_modifier': false
}
@export var ability_set: Array[ResAbility] # May need to be refactored to dict for specific selection
@export var max_turn_charges = 1
@export var riposte_effect: ResDamageEffect
@export var ai_package: GDScript
var turn_charges: int
var stat_modifiers = {}
var status_effects: Array[ResStatusEffect]
var lingering_effects: Array[String]
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
	var stat_increase = {}
	for stat in stat_values.keys():
		if scale_stats[stat]: 
			# Increase stat by 10% of the character's base stat value (value at lvl1) per level
			# 20HP > 22 > 24
			# 0.25 > 0.27 > 0.3
			# 8 > 9 > 10
			stat_increase[stat] = (base_stat_values[stat] * (1 + ((PlayerGlobals.team_level-1)*0.1))) - base_stat_values[stat]
#		if (stat == 'health' or  stat == 'speed') and base_stat_values[stat]:
#			stat_increase[stat] = int(stat_increase[stat])
	CombatGlobals.modifyStat(self, stat_increase, 'scaled_stats')

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

func isDead()-> bool:
	return stat_values['health'] < 1.0

func isImmobilized()-> bool:
	return (stat_values['speed'] < -99 and !hasStatusEffect('Fading')) or hasStatusEffect('Stunned')

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

func applyStatModifications(modifier_id: String):
	for modifier in stat_modifiers.keys():
		if modifier == modifier_id:
			for stat in stat_modifiers[modifier]:
				if stat == 'health':
					updateHealth(stat_modifiers[modifier][stat])
				else:
					stat_values[stat] += stat_modifiers[modifier][stat]
			return

func removeStatModification(modifier_id: String):
	for modifier in stat_modifiers.keys():
		if modifier == modifier_id:
			for stat in stat_modifiers[modifier]:
				if stat == 'health':
					updateHealth(-stat_modifiers[modifier][stat])
				else:
					stat_values[stat] -= stat_modifiers[modifier][stat]
			stat_modifiers.erase(modifier)
			return

func updateHealth(amount: int):
	var percent_health = float(stat_values['health']) / float(base_stat_values['health'])
	base_stat_values['health'] += amount
	if stat_values['health'] >= base_stat_values['health'] or percent_health == 1:
		stat_values['health'] = base_stat_values['health']

func _to_string():
	return str(name)

#func freeBreathingTweens():
#	stopBreatheTween()
#	if is_instance_valid(scale_tween):
#		scale_tween=null
#	if is_instance_valid(pos_tween):
#		pos_tween=null
